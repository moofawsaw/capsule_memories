-- Fix: group members + avatars not loading after recent RLS changes.
--
-- Symptom:
-- - Group member lists/avatars resolve to empty because the app cannot SELECT from public.user_profiles
--   for users other than auth.uid().
--
-- This restores the expected behavior for authenticated users by ensuring a permissive SELECT policy
-- exists on public.user_profiles.
--
-- Notes:
-- - Policies are OR-ed. Adding this policy will allow reads even if a stricter policy exists.
-- - This does NOT change write permissions.

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'user_profiles'
      AND policyname = 'authenticated_can_view_user_profiles'
  ) THEN
    CREATE POLICY "authenticated_can_view_user_profiles"
    ON public.user_profiles
    FOR SELECT
    TO authenticated
    USING (true);
  END IF;
END $$;

