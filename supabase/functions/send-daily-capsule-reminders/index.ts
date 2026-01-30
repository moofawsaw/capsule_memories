import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type SettingsRow = {
  user_id: string
  utc_offset_minutes: number
  reminder_enabled: boolean
  reminder_hour: number
  reminder_minute: number
  next_reminder_at: string
}

function ymdFromUtcMillis(ms: number): string {
  const d = new Date(ms)
  const y = d.getUTCFullYear()
  const m = `${d.getUTCMonth() + 1}`.padStart(2, '0')
  const day = `${d.getUTCDate()}`.padStart(2, '0')
  return `${y}-${m}-${day}`
}

function computeNextReminderAtIso(params: {
  utcOffsetMinutes: number
  baseLocalY: number
  baseLocalM0: number
  baseLocalD: number
  hour: number
  baseMinute: number
  minuteJitterHalfSpan: number
}): string {
  const {
    utcOffsetMinutes,
    baseLocalY,
    baseLocalM0,
    baseLocalD,
    hour,
    baseMinute,
    minuteJitterHalfSpan,
  } = params

  // Small random jitter around the configured minute, staying within the same hour.
  // Example: 20:00 ± 15m => [19:45..20:15] effectively clamps within 20:00 hour.
  const delta = Math.floor((Math.random() * (minuteJitterHalfSpan * 2 + 1)) - minuteJitterHalfSpan)
  const rawMinute = (baseMinute ?? 0) + delta
  const targetMinute = Math.max(0, Math.min(59, rawMinute))

  // Compute target local datetime as UTC components, then shift back by offset
  const targetUtcMs =
    Date.UTC(baseLocalY, baseLocalM0, baseLocalD, hour, targetMinute, 0, 0) -
    utcOffsetMinutes * 60 * 1000

  return new Date(targetUtcMs).toISOString()
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

  const payload = {
    notification: {
      title,
      body,
      sound: 'default',
      priority: 'high',
    },
    data: {
      // DeepLinkService accepts /app/... for push taps
      deep_link: '/app/daily-capsule',
      ...(data ?? {}),
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    priority: 'high',
    content_available: true,
  }

  const endpoint = 'https://fcm.googleapis.com/fcm/send'
  const requests = tokens.map(async (t: { token: string }) => {
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: {
        Authorization: `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ ...payload, to: t.token }),
    })
    const json = await res.json().catch(() => ({}))

    // Mark invalid registrations inactive
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

    const now = Date.now()

    const { data: due, error: dueError } = await supabase
      .from('daily_capsule_settings')
      .select('user_id, utc_offset_minutes, reminder_enabled, reminder_hour, reminder_minute, next_reminder_at')
      .eq('reminder_enabled', true)
      .lte('next_reminder_at', new Date(now).toISOString())

    if (dueError) throw new Error(`Failed to fetch due settings: ${dueError.message}`)

    const rows: SettingsRow[] = (due ?? []) as SettingsRow[]
    if (rows.length === 0) {
      return new Response(JSON.stringify({ ok: true, processed: 0, sent: 0 }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    let sentTotal = 0

    for (const row of rows) {
      const userId = row.user_id
      const offsetMin = row.utc_offset_minutes ?? 0

      // Local "now" expressed as UTC milliseconds (shifted by offset)
      const nowLocalMs = now + offsetMin * 60 * 1000
      const localDate = ymdFromUtcMillis(nowLocalMs)

      // Skip if user has disabled Daily Capsule reminder pushes OR master pushes
      const { data: prefs } = await supabase
        .from('email_preferences')
        .select('push_notifications_enabled, push_daily_capsule_reminder, push_daily_capsule')
        .eq('user_id', userId)
        .maybeSingle()

      const reminderEnabled =
        (prefs?.push_daily_capsule_reminder ?? prefs?.push_daily_capsule) !== false

      if (prefs && (prefs.push_notifications_enabled === false || reminderEnabled === false)) {
        // Still advance schedule to tomorrow
        const localNow = new Date(nowLocalMs)
        const nextIso = computeNextReminderAtIso({
          utcOffsetMinutes: offsetMin,
          baseLocalY: localNow.getUTCFullYear(),
          baseLocalM0: localNow.getUTCMonth(),
          baseLocalD: localNow.getUTCDate() + 1,
          hour: row.reminder_hour ?? 20,
          baseMinute: row.reminder_minute ?? 0,
          minuteJitterHalfSpan: 15,
        })
        await supabase
          .from('daily_capsule_settings')
          .update({ next_reminder_at: nextIso, updated_at: new Date().toISOString() })
          .eq('user_id', userId)
        continue
      }

      // Check if completed today
      const { data: entry } = await supabase
        .from('daily_capsule_entries')
        .select('id')
        .eq('user_id', userId)
        .eq('local_date', localDate)
        .maybeSingle()

      const completed = !!entry

      if (!completed) {
        const sent = await sendFcmToUser({
          supabase,
          userId,
          title: 'Daily Capsule',
          body: 'Don’t lose your streak — post your Daily Capsule for today.',
          data: { kind: 'daily_capsule_reminder' },
        })
        sentTotal += sent
      }

      // Advance schedule to tomorrow around 8pm local
      const localNow = new Date(nowLocalMs)
      const nextIso = computeNextReminderAtIso({
        utcOffsetMinutes: offsetMin,
        baseLocalY: localNow.getUTCFullYear(),
        baseLocalM0: localNow.getUTCMonth(),
        baseLocalD: localNow.getUTCDate() + 1,
        hour: row.reminder_hour ?? 20,
        baseMinute: row.reminder_minute ?? 0,
        minuteJitterHalfSpan: 15,
      })

      await supabase
        .from('daily_capsule_settings')
        .update({ next_reminder_at: nextIso, updated_at: new Date().toISOString() })
        .eq('user_id', userId)
    }

    return new Response(JSON.stringify({ ok: true, processed: rows.length, sent: sentTotal }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ ok: false, error: error?.message ?? String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

