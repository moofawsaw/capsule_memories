-- Migration: Daily Capsule user tags
-- Adds:
-- - public.user_tags: per-user custom tags (Gym, Baby Carter, etc.)
-- - daily_capsule_entries.tag_id: optional tag reference per day

-- 1) User tags (owned by user)
CREATE TABLE IF NOT EXISTS public.user_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_tags_unique_name UNIQUE (user_id, normalized_name)
);

CREATE INDEX IF NOT EXISTS idx_user_tags_user_id_created_at
ON public.user_tags(user_id, created_at DESC);

COMMENT ON TABLE public.user_tags IS
  'Per-user custom tags for organizing Daily Capsule stories.';

COMMENT ON COLUMN public.user_tags.normalized_name IS
  'Lowercased, trimmed version of name for uniqueness.';

-- 2) Add tag_id to daily capsule entries
ALTER TABLE public.daily_capsule_entries
ADD COLUMN IF NOT EXISTS tag_id UUID REFERENCES public.user_tags(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_daily_capsule_entries_tag_id
ON public.daily_capsule_entries(tag_id);

COMMENT ON COLUMN public.daily_capsule_entries.tag_id IS
  'Optional user-owned tag attached to the daily capsule entry.';

-- 3) RLS
ALTER TABLE public.user_tags ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_tags'
      AND policyname = 'users_manage_own_user_tags'
  ) THEN
    CREATE POLICY "users_manage_own_user_tags"
    ON public.user_tags
    FOR ALL
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

