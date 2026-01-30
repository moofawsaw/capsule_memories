-- Split push notification preferences so each push type can be toggled independently.
-- Previously, multiple push types shared grouped flags (e.g. push_memory_activity).

ALTER TABLE public.email_preferences
  ADD COLUMN IF NOT EXISTS push_new_story BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_memory_expiring BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_followed BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_new_follower BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_daily_capsule_reminder BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_friend_daily_capsule_completed BOOLEAN DEFAULT TRUE;

COMMENT ON COLUMN public.email_preferences.push_new_story IS
  'Enable push notifications for new stories in memories (new_story).';
COMMENT ON COLUMN public.email_preferences.push_memory_expiring IS
  'Enable push notifications for memory expiring reminders (memory_expiring).';
COMMENT ON COLUMN public.email_preferences.push_followed IS
  'Enable push notifications for follow events (followed).';
COMMENT ON COLUMN public.email_preferences.push_new_follower IS
  'Enable push notifications for new follower events (new_follower).';
COMMENT ON COLUMN public.email_preferences.push_daily_capsule_reminder IS
  'Enable push notifications for Daily Capsule reminders (daily_capsule_reminder).';
COMMENT ON COLUMN public.email_preferences.push_friend_daily_capsule_completed IS
  'Enable push notifications when a friend completes their Daily Capsule (friend_daily_capsule_completed).';

