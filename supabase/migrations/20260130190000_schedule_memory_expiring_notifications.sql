-- Schedule memory expiring notifications (1 hour before expires_at)
-- Uses pg_cron (scheduler) + pg_net (HTTP) to invoke the deployed Edge Function.
--
-- The Edge Function `send-memory-expiring-notifications` is responsible for:
-- - Creating the in-app `notifications` row (type = memory_expiring)
-- - Sending the push notification (respecting push prefs)
--
-- NOTE: This job runs every minute, but the edge function only acts on memories in a
-- narrow window around (now + 60 minutes), and dedupes, so each memory notifies once.

-- IMPORTANT:
-- Do NOT run CREATE EXTENSION here. On Supabase, attempting to (re)create pg_cron
-- can fail due to privilege scripts (even when the extension already exists).
-- We assume pg_cron + pg_net are enabled in the project via Dashboard → Extensions.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    RAISE EXCEPTION 'pg_cron extension is not enabled. Enable it in Supabase Dashboard → Database → Extensions.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') THEN
    RAISE EXCEPTION 'pg_net extension is not enabled. Enable it in Supabase Dashboard → Database → Extensions.';
  END IF;
END $$;

DO $$
DECLARE
  existing_jobid INTEGER;
BEGIN
  -- Unschedule any existing job with the same name (idempotent re-deploys)
  SELECT jobid
  INTO existing_jobid
  FROM cron.job
  WHERE jobname = 'send-memory-expiring-notifications';

  IF existing_jobid IS NOT NULL THEN
    PERFORM cron.unschedule(existing_jobid);
  END IF;

  -- Schedule: every minute
  PERFORM cron.schedule(
    'send-memory-expiring-notifications',
    '* * * * *',
    $cron$
      SELECT
        net.http_post(
          url := 'https://resdvutqgrbbylknaxjp.functions.supabase.co/send-memory-expiring-notifications',
          headers := jsonb_build_object('Content-Type', 'application/json'),
          body := '{}'::jsonb
        );
    $cron$
  );
END $$;

