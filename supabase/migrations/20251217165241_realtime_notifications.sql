-- Location: supabase/migrations/20251217165241_realtime_notifications.sql
-- Schema Analysis: Extending existing Capsule schema with notification triggers
-- Integration Type: Enhancement - adding notification automation
-- Dependencies: Complete schema from 20251216024537_capsule_complete_schema.sql must be applied first

-- ============================================================================
-- CRITICAL: PREREQUISITE VALIDATION (NON-BLOCKING)
-- ============================================================================
-- This migration REQUIRES the base schema to be applied first
-- This check will warn if tables are missing but won't prevent migration deployment

DO $$
DECLARE
    missing_tables TEXT[] := ARRAY[]::TEXT[];
    missing_types TEXT[] := ARRAY[]::TEXT[];
    can_proceed BOOLEAN := TRUE;
BEGIN
    -- Check for required tables
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'memory_contributors') THEN
        missing_tables := array_append(missing_tables, 'memory_contributors');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'friend_requests') THEN
        missing_tables := array_append(missing_tables, 'friend_requests');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'stories') THEN
        missing_tables := array_append(missing_tables, 'stories');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'follows') THEN
        missing_tables := array_append(missing_tables, 'follows');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'memories') THEN
        missing_tables := array_append(missing_tables, 'memories');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        missing_tables := array_append(missing_tables, 'notifications');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles') THEN
        missing_tables := array_append(missing_tables, 'user_profiles');
        can_proceed := FALSE;
    END IF;
    
    -- Check for required types
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        missing_types := array_append(missing_types, 'notification_type');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'friend_request_state') THEN
        missing_types := array_append(missing_types, 'friend_request_state');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'memory_state') THEN
        missing_types := array_append(missing_types, 'memory_state');
        can_proceed := FALSE;
    END IF;
    
    -- Report missing dependencies
    IF NOT can_proceed THEN
        RAISE WARNING '⚠️  PREREQUISITE CHECK FAILED - Missing Dependencies Detected';
        RAISE WARNING '═══════════════════════════════════════════════════════════';
        
        IF array_length(missing_tables, 1) > 0 THEN
            RAISE WARNING '❌ Missing Tables: %', array_to_string(missing_tables, ', ');
        END IF;
        
        IF array_length(missing_types, 1) > 0 THEN
            RAISE WARNING '❌ Missing Types: %', array_to_string(missing_types, ', ');
        END IF;
        
        RAISE WARNING '';
        RAISE WARNING '📋 REQUIRED ACTION:';
        RAISE WARNING '   Run migration 20251216024537_capsule_complete_schema.sql first';
        RAISE WARNING '';
        RAISE WARNING '⏭️  This migration will be skipped for now';
        RAISE WARNING '   Re-run after base schema is applied';
        RAISE WARNING '═══════════════════════════════════════════════════════════';
        
        -- Exit early without creating triggers
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ All prerequisite tables and types verified successfully';
    RAISE NOTICE '✅ Proceeding with trigger creation...';
END $$;

-- ============================================================================
-- NOTIFICATION TRIGGER FUNCTIONS
-- ============================================================================
-- Only execute if prerequisite validation passed

DO $$
BEGIN
    -- Check if we can proceed (all required tables exist)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'memory_contributors')
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications')
       AND EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        
        -- Function to create notification for memory invite
        CREATE OR REPLACE FUNCTION public.notify_memory_invite()
        RETURNS TRIGGER
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            memory_title TEXT;
            inviter_name TEXT;
        BEGIN
            -- Get memory and inviter details
            SELECT m.title, up.display_name
            INTO memory_title, inviter_name
            FROM public.memories m
            JOIN public.user_profiles up ON m.creator_id = up.id
            WHERE m.id = NEW.memory_id;

            -- Create notification for the invited user
            INSERT INTO public.notifications (
                user_id,
                type,
                title,
                message,
                data,
                is_read,
                created_at
            )
            VALUES (
                NEW.user_id,
                'memory_invite'::public.notification_type,
                'Memory Invitation',
                inviter_name || ' invited you to contribute to ' || memory_title,
                jsonb_build_object(
                    'memory_id', NEW.memory_id,
                    'memory_title', memory_title,
                    'inviter_id', (SELECT creator_id FROM public.memories WHERE id = NEW.memory_id),
                    'inviter_name', inviter_name
                ),
                false,
                CURRENT_TIMESTAMP
            );

            RETURN NEW;
        END;
        $func$;

        -- Function to create notification for friend request
        CREATE OR REPLACE FUNCTION public.notify_friend_request()
        RETURNS TRIGGER
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            sender_name TEXT;
        BEGIN
            IF NEW.status = 'pending'::public.friend_request_state THEN
                -- Get sender details
                SELECT display_name INTO sender_name
                FROM public.user_profiles
                WHERE id = NEW.sender_id;

                -- Create notification for receiver
                INSERT INTO public.notifications (
                    user_id,
                    type,
                    title,
                    message,
                    data,
                    is_read,
                    created_at
                )
                VALUES (
                    NEW.receiver_id,
                    'friend_request'::public.notification_type,
                    'New Friend Request',
                    sender_name || ' sent you a friend request',
                    jsonb_build_object(
                        'request_id', NEW.id,
                        'sender_id', NEW.sender_id,
                        'sender_name', sender_name
                    ),
                    false,
                    CURRENT_TIMESTAMP
                );
            END IF;

            RETURN NEW;
        END;
        $func$;

        -- Function to create notification for new story in memory
        CREATE OR REPLACE FUNCTION public.notify_new_story()
        RETURNS TRIGGER
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            memory_title TEXT;
            contributor_name TEXT;
            contributor_user_id UUID;
        BEGIN
            -- Get memory and contributor details
            SELECT m.title, up.display_name
            INTO memory_title, contributor_name
            FROM public.memories m
            JOIN public.user_profiles up ON up.id = NEW.contributor_id
            WHERE m.id = NEW.memory_id;

            -- Notify all other contributors
            FOR contributor_user_id IN
                SELECT DISTINCT mc.user_id
                FROM public.memory_contributors mc
                WHERE mc.memory_id = NEW.memory_id
                AND mc.user_id != NEW.contributor_id
            LOOP
                INSERT INTO public.notifications (
                    user_id,
                    type,
                    title,
                    message,
                    data,
                    is_read,
                    created_at
                )
                VALUES (
                    contributor_user_id,
                    'new_story'::public.notification_type,
                    'New Story Added',
                    contributor_name || ' added a new story to ' || memory_title,
                    jsonb_build_object(
                        'story_id', NEW.id,
                        'memory_id', NEW.memory_id,
                        'memory_title', memory_title,
                        'contributor_id', NEW.contributor_id,
                        'contributor_name', contributor_name
                    ),
                    false,
                    CURRENT_TIMESTAMP
                );
            END LOOP;

            RETURN NEW;
        END;
        $func$;

        -- Function to create notification for new follower
        CREATE OR REPLACE FUNCTION public.notify_new_follower()
        RETURNS TRIGGER
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            follower_name TEXT;
        BEGIN
            -- Get follower details
            SELECT display_name INTO follower_name
            FROM public.user_profiles
            WHERE id = NEW.follower_id;

            -- Create notification for the followed user
            INSERT INTO public.notifications (
                user_id,
                type,
                title,
                message,
                data,
                is_read,
                created_at
            )
            VALUES (
                NEW.following_id,
                'followed'::public.notification_type,
                'New Follower',
                follower_name || ' started following you',
                jsonb_build_object(
                    'follower_id', NEW.follower_id,
                    'follower_name', follower_name
                ),
                false,
                CURRENT_TIMESTAMP
            );

            RETURN NEW;
        END;
        $func$;

        -- Function to create notification for memory expiring soon (1 hour before)
        CREATE OR REPLACE FUNCTION public.notify_memory_expiring()
        RETURNS VOID
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            memory_record RECORD;
            contributor_user_id UUID;
        BEGIN
            -- Find memories expiring in approximately 1 hour
            FOR memory_record IN
                SELECT id, title, creator_id
                FROM public.memories
                WHERE state = 'open'::public.memory_state
                AND expires_at > CURRENT_TIMESTAMP
                AND expires_at <= CURRENT_TIMESTAMP + INTERVAL '1 hour'
                AND NOT EXISTS (
                    SELECT 1 FROM public.notifications
                    WHERE type = 'memory_expiring'::public.notification_type
                    AND (data->>'memory_id')::UUID = memories.id
                    AND created_at > CURRENT_TIMESTAMP - INTERVAL '2 hours'
                )
            LOOP
                -- Notify all contributors
                FOR contributor_user_id IN
                    SELECT DISTINCT user_id
                    FROM public.memory_contributors
                    WHERE memory_id = memory_record.id
                LOOP
                    INSERT INTO public.notifications (
                        user_id,
                        type,
                        title,
                        message,
                        data,
                        is_read,
                        created_at
                    )
                    VALUES (
                        contributor_user_id,
                        'memory_expiring'::public.notification_type,
                        'Memory Expiring Soon',
                        memory_record.title || ' will be sealed in less than 1 hour',
                        jsonb_build_object(
                            'memory_id', memory_record.id,
                            'memory_title', memory_record.title,
                            'expires_at', (SELECT expires_at FROM public.memories WHERE id = memory_record.id)
                        ),
                        false,
                        CURRENT_TIMESTAMP
                    );
                END LOOP;
            END LOOP;
        END;
        $func$;

        -- Function to create notification when memory is sealed
        CREATE OR REPLACE FUNCTION public.notify_memory_sealed()
        RETURNS TRIGGER
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            contributor_user_id UUID;
        BEGIN
            IF OLD.state = 'open'::public.memory_state AND NEW.state = 'sealed'::public.memory_state THEN
                -- Notify all contributors
                FOR contributor_user_id IN
                    SELECT DISTINCT user_id
                    FROM public.memory_contributors
                    WHERE memory_id = NEW.id
                LOOP
                    INSERT INTO public.notifications (
                        user_id,
                        type,
                        title,
                        message,
                        data,
                        is_read,
                        created_at
                    )
                    VALUES (
                        contributor_user_id,
                        'memory_sealed'::public.notification_type,
                        'Memory Sealed',
                        NEW.title || ' has been sealed and is now permanent',
                        jsonb_build_object(
                            'memory_id', NEW.id,
                            'memory_title', NEW.title,
                            'sealed_at', NEW.sealed_at
                        ),
                        false,
                        CURRENT_TIMESTAMP
                    );
                END LOOP;
            END IF;

            RETURN NEW;
        END;
        $func$;

        -- ============================================================================
        -- CREATE TRIGGERS (with DROP IF EXISTS for idempotency)
        -- ============================================================================

        -- Trigger for memory invite notifications
        DROP TRIGGER IF EXISTS notify_memory_invite_trigger ON public.memory_contributors;
        CREATE TRIGGER notify_memory_invite_trigger
            AFTER INSERT ON public.memory_contributors
            FOR EACH ROW
            EXECUTE FUNCTION public.notify_memory_invite();

        -- Trigger for friend request notifications
        DROP TRIGGER IF EXISTS notify_friend_request_trigger ON public.friend_requests;
        CREATE TRIGGER notify_friend_request_trigger
            AFTER INSERT ON public.friend_requests
            FOR EACH ROW
            EXECUTE FUNCTION public.notify_friend_request();

        -- Trigger for new story notifications
        DROP TRIGGER IF EXISTS notify_new_story_trigger ON public.stories;
        CREATE TRIGGER notify_new_story_trigger
            AFTER INSERT ON public.stories
            FOR EACH ROW
            EXECUTE FUNCTION public.notify_new_story();

        -- Trigger for new follower notifications
        DROP TRIGGER IF EXISTS notify_new_follower_trigger ON public.follows;
        CREATE TRIGGER notify_new_follower_trigger
            AFTER INSERT ON public.follows
            FOR EACH ROW
            EXECUTE FUNCTION public.notify_new_follower();

        -- Trigger for memory sealed notifications
        DROP TRIGGER IF EXISTS notify_memory_sealed_trigger ON public.memories;
        CREATE TRIGGER notify_memory_sealed_trigger
            AFTER UPDATE ON public.memories
            FOR EACH ROW
            EXECUTE FUNCTION public.notify_memory_sealed();

        RAISE NOTICE '✅ Real-time notification triggers created successfully';
        RAISE NOTICE '✅ All triggers are now active and will automatically create notifications';
        RAISE NOTICE 'ℹ️  To enable memory expiring notifications, set up pg_cron extension (see notes below)';
    ELSE
        RAISE NOTICE '⏭️  Skipping trigger creation - prerequisite tables not found';
    END IF;
END $$;

-- ============================================================================
-- SCHEDULED JOB SETUP (Optional - Requires pg_cron extension)
-- ============================================================================
-- Note: To enable memory expiring notifications, you need to:
-- 1. Enable pg_cron extension in Supabase dashboard (Database → Extensions)
-- 2. Create a scheduled job to run notify_memory_expiring() every hour
-- 
-- Run this SQL in Supabase SQL editor after enabling pg_cron:
-- SELECT cron.schedule(
--     'check-expiring-memories',
--     '0 * * * *',
--     'SELECT public.notify_memory_expiring()'
-- );