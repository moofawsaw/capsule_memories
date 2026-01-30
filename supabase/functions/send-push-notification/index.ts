import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
  user_id: string
  title: string
  body: string
  data?: Record<string, any>
  notification_type: string
  skip_in_app?: boolean
}

type PushPrefsRow = {
  push_notifications_enabled?: boolean | null
  push_memory_invites?: boolean | null
  push_memory_activity?: boolean | null
  push_memory_sealed?: boolean | null
  push_new_followers?: boolean | null
  push_friend_requests?: boolean | null
  push_group_invites?: boolean | null
  push_daily_capsule?: boolean | null
  push_new_story?: boolean | null
  push_memory_expiring?: boolean | null
  push_followed?: boolean | null
  push_new_follower?: boolean | null
  push_daily_capsule_reminder?: boolean | null
  push_friend_daily_capsule_completed?: boolean | null
}

function prefFieldForNotificationType(notificationType: string): keyof PushPrefsRow | null {
  // Map edge `notification_type` values to the user's preference columns.
  // Multiple notification types can share one preference category.
  switch ((notificationType ?? '').trim()) {
    case 'memory_invite':
      return 'push_memory_invites'

    case 'new_story':
      return 'push_new_story'

    case 'memory_sealed':
      return 'push_memory_sealed'

    // Daily Capsule
    case 'daily_capsule_reminder':
      return 'push_daily_capsule_reminder'
    case 'friend_daily_capsule_completed':
      return 'push_friend_daily_capsule_completed'

    // New followers
    case 'followed':
      return 'push_followed'
    case 'new_follower':
      return 'push_new_follower'

    // Friend request lifecycle
    case 'friend_request':
    case 'friend_accepted':
      return 'push_friend_requests'

    // Group lifecycle (we no longer send group_join/group_added via this function)
    case 'group_invite':
      return 'push_group_invites'

    // Memory expiring reminders (if used) fall under memory activity
    case 'memory_expiring':
      return 'push_memory_expiring'

    default:
      return null
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const payload: NotificationPayload = await req.json()
    const { user_id, title, body, data, notification_type, skip_in_app } = payload

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Explicitly disabled notification types (we do not want to send or create these).
    // Return 200 so upstream callers don't retry.
    const disabledTypes = new Set([
      'group_join',
      'group_added',
      'memory_activity',
      'memory_update',
    ])
    if (disabledTypes.has((notification_type ?? '').trim())) {
      return new Response(
        JSON.stringify({ message: 'Notification type disabled', notification_type, sent: 0 }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Respect push notification preferences.
    try {
      const { data: prefs } = await supabaseClient
        .from('email_preferences')
        .select(
          [
            'push_notifications_enabled',
            'push_memory_invites',
            'push_memory_sealed',
            'push_friend_requests',
            'push_group_invites',
            // Split per-type flags (new schema)
            'push_new_story',
            'push_memory_expiring',
            'push_followed',
            'push_new_follower',
            'push_daily_capsule_reminder',
            'push_friend_daily_capsule_completed',
            // Legacy flags (kept for backward compat / fallback)
            'push_memory_activity',
            'push_new_followers',
            'push_daily_capsule',
          ].join(', ')
        )
        .eq('user_id', user_id)
        .maybeSingle()

      const masterEnabled = (prefs as PushPrefsRow | null)?.push_notifications_enabled !== false
      if (!masterEnabled) {
        return new Response(
          JSON.stringify({ message: 'Push notifications disabled by user', sent: 0 }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      const prefField = prefFieldForNotificationType(notification_type)
      if (prefField) {
        const typed = prefs as PushPrefsRow | null
        // Backward-compat: if the new split column is missing/null, fall back to the legacy grouped flag.
        let enabled = typed?.[prefField] !== false
        if (typed && (typed as any)[prefField] == null) {
          switch (prefField) {
            case 'push_new_story':
            case 'push_memory_expiring':
              enabled = (typed.push_memory_activity !== false)
              break
            case 'push_followed':
            case 'push_new_follower':
              enabled = (typed.push_new_followers !== false)
              break
            case 'push_daily_capsule_reminder':
            case 'push_friend_daily_capsule_completed':
              enabled = (typed.push_daily_capsule !== false)
              break
          }
        }
        if (!enabled) {
          return new Response(
            JSON.stringify({
              message: `Push notifications disabled by user for ${notification_type}`,
              pref_field: prefField,
              sent: 0,
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
      }
    } catch (_) {
      // If prefs lookup fails, do not block the push (fail-open).
    }

    // Get active FCM tokens for the user
    const { data: tokens, error: tokensError } = await supabaseClient
      .from('fcm_tokens')
      .select('token, device_type')
      .eq('user_id', user_id)
      .eq('is_active', true)

    if (tokensError) {
      throw new Error(`Failed to fetch FCM tokens: ${tokensError.message}`)
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No active FCM tokens found for user', sent: 0 }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // FCM configuration
    const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')
    if (!FCM_SERVER_KEY) {
      throw new Error('FCM_SERVER_KEY not configured')
    }

    const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send'

    // Send notifications to all tokens
    const notificationPromises = tokens.map(async ({ token, device_type }) => {
      const fcmPayload = {
        to: token,
        notification: {
          title,
          body,
          sound: 'default',
          badge: '1',
          priority: 'high',
        },
        data: {
          notification_type,
          ...data,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        priority: 'high',
        content_available: true,
      }

      const response = await fetch(FCM_ENDPOINT, {
        method: 'POST',
        headers: {
          'Authorization': `key=${FCM_SERVER_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      })

      const result = await response.json()

      // If token is invalid, mark it as inactive
      if (result.failure === 1 && result.results?.[0]?.error === 'InvalidRegistration') {
        await supabaseClient
          .from('fcm_tokens')
          .update({ is_active: false })
          .eq('token', token)
      }

      return {
        token,
        device_type,
        success: result.success === 1,
        result,
      }
    })

    const results = await Promise.all(notificationPromises)
    const successCount = results.filter(r => r.success).length

    // Optionally create in-app notification record.
    // Many events already create DB notifications via triggers; avoid duplicates.
    if (skip_in_app !== true) {
      await supabaseClient.from('notifications').insert({
        user_id,
        title,
        message: body,
        type: notification_type,
        data: data || {},
        is_read: false,
      })
    }

    return new Response(
      JSON.stringify({
        message: 'Push notifications sent',
        sent: successCount,
        total: tokens.length,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error sending push notification:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})