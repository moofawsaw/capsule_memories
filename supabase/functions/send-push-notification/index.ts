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
    const { user_id, title, body, data, notification_type } = payload

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
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

    // Create in-app notification record
    await supabaseClient.from('notifications').insert({
      user_id,
      title,
      message: body,
      type: notification_type,
      data: data || {},
      is_read: false,
    })

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