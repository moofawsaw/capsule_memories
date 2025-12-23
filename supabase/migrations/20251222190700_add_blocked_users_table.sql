-- Migration: Add blocked_users table for user blocking functionality
-- This migration creates a table to track blocked users

-- Create blocked_users table
CREATE TABLE IF NOT EXISTS public.blocked_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT blocked_users_unique_pair UNIQUE (blocker_id, blocked_id),
    CONSTRAINT cannot_block_self CHECK (blocker_id != blocked_id)
);

-- Create indexes for performance
CREATE INDEX idx_blocked_users_blocker_id ON public.blocked_users(blocker_id);
CREATE INDEX idx_blocked_users_blocked_id ON public.blocked_users(blocked_id);

-- Enable RLS
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for blocked_users
CREATE POLICY users_manage_own_blocks ON public.blocked_users
    FOR ALL
    TO authenticated
    USING (blocker_id = auth.uid())
    WITH CHECK (blocker_id = auth.uid());

CREATE POLICY admins_can_view_all_blocks ON public.blocked_users
    FOR SELECT
    TO authenticated
    USING (has_role(auth.uid(), 'admin'::app_role));

-- Function to check if user is blocked
CREATE OR REPLACE FUNCTION public.is_user_blocked(
    p_blocker_id UUID,
    p_blocked_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.blocked_users
        WHERE blocker_id = p_blocker_id
        AND blocked_id = p_blocked_id
    );
END;
$$;

-- Trigger function to clean up relationships when blocking
CREATE OR REPLACE FUNCTION public.cleanup_relationships_on_block()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Remove friendship if exists
    DELETE FROM public.friends
    WHERE (user_id = NEW.blocker_id AND friend_id = NEW.blocked_id)
    OR (user_id = NEW.blocked_id AND friend_id = NEW.blocker_id);
    
    -- Remove follow relationships
    DELETE FROM public.follows
    WHERE (follower_id = NEW.blocker_id AND following_id = NEW.blocked_id)
    OR (follower_id = NEW.blocked_id AND following_id = NEW.blocker_id);
    
    -- Remove pending friend requests
    DELETE FROM public.friend_requests
    WHERE (sender_id = NEW.blocker_id AND receiver_id = NEW.blocked_id)
    OR (sender_id = NEW.blocked_id AND receiver_id = NEW.blocker_id);
    
    RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_block_cleanup_relationships
    AFTER INSERT ON public.blocked_users
    FOR EACH ROW
    EXECUTE FUNCTION public.cleanup_relationships_on_block();

COMMENT ON TABLE public.blocked_users IS 'Tracks blocked users to prevent unwanted interactions';
COMMENT ON FUNCTION public.is_user_blocked IS 'Checks if a user has blocked another user';
COMMENT ON FUNCTION public.cleanup_relationships_on_block IS 'Removes all relationships when a user is blocked';