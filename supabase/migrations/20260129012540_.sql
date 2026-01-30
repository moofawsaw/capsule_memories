-- Create cron job to send daily capsule reminders every minute
SELECT cron.schedule(
  'send-daily-capsule-reminders',
  '* * * * *',
  $$
  SELECT
    net.http_post(
        url:='https://resdvutqgrbbylknaxjp.supabase.co/functions/v1/send-daily-capsule-reminders',
        headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlc2R2dXRxZ3JiYnlsa25heGpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4NjE0NzgsImV4cCI6MjA4MTQzNzQ3OH0.ulBP1Kcl0MNL2Gr6FsJGg1f3rqorhsoIeptEUvkaKG4"}'::jsonb,
        body:='{}'::jsonb
    ) AS request_id;
  $$
);;
