-- Migration: Daily Capsule (daily journal)
-- Adds:
-- - memories.is_daily_capsule to hide per-user journal memory from feeds
-- - daily_capsule_settings (timezone offset + reminder scheduling)
-- - daily_capsule_entries (one action per local day)

-- 1) Mark hidden Daily Capsule memories
ALTER TABLE public.memories
ADD COLUMN IF NOT EXISTS is_daily_capsule BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_memories_is_daily_capsule
ON public.memories(is_daily_capsule)
WHERE is_daily_capsule = true;

COMMENT ON COLUMN public.memories.is_daily_capsule IS
  'True for a per-user private Daily Capsule memory (hidden from normal feeds).';

-- 2) Settings (device timezone offset; reminder at ~8pm local)
CREATE TABLE IF NOT EXISTS public.daily_capsule_settings (
  user_id UUID PRIMARY KEY REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  utc_offset_minutes INTEGER NOT NULL,
  reminder_enabled BOOLEAN NOT NULL DEFAULT true,
  reminder_hour SMALLINT NOT NULL DEFAULT 20,
  reminder_minute SMALLINT NOT NULL DEFAULT 0,
  next_reminder_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_daily_capsule_settings_next_reminder_at
ON public.daily_capsule_settings(next_reminder_at);

COMMENT ON TABLE public.daily_capsule_settings IS
  'Per-user Daily Capsule reminder scheduling (based on device UTC offset).';

-- 3) Entries (one per day)
CREATE TABLE IF NOT EXISTS public.daily_capsule_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  local_date DATE NOT NULL,
  utc_offset_minutes INTEGER NOT NULL,
  completion_type TEXT NOT NULL CHECK (completion_type IN ('mood', 'instant_story', 'memory_post')),
  mood_emoji TEXT,
  story_id UUID REFERENCES public.stories(id) ON DELETE SET NULL,
  memory_id UUID REFERENCES public.memories(id) ON DELETE SET NULL,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT daily_capsule_entries_unique_day UNIQUE (user_id, local_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_capsule_entries_user_date
ON public.daily_capsule_entries(user_id, local_date DESC);

COMMENT ON TABLE public.daily_capsule_entries IS
  'One daily journal completion per user per local date.';

-- 4) RLS
ALTER TABLE public.daily_capsule_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_capsule_entries ENABLE ROW LEVEL SECURITY;

-- Settings: user-only
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'daily_capsule_settings'
      AND policyname = 'users_manage_own_daily_capsule_settings'
  ) THEN
    CREATE POLICY "users_manage_own_daily_capsule_settings"
    ON public.daily_capsule_settings
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- Entries: user-only
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'daily_capsule_entries'
      AND policyname = 'users_manage_own_daily_capsule_entries'
  ) THEN
    CREATE POLICY "users_manage_own_daily_capsule_entries"
    ON public.daily_capsule_entries
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- 5) Notification preference column (optional gate for reminders)
ALTER TABLE public.email_preferences
ADD COLUMN IF NOT EXISTS push_daily_capsule BOOLEAN DEFAULT TRUE;

COMMENT ON COLUMN public.email_preferences.push_daily_capsule IS
  'Enable push notifications for Daily Capsule reminders (8pm local if incomplete).';

