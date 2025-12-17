-- Location: supabase/migrations/20251216024537_capsule_complete_schema.sql
-- Schema Analysis: Fresh database - implementing complete Capsule app schema
-- Integration Type: Complete schema creation with authentication
-- Dependencies: None (fresh project)

-- ============================================================================
-- 1. CUSTOM TYPES
-- ============================================================================

CREATE TYPE public.memory_visibility AS ENUM ('public', 'private');
CREATE TYPE public.memory_duration AS ENUM ('12_hours', '24_hours', '3_days');
CREATE TYPE public.memory_state AS ENUM ('open', 'sealed');
CREATE TYPE public.friend_request_state AS ENUM ('pending', 'accepted', 'declined');
CREATE TYPE public.reaction_emoji AS ENUM ('heart', 'thumbs_up', 'fire', 'cry');
CREATE TYPE public.reaction_text AS ENUM ('lol', 'hott', 'wild', 'omg');
CREATE TYPE public.report_reason AS ENUM ('inappropriate', 'harassment', 'spam', 'violence', 'hate_speech', 'false_information', 'other');
CREATE TYPE public.notification_type AS ENUM (
    'memory_invite',
    'friend_request',
    'new_story',
    'followed',
    'memory_expiring',
    'memory_sealed'
);

-- ============================================================================
-- 2. CORE TABLES (No Foreign Keys)
-- ============================================================================

-- User Profiles (Critical intermediary table for PostgREST compatibility)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    is_verified BOOLEAN DEFAULT false,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    posting_streak INTEGER DEFAULT 0,
    last_post_date DATE,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    location_name TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Memories (Collaborative video timelines)
CREATE TABLE public.memories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    visibility public.memory_visibility NOT NULL DEFAULT 'private'::public.memory_visibility,
    duration public.memory_duration NOT NULL DEFAULT '12_hours'::public.memory_duration,
    state public.memory_state NOT NULL DEFAULT 'open'::public.memory_state,
    invite_code TEXT NOT NULL UNIQUE,
    qr_code_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    sealed_at TIMESTAMPTZ,
    view_count INTEGER DEFAULT 0,
    contributor_count INTEGER DEFAULT 0,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    location_name TEXT
);

-- Stories (Individual video contributions)
CREATE TABLE public.stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    memory_id UUID NOT NULL REFERENCES public.memories(id) ON DELETE CASCADE,
    contributor_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    duration_seconds INTEGER NOT NULL,
    capture_timestamp TIMESTAMPTZ NOT NULL,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    location_name TEXT,
    text_overlays JSONB DEFAULT '[]'::jsonb,
    stickers JSONB DEFAULT '[]'::jsonb,
    drawings JSONB DEFAULT '[]'::jsonb,
    background_music JSONB,
    is_from_camera_roll BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Groups (Named lists of friends)
CREATE TABLE public.groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    invite_code TEXT NOT NULL UNIQUE,
    qr_code_url TEXT,
    member_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. RELATIONSHIP TABLES (Junction Tables)
-- ============================================================================

-- Friends (Mutual relationships)
CREATE TABLE public.friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT friends_no_self_reference CHECK (user_id != friend_id),
    CONSTRAINT friends_unique_pair UNIQUE (user_id, friend_id)
);

-- Friend Requests
CREATE TABLE public.friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status public.friend_request_state NOT NULL DEFAULT 'pending'::public.friend_request_state,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT friend_requests_no_self_reference CHECK (sender_id != receiver_id),
    CONSTRAINT friend_requests_unique_pair UNIQUE (sender_id, receiver_id)
);

-- Follows (One-way subscriptions)
CREATE TABLE public.follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT follows_no_self_reference CHECK (follower_id != following_id),
    CONSTRAINT follows_unique_pair UNIQUE (follower_id, following_id)
);

-- Memory Contributors
CREATE TABLE public.memory_contributors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    memory_id UUID NOT NULL REFERENCES public.memories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT memory_contributors_unique_pair UNIQUE (memory_id, user_id)
);

-- Group Members
CREATE TABLE public.group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT group_members_unique_pair UNIQUE (group_id, user_id)
);

-- ============================================================================
-- 4. INTERACTION TABLES
-- ============================================================================

-- Reactions (8 types: 4 emojis + 4 text reactions)
CREATE TABLE public.reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    reaction_type TEXT NOT NULL,
    tap_count INTEGER DEFAULT 1 CHECK (tap_count <= 10),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reactions_unique_user_story_type UNIQUE (story_id, user_id, reaction_type),
    CONSTRAINT reactions_type_check CHECK (
        reaction_type IN ('heart', 'thumbs_up', 'fire', 'cry', 'lol', 'hott', 'wild', 'omg')
    )
);

-- Reports
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    reason public.report_reason NOT NULL,
    details TEXT,
    case_number TEXT NOT NULL UNIQUE,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMPTZ
);

-- Notifications
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    type public.notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 5. INDEXES (Performance Optimization)
-- ============================================================================

-- User Profiles Indexes
CREATE INDEX idx_user_profiles_username ON public.user_profiles(username);
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_verified ON public.user_profiles(is_verified);
CREATE INDEX idx_user_profiles_location ON public.user_profiles(location_lat, location_lng);

-- Memories Indexes
CREATE INDEX idx_memories_creator_id ON public.memories(creator_id);
CREATE INDEX idx_memories_state ON public.memories(state);
CREATE INDEX idx_memories_visibility ON public.memories(visibility);
CREATE INDEX idx_memories_expires_at ON public.memories(expires_at);
CREATE INDEX idx_memories_created_at ON public.memories(created_at DESC);
CREATE INDEX idx_memories_invite_code ON public.memories(invite_code);

-- Stories Indexes
CREATE INDEX idx_stories_memory_id ON public.stories(memory_id);
CREATE INDEX idx_stories_contributor_id ON public.stories(contributor_id);
CREATE INDEX idx_stories_capture_timestamp ON public.stories(capture_timestamp);
CREATE INDEX idx_stories_created_at ON public.stories(created_at DESC);

-- Groups Indexes
CREATE INDEX idx_groups_creator_id ON public.groups(creator_id);
CREATE INDEX idx_groups_invite_code ON public.groups(invite_code);

-- Friends Indexes
CREATE INDEX idx_friends_user_id ON public.friends(user_id);
CREATE INDEX idx_friends_friend_id ON public.friends(friend_id);

-- Friend Requests Indexes
CREATE INDEX idx_friend_requests_sender_id ON public.friend_requests(sender_id);
CREATE INDEX idx_friend_requests_receiver_id ON public.friend_requests(receiver_id);
CREATE INDEX idx_friend_requests_status ON public.friend_requests(status);

-- Follows Indexes
CREATE INDEX idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX idx_follows_following_id ON public.follows(following_id);

-- Memory Contributors Indexes
CREATE INDEX idx_memory_contributors_memory_id ON public.memory_contributors(memory_id);
CREATE INDEX idx_memory_contributors_user_id ON public.memory_contributors(user_id);

-- Group Members Indexes
CREATE INDEX idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX idx_group_members_user_id ON public.group_members(user_id);

-- Reactions Indexes
CREATE INDEX idx_reactions_story_id ON public.reactions(story_id);
CREATE INDEX idx_reactions_user_id ON public.reactions(user_id);

-- Reports Indexes
CREATE INDEX idx_reports_story_id ON public.reports(story_id);
CREATE INDEX idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX idx_reports_status ON public.reports(status);

-- Notifications Indexes
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);

-- ============================================================================
-- 6. FUNCTIONS (Helper Functions for Business Logic)
-- ============================================================================

-- Function to generate invite code
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $func$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$func$;

-- Function to generate case number for reports
CREATE OR REPLACE FUNCTION public.generate_case_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $func$
BEGIN
    RETURN 'CASE-' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDD') || '-' || 
           lpad(floor(random() * 10000)::text, 4, '0');
END;
$func$;

-- Function to check if user is friend
CREATE OR REPLACE FUNCTION public.are_friends(user1_uuid UUID, user2_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $func$
SELECT EXISTS (
    SELECT 1 FROM public.friends f
    WHERE (f.user_id = user1_uuid AND f.friend_id = user2_uuid)
       OR (f.user_id = user2_uuid AND f.friend_id = user1_uuid)
)
$func$;

-- Function to check if memory is accessible
CREATE OR REPLACE FUNCTION public.can_access_memory(memory_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $func$
SELECT EXISTS (
    SELECT 1 FROM public.memories m
    LEFT JOIN public.memory_contributors mc ON m.id = mc.memory_id
    WHERE m.id = memory_uuid
    AND (
        m.visibility = 'public'::public.memory_visibility
        OR m.creator_id = auth.uid()
        OR mc.user_id = auth.uid()
    )
)
$func$;

-- ============================================================================
-- 7. ROW LEVEL SECURITY (Enable RLS)
-- ============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memory_contributors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 8. RLS POLICIES (Access Control)
-- ============================================================================

-- User Profiles Policies (Pattern 1: Core User Table)
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "public_can_view_user_profiles"
ON public.user_profiles
FOR SELECT
TO public
USING (true);

-- Memories Policies (Pattern 4: Public Read, Private Write)
CREATE POLICY "public_can_view_public_memories"
ON public.memories
FOR SELECT
TO public
USING (visibility = 'public'::public.memory_visibility);

CREATE POLICY "users_can_view_contributed_memories"
ON public.memories
FOR SELECT
TO authenticated
USING (
    creator_id = auth.uid() 
    OR EXISTS (
        SELECT 1 FROM public.memory_contributors mc
        WHERE mc.memory_id = id AND mc.user_id = auth.uid()
    )
);

CREATE POLICY "users_manage_own_memories"
ON public.memories
FOR ALL
TO authenticated
USING (creator_id = auth.uid())
WITH CHECK (creator_id = auth.uid());

-- Stories Policies
CREATE POLICY "public_can_view_stories_in_public_memories"
ON public.stories
FOR SELECT
TO public
USING (
    EXISTS (
        SELECT 1 FROM public.memories m
        WHERE m.id = memory_id AND m.visibility = 'public'::public.memory_visibility
    )
);

CREATE POLICY "contributors_can_view_stories"
ON public.stories
FOR SELECT
TO authenticated
USING (public.can_access_memory(memory_id));

CREATE POLICY "users_manage_own_stories"
ON public.stories
FOR ALL
TO authenticated
USING (contributor_id = auth.uid())
WITH CHECK (contributor_id = auth.uid());

-- Groups Policies (Pattern 2: Simple User Ownership)
CREATE POLICY "users_manage_own_groups"
ON public.groups
FOR ALL
TO authenticated
USING (creator_id = auth.uid())
WITH CHECK (creator_id = auth.uid());

CREATE POLICY "members_can_view_groups"
ON public.groups
FOR SELECT
TO authenticated
USING (
    creator_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.group_members gm
        WHERE gm.group_id = id AND gm.user_id = auth.uid()
    )
);

-- Friends Policies
CREATE POLICY "users_manage_own_friendships"
ON public.friends
FOR ALL
TO authenticated
USING (user_id = auth.uid() OR friend_id = auth.uid())
WITH CHECK (user_id = auth.uid() OR friend_id = auth.uid());

-- Friend Requests Policies
CREATE POLICY "users_manage_own_friend_requests"
ON public.friend_requests
FOR ALL
TO authenticated
USING (sender_id = auth.uid() OR receiver_id = auth.uid())
WITH CHECK (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Follows Policies
CREATE POLICY "users_manage_own_follows"
ON public.follows
FOR ALL
TO authenticated
USING (follower_id = auth.uid())
WITH CHECK (follower_id = auth.uid());

CREATE POLICY "users_can_view_follows"
ON public.follows
FOR SELECT
TO authenticated
USING (true);

-- Memory Contributors Policies
CREATE POLICY "contributors_manage_own_contributions"
ON public.memory_contributors
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "memory_creators_manage_contributors"
ON public.memory_contributors
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.memories m
        WHERE m.id = memory_id AND m.creator_id = auth.uid()
    )
);

-- Group Members Policies
CREATE POLICY "members_manage_own_group_membership"
ON public.group_members
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "group_creators_manage_members"
ON public.group_members
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = group_id AND g.creator_id = auth.uid()
    )
);

-- Reactions Policies (Pattern 2: Simple User Ownership)
CREATE POLICY "users_manage_own_reactions"
ON public.reactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "public_can_view_reactions"
ON public.reactions
FOR SELECT
TO public
USING (true);

-- Reports Policies (Pattern 2: Simple User Ownership)
CREATE POLICY "users_manage_own_reports"
ON public.reports
FOR ALL
TO authenticated
USING (reporter_id = auth.uid())
WITH CHECK (reporter_id = auth.uid());

-- Notifications Policies (Pattern 2: Simple User Ownership)
CREATE POLICY "users_manage_own_notifications"
ON public.notifications
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- 9. TRIGGERS
-- ============================================================================

-- Trigger function to create user profile automatically
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
    INSERT INTO public.user_profiles (
        id,
        username,
        email,
        display_name,
        avatar_url,
        bio
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        COALESCE(NEW.raw_user_meta_data->>'bio', '')
    );
    RETURN NEW;
END;
$func$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Trigger function to update memory state
CREATE OR REPLACE FUNCTION public.update_memory_state()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
    IF NEW.expires_at <= CURRENT_TIMESTAMP AND NEW.state = 'open'::public.memory_state THEN
        NEW.state := 'sealed'::public.memory_state;
        NEW.sealed_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$func$;

CREATE TRIGGER check_memory_expiration
    BEFORE UPDATE ON public.memories
    FOR EACH ROW
    EXECUTE FUNCTION public.update_memory_state();

-- Trigger function to update follower/following counts
CREATE OR REPLACE FUNCTION public.update_follow_counts()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.user_profiles
        SET following_count = following_count + 1
        WHERE id = NEW.follower_id;
        
        UPDATE public.user_profiles
        SET follower_count = follower_count + 1
        WHERE id = NEW.following_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.user_profiles
        SET following_count = GREATEST(following_count - 1, 0)
        WHERE id = OLD.follower_id;
        
        UPDATE public.user_profiles
        SET follower_count = GREATEST(follower_count - 1, 0)
        WHERE id = OLD.following_id;
    END IF;
    RETURN NEW;
END;
$func$;

CREATE TRIGGER update_follow_counts_trigger
    AFTER INSERT OR DELETE ON public.follows
    FOR EACH ROW
    EXECUTE FUNCTION public.update_follow_counts();

-- Trigger function to update group member count
CREATE OR REPLACE FUNCTION public.update_group_member_count()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.groups
        SET member_count = member_count + 1
        WHERE id = NEW.group_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.groups
        SET member_count = GREATEST(member_count - 1, 0)
        WHERE id = OLD.group_id;
    END IF;
    RETURN NEW;
END;
$func$;

CREATE TRIGGER update_group_member_count_trigger
    AFTER INSERT OR DELETE ON public.group_members
    FOR EACH ROW
    EXECUTE FUNCTION public.update_group_member_count();

-- Trigger function to update memory contributor count
CREATE OR REPLACE FUNCTION public.update_memory_contributor_count()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.memories
        SET contributor_count = contributor_count + 1
        WHERE id = NEW.memory_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.memories
        SET contributor_count = GREATEST(contributor_count - 1, 0)
        WHERE id = OLD.memory_id;
    END IF;
    RETURN NEW;
END;
$func$;

CREATE TRIGGER update_memory_contributor_count_trigger
    AFTER INSERT OR DELETE ON public.memory_contributors
    FOR EACH ROW
    EXECUTE FUNCTION public.update_memory_contributor_count();

-- Trigger function to set invite code on insert
CREATE OR REPLACE FUNCTION public.set_memory_invite_code()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := public.generate_invite_code();
    END IF;
    RETURN NEW;
END;
$func$;

CREATE TRIGGER set_memory_invite_code_trigger
    BEFORE INSERT ON public.memories
    FOR EACH ROW
    EXECUTE FUNCTION public.set_memory_invite_code();

-- Trigger function to set group invite code
CREATE OR REPLACE FUNCTION public.set_group_invite_code()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := public.generate_invite_code();
    END IF;
    RETURN NEW;
END;
$func$;

CREATE TRIGGER set_group_invite_code_trigger
    BEFORE INSERT ON public.groups
    FOR EACH ROW
    EXECUTE FUNCTION public.set_group_invite_code();

-- Trigger function to set case number for reports
CREATE OR REPLACE FUNCTION public.set_report_case_number()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $func$
BEGIN
    IF NEW.case_number IS NULL OR NEW.case_number = '' THEN
        NEW.case_number := public.generate_case_number();
    END IF;
    RETURN NEW;
END;
$func$;

CREATE TRIGGER set_report_case_number_trigger
    BEFORE INSERT ON public.reports
    FOR EACH ROW
    EXECUTE FUNCTION public.set_report_case_number();

-- ============================================================================
-- 10. MOCK DATA (For Testing and Development)
-- ============================================================================

DO $$
DECLARE
    user1_id UUID := gen_random_uuid();
    user2_id UUID := gen_random_uuid();
    user3_id UUID := gen_random_uuid();
    memory1_id UUID := gen_random_uuid();
    memory2_id UUID := gen_random_uuid();
    story1_id UUID := gen_random_uuid();
    story2_id UUID := gen_random_uuid();
    story3_id UUID := gen_random_uuid();
    group1_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (user1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'alex@capsule.app', crypt('capsule123', gen_salt('bf', 10)), now(), now(), now(),
         '{"username": "alex_memorymaker", "display_name": "Alex", "avatar_url": "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400", "bio": "Capturing life one moment at a time"}'::jsonb,
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sam@capsule.app', crypt('capsule123', gen_salt('bf', 10)), now(), now(), now(),
         '{"username": "sam_storyteller", "display_name": "Sam", "avatar_url": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400", "bio": "Living for the stories we create together"}'::jsonb,
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'jordan@capsule.app', crypt('capsule123', gen_salt('bf', 10)), now(), now(), now(),
         '{"username": "jordan_moments", "display_name": "Jordan", "avatar_url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400", "bio": "Adventure seeker and memory collector"}'::jsonb,
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create memories
    INSERT INTO public.memories (id, title, creator_id, visibility, duration, state, invite_code, expires_at, created_at)
    VALUES
        (memory1_id, 'Beach Day 2024', user1_id, 'public'::public.memory_visibility, '24_hours'::public.memory_duration, 
         'open'::public.memory_state, 'BEACH24A', CURRENT_TIMESTAMP + INTERVAL '24 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours'),
        (memory2_id, 'Private Party', user2_id, 'private'::public.memory_visibility, '12_hours'::public.memory_duration,
         'open'::public.memory_state, 'PARTY12B', CURRENT_TIMESTAMP + INTERVAL '10 hours', CURRENT_TIMESTAMP - INTERVAL '1 hour');

    -- Create stories
    INSERT INTO public.stories (id, memory_id, contributor_id, video_url, thumbnail_url, duration_seconds, capture_timestamp, location_name)
    VALUES
        (story1_id, memory1_id, user1_id, 
         'https://storage.googleapis.com/capsule-videos/beach1.mp4',
         'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
         15, CURRENT_TIMESTAMP - INTERVAL '1 hour 30 minutes', 'Santa Monica Beach'),
        (story2_id, memory1_id, user2_id,
         'https://storage.googleapis.com/capsule-videos/beach2.mp4', 
         'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=800',
         20, CURRENT_TIMESTAMP - INTERVAL '1 hour', 'Santa Monica Beach'),
        (story3_id, memory2_id, user3_id,
         'https://storage.googleapis.com/capsule-videos/party1.mp4',
         'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800',
         18, CURRENT_TIMESTAMP - INTERVAL '30 minutes', 'Downtown Loft');

    -- Create group
    INSERT INTO public.groups (id, name, creator_id, invite_code)
    VALUES
        (group1_id, 'Beach Crew', user1_id, 'CREW2024');

    -- Add memory contributors
    INSERT INTO public.memory_contributors (memory_id, user_id)
    VALUES
        (memory1_id, user1_id),
        (memory1_id, user2_id),
        (memory2_id, user2_id),
        (memory2_id, user3_id);

    -- Add group members
    INSERT INTO public.group_members (group_id, user_id)
    VALUES
        (group1_id, user1_id),
        (group1_id, user2_id),
        (group1_id, user3_id);

    -- Create friendships
    INSERT INTO public.friends (user_id, friend_id)
    VALUES
        (user1_id, user2_id),
        (user2_id, user1_id),
        (user1_id, user3_id),
        (user3_id, user1_id);

    -- Create follows
    INSERT INTO public.follows (follower_id, following_id)
    VALUES
        (user1_id, user2_id),
        (user2_id, user1_id),
        (user1_id, user3_id),
        (user3_id, user1_id),
        (user2_id, user3_id);

    -- Create reactions
    INSERT INTO public.reactions (story_id, user_id, reaction_type, tap_count)
    VALUES
        (story1_id, user2_id, 'heart', 5),
        (story1_id, user3_id, 'fire', 3),
        (story2_id, user1_id, 'lol', 7),
        (story3_id, user1_id, 'wild', 4);

    -- Create notifications
    INSERT INTO public.notifications (user_id, type, title, message)
    VALUES
        (user1_id, 'new_story'::public.notification_type, 'New Story Added', 'Sam added a new story to Beach Day 2024'),
        (user2_id, 'memory_invite'::public.notification_type, 'Memory Invitation', 'Alex invited you to contribute to Beach Day 2024'),
        (user3_id, 'followed'::public.notification_type, 'New Follower', 'Sam started following you');

    RAISE NOTICE 'Mock data created successfully';
END $$;