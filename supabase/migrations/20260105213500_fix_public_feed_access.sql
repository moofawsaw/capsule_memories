-- Migration: Fix public feed access by granting anonymous SELECT access to user_profiles_public view
-- Purpose: Allow unauthenticated users to query stories that join to user_profiles_public
-- This resolves the "permission denied for table user_profiles" error when anonymous users try to view public stories

-- CRITICAL FIX: Views CANNOT have RLS policies - they inherit security from underlying tables
-- Instead, we grant direct SELECT permission to the anon (anonymous) role

-- Grant SELECT permission on user_profiles_public view to anonymous users
GRANT SELECT ON user_profiles_public TO anon;

-- Add comment explaining the grant
COMMENT ON VIEW user_profiles_public IS 
'Public view of user_profiles that exposes only non-sensitive data (avatar_url, bio, display_name, follower_count, following_count, is_verified, popularity_score, posting_streak, username). 
Anonymous users can SELECT from this view to display user information in public feeds.
PII (email, location, ban status) is NOT included in this view.';