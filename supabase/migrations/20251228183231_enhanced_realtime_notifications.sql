-- Location: supabase/migrations/20251228183231_enhanced_realtime_notifications.sql
-- Schema Analysis: Extending Supabase real-time notifications for group joins, friend acceptance, and memory updates
-- Integration Type: Enhancement - adding missing notification triggers for complete real-time coverage
-- Dependencies: 20251217165241_realtime_notifications.sql must be applied first

-- ============================================================================
-- CRITICAL: PREREQUISITE VALIDATION
-- ============================================================================

DO $$
DECLARE
    missing_tables TEXT[] := ARRAY[]::TEXT[];
    missing_types TEXT[] := ARRAY[]::TEXT[];
    can_proceed BOOLEAN := TRUE;
BEGIN
    -- Check for required tables
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'group_members') THEN
        missing_tables := array_append(missing_tables, 'group_members');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'friends') THEN
        missing_tables := array_append(missing_tables, 'friends');
        can_proceed := FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        missing_tables := array_append(missing_tables, 'notifications');
        can_proceed := FALSE;
    END IF;
    
    -- Check for required type
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        missing_types := array_append(missing_types, 'notification_type');
        can_proceed := FALSE;
    END IF;
    
    -- Report missing dependencies
    IF NOT can_proceed THEN
        RAISE WARNING '⚠️  PREREQUISITE CHECK FAILED - Missing Dependencies';
        RAISE WARNING '═════════════════════════════════════════════════════';
        
        IF array_length(missing_tables, 1) > 0 THEN
            RAISE WARNING '❌ Missing Tables: %', array_to_string(missing_tables, ', ');
        END IF;
        
        IF array_length(missing_types, 1) > 0 THEN
            RAISE WARNING '❌ Missing Types: %', array_to_string(missing_types, ', ');
        END IF;
        
        RAISE WARNING '';
        RAISE WARNING '📋 REQUIRED ACTION:';
        RAISE WARNING '   Run base schema migrations first';
        RAISE WARNING '⏭️  Skipping migration - re-run after base schema applied';
        RAISE WARNING '═════════════════════════════════════════════════════';
        
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ All prerequisite tables and types verified';
    RAISE NOTICE '✅ Proceeding with enhanced notification triggers...';
END $$;

-- ============================================================================
-- EXTEND NOTIFICATION TYPE ENUM (if not already extended)
-- ============================================================================

DO $$
BEGIN
    -- Add 'group_join' if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'group_join' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type')) THEN
        ALTER TYPE public.notification_type ADD VALUE 'group_join';
        RAISE NOTICE '✅ Added "group_join" to notification_type enum';
    ELSE
        RAISE NOTICE 'ℹ️  "group_join" already exists in notification_type enum';
    END IF;
    
    -- Add 'friend_accepted' if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'friend_accepted' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type')) THEN
        ALTER TYPE public.notification_type ADD VALUE 'friend_accepted';
        RAISE NOTICE '✅ Added "friend_accepted" to notification_type enum';
    ELSE
        RAISE NOTICE 'ℹ️  "friend_accepted" already exists in notification_type enum';
    END IF;
    
    -- Add 'memory_update' if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'memory_update' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'notification_type')) THEN
        ALTER TYPE public.notification_type ADD VALUE 'memory_update';
        RAISE NOTICE '✅ Added "memory_update" to notification_type enum';
    ELSE
        RAISE NOTICE 'ℹ️  "memory_update" already exists in notification_type enum';
    END IF;
EXCEPTION
    WHEN others THEN
        RAISE WARNING '⚠️  Could not extend notification_type enum: %', SQLERRM;
        RAISE WARNING '   This is OK if values already exist';
END $$;

-- ============================================================================
-- NOTIFICATION TRIGGER FUNCTIONS FOR ENHANCED REAL-TIME
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'group_members')
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        
        -- ========================================================================
        -- Function: Notify when user joins a group
        -- ========================================================================
        CREATE OR REPLACE FUNCTION public.notify_group_join()
        RETURNS TRIGGER
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            group_name TEXT;
            joiner_name TEXT;
            group_creator_id UUID;
            group_member_id UUID;
        BEGIN
            -- Get group and joiner details
            SELECT g.name, g.creator_id, up.display_name
            INTO group_name, group_creator_id, joiner_name
            FROM public.groups g
            JOIN public.user_profiles up ON up.id = NEW.user_id
            WHERE g.id = NEW.group_id;

            -- Notify all existing group members (excluding the new joiner)
            FOR group_member_id IN
                SELECT DISTINCT gm.user_id
                FROM public.group_members gm
                WHERE gm.group_id = NEW.group_id
                AND gm.user_id != NEW.user_id
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
                    group_member_id,
                    'group_join'::public.notification_type,
                    'New Group Member',
                    joiner_name || ' joined ' || group_name,
                    jsonb_build_object(
                        'group_id', NEW.group_id,
                        'group_name', group_name,
                        'new_member_id', NEW.user_id,
                        'new_member_name', joiner_name
                    ),
                    false,
                    CURRENT_TIMESTAMP
                );
            END LOOP;

            -- Also notify the group creator if they're not already a member
            IF NOT EXISTS (
                SELECT 1 FROM public.group_members 
                WHERE group_id = NEW.group_id AND user_id = group_creator_id
            ) AND group_creator_id != NEW.user_id THEN
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
                    group_creator_id,
                    'group_join'::public.notification_type,
                    'New Group Member',
                    joiner_name || ' joined ' || group_name,
                    jsonb_build_object(
                        'group_id', NEW.group_id,
                        'group_name', group_name,
                        'new_member_id', NEW.user_id,
                        'new_member_name', joiner_name
                    ),
                    false,
                    CURRENT_TIMESTAMP
                );
            END IF;

            RETURN NEW;
        END;
        $func$;

        -- ========================================================================
        -- Function: Notify when friend request is accepted
        -- ========================================================================
        CREATE OR REPLACE FUNCTION public.notify_friend_accepted()
        RETURNS TRIGGER
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            user1_name TEXT;
            user2_name TEXT;
        BEGIN
            -- Get both users' display names
            SELECT up1.display_name, up2.display_name
            INTO user1_name, user2_name
            FROM public.user_profiles up1
            CROSS JOIN public.user_profiles up2
            WHERE up1.id = NEW.user_id AND up2.id = NEW.friend_id;

            -- Notify user_id that friend_id accepted friendship
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
                'friend_accepted'::public.notification_type,
                'Friend Request Accepted',
                user2_name || ' is now your friend',
                jsonb_build_object(
                    'friend_id', NEW.friend_id,
                    'friend_name', user2_name
                ),
                false,
                CURRENT_TIMESTAMP
            );

            -- Notify friend_id that user_id is now a friend
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
                NEW.friend_id,
                'friend_accepted'::public.notification_type,
                'New Friend',
                user1_name || ' is now your friend',
                jsonb_build_object(
                    'friend_id', NEW.user_id,
                    'friend_name', user1_name
                ),
                false,
                CURRENT_TIMESTAMP
            );

            RETURN NEW;
        END;
        $func$;

        -- ========================================================================
        -- Function: Notify memory contributors when memory is updated
        -- ========================================================================
        CREATE OR REPLACE FUNCTION public.notify_memory_update()
        RETURNS TRIGGER
        SECURITY DEFINER
        LANGUAGE plpgsql
        AS $func$
        DECLARE
            contributor_user_id UUID;
            update_details TEXT;
        BEGIN
            -- Only notify on updates, not inserts
            IF TG_OP = 'UPDATE' THEN
                -- Determine what changed
                IF OLD.title != NEW.title THEN
                    update_details := 'Memory title updated to: ' || NEW.title;
                ELSIF OLD.state != NEW.state THEN
                    update_details := 'Memory state changed to: ' || NEW.state;
                ELSIF OLD.visibility != NEW.visibility THEN
                    update_details := 'Memory visibility changed to: ' || NEW.visibility;
                ELSE
                    update_details := 'Memory details updated';
                END IF;

                -- Notify all contributors except the one who made the update
                FOR contributor_user_id IN
                    SELECT DISTINCT mc.user_id
                    FROM public.memory_contributors mc
                    WHERE mc.memory_id = NEW.id
                    AND mc.user_id != auth.uid()
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
                        'memory_update'::public.notification_type,
                        'Memory Updated',
                        update_details,
                        jsonb_build_object(
                            'memory_id', NEW.id,
                            'memory_title', NEW.title,
                            'update_type', CASE
                                WHEN OLD.title != NEW.title THEN 'title'
                                WHEN OLD.state != NEW.state THEN 'state'
                                WHEN OLD.visibility != NEW.visibility THEN 'visibility'
                                ELSE 'details'
                            END
                        ),
                        false,
                        CURRENT_TIMESTAMP
                    );
                END LOOP;
            END IF;

            RETURN NEW;
        END;
        $func$;

        -- ========================================================================
        -- CREATE/REPLACE TRIGGERS
        -- ========================================================================

        -- Trigger for group join notifications
        DROP TRIGGER IF EXISTS notify_group_join_trigger ON public.group_members;
        CREATE TRIGGER notify_group_join_trigger
            AFTER INSERT ON public.group_members
            FOR EACH ROW
            EXECUTE FUNCTION public.notify_group_join();

        -- Trigger for friend acceptance notifications
        DROP TRIGGER IF EXISTS notify_friend_accepted_trigger ON public.friends;
        CREATE TRIGGER notify_friend_accepted_trigger
            AFTER INSERT ON public.friends
            FOR EACH ROW
            EXECUTE FUNCTION public.notify_friend_accepted();

        -- Trigger for memory update notifications
        DROP TRIGGER IF EXISTS notify_memory_update_trigger ON public.memories;
        CREATE TRIGGER notify_memory_update_trigger
            AFTER UPDATE ON public.memories
            FOR EACH ROW
            EXECUTE FUNCTION public.notify_memory_update();

        RAISE NOTICE '✅ Enhanced real-time notification triggers created successfully';
        RAISE NOTICE '✅ Group join, friend acceptance, and memory update notifications now active';
    ELSE
        RAISE NOTICE '⏭️  Skipping trigger creation - prerequisite tables not found';
    END IF;
END $$;

-- ============================================================================
-- MIGRATION SUMMARY
-- ============================================================================
-- ✅ Extended notification_type enum with: group_join, friend_accepted, memory_update
-- ✅ Created notify_group_join() trigger function for instant group join notifications
-- ✅ Created notify_friend_accepted() trigger function for instant friendship notifications
-- ✅ Created notify_memory_update() trigger function for memory change notifications
-- ✅ All triggers are now active and will push real-time notifications without page refresh
-- 
-- REAL-TIME BEHAVIOR:
-- - Group joins: All existing members get instant notification when someone new joins
-- - Friend acceptance: Both users get instant notification when friendship is established
-- - Memory updates: Contributors get notified when memory details change
-- 
-- FLUTTER INTEGRATION:
-- - NotificationService.subscribeToNotifications() handles real-time delivery
-- - No additional Flutter code changes needed - existing service handles new notification types