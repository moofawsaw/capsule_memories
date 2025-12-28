-- Add push notification preference columns to email_preferences table
ALTER TABLE email_preferences 
  ADD COLUMN IF NOT EXISTS push_notifications_enabled BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_memory_invites BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_memory_activity BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_memory_sealed BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_reactions BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_new_followers BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_friend_requests BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS push_group_invites BOOLEAN DEFAULT TRUE;

-- Add comments to new columns
COMMENT ON COLUMN email_preferences.push_notifications_enabled IS 'Master toggle for all push notifications';
COMMENT ON COLUMN email_preferences.push_memory_invites IS 'Enable push notifications for memory invitations';
COMMENT ON COLUMN email_preferences.push_memory_activity IS 'Enable push notifications for memory activity';
COMMENT ON COLUMN email_preferences.push_memory_sealed IS 'Enable push notifications when memories are sealed';
COMMENT ON COLUMN email_preferences.push_reactions IS 'Enable push notifications for story reactions';
COMMENT ON COLUMN email_preferences.push_new_followers IS 'Enable push notifications for new followers';
COMMENT ON COLUMN email_preferences.push_friend_requests IS 'Enable push notifications for friend requests';
COMMENT ON COLUMN email_preferences.push_group_invites IS 'Enable push notifications for group invitations';

-- Update RLS policies remain the same (already allow users to manage their own preferences)
-- No additional policies needed as existing policies cover the new columns