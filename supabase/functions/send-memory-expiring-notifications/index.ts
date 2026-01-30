import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type PrefsRow = {
  push_notifications_enabled?: boolean | null
  push_memory_expiring?: boolean | null
  // Legacy fallback (older schema)
  push_memory_activity?: boolean | null
}

async function sendFcmToUser(params: {
  supabase: any
  userId: string
  title: string
  body: string
  data?: Record<string, any>
}): Promise<number> {
  const { supabase, userId, title, body, data } = params

  const { data: tokens, error: tokensError } = await supabase
    .from('fcm_tokens')
    .select('token')
    .eq('user_id', userId)
    .eq('is_active', true)

  if (tokensError) throw new Error(`Failed to fetch FCM tokens: ${tokensError.message}`)
  if (!tokens || tokens.length === 0) return 0

  const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')
  if (!FCM_SERVER_KEY) throw new Error('FCM_SERVER_KEY not configured')

  const endpoint = 'https://fcm.googleapis.com/fcm/send'
  const basePayload = {
    notification: {
      title,
      body,
      sound: 'default',
      priority: 'high',
      badge: '1',
    },
    data: {
      notification_type: 'memory_expiring',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      ...(data ?? {}),
    },
    priority: 'high',
    content_available: true,
  }

  const requests = tokens.map(async (t: { token: string }) => {
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ ...basePayload, to: t.token }),
    })
    const json = await res.json().catch(() => ({}))

    if (json?.failure === 1 && json?.results?.[0]?.error === 'InvalidRegistration') {
      await supabase.from('fcm_tokens').update({ is_active: false }).eq('token', t.token)
      return false
    }
    return json?.success === 1
  })

  const results = await Promise.all(requests)
  return results.filter(Boolean).length
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const now = new Date()
    const nowIso = now.toISOString()
    const twoHoursAgoIso = new Date(now.getTime() - 2 * 60 * 60 * 1000).toISOString()
    // We want this to fire once, ~1 hour before expiration.
    // This function is intended to be scheduled to run frequently (e.g. every minute).
    // To avoid "any time in the last hour" behavior, we target a narrow window around +60m.
    const targetMs = now.getTime() + 60 * 60 * 1000
    const windowStartIso = new Date(targetMs - 90 * 1000).toISOString() // -90s
    const windowEndIso = new Date(targetMs + 90 * 1000).toISOString() // +90s

    // Find open memories expiring ~1 hour from now (narrow window).
    const { data: memories, error: memErr } = await supabase
      .from('memories')
      .select('id, title, expires_at')
      .eq('state', 'open')
      .gt('expires_at', nowIso)
      .gte('expires_at', windowStartIso)
      .lte('expires_at', windowEndIso)

    if (memErr) throw new Error(`Failed to fetch expiring memories: ${memErr.message}`)

    const memRows = (memories ?? []) as Array<{ id: string; title: string; expires_at: string }>
    if (memRows.length === 0) {
      return new Response(JSON.stringify({ ok: true, processed: 0, pushes_sent: 0, in_app_created: 0 }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    let inAppCreated = 0
    let pushesSent = 0
    let processedPairs = 0

    for (const mem of memRows) {
      const memoryId = mem.id
      const memoryTitle = mem.title ?? 'Memory'
      const expiresAt = mem.expires_at

      // Get contributors for this memory
      const { data: contrib, error: cErr } = await supabase
        .from('memory_contributors')
        .select('user_id')
        .eq('memory_id', memoryId)

      if (cErr) continue
      const users = (contrib ?? []) as Array<{ user_id: string }>

      for (const u of users) {
        const userId = (u.user_id ?? '').toString().trim()
        if (!userId) continue

        // De-dupe: avoid re-notifying the same user for same memory within 2 hours
        const { data: existing } = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('type', 'memory_expiring')
          .gte('created_at', twoHoursAgoIso)
          .filter('data->>memory_id', 'eq', memoryId)
          .limit(1)

        if (existing && existing.length > 0) continue

        processedPairs += 1

        // Always create in-app notification (settings page is for PUSH preferences).
        const { error: nErr } = await supabase.from('notifications').insert({
          user_id: userId,
          title: 'Memory Expiring Soon',
          message: `${memoryTitle} will be sealed in less than 1 hour`,
          type: 'memory_expiring',
          data: {
            memory_id: memoryId,
            memory_title: memoryTitle,
            expires_at: expiresAt,
            deep_link: `https://capapp.co/memory/${memoryId}`,
          },
          is_read: false,
        })

        if (!nErr) inAppCreated += 1

        // Push is optional and respects user prefs
        const { data: prefs } = await supabase
          .from('email_preferences')
          .select('push_notifications_enabled, push_memory_expiring, push_memory_activity')
          .eq('user_id', userId)
          .maybeSingle()

        const typed = prefs as PrefsRow | null
        const masterEnabled = typed?.push_notifications_enabled !== false
        const expiringEnabled =
          (typed?.push_memory_expiring ?? typed?.push_memory_activity) !== false

        if (!masterEnabled || !expiringEnabled) continue

        const sent = await sendFcmToUser({
          supabase,
          userId,
          title: 'Memory Expiring Soon',
          body: `${memoryTitle} will be sealed in less than 1 hour`,
          data: {
            memory_id: memoryId,
            expires_at: expiresAt,
            deep_link: `https://capapp.co/memory/${memoryId}`,
          },
        }).catch(() => 0)

        pushesSent += sent
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        processed: processedPairs,
        in_app_created: inAppCreated,
        pushes_sent: pushesSent,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error sending memory expiring notifications:', error)
    return new Response(JSON.stringify({ ok: false, error: error?.message ?? String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

