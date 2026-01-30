-- =============================================================
-- PHASE 1: Create the shared helper function for calling the edge function
-- =============================================================

-- Enable pg_net extension if not already enabled (required for net.http_post)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Create a helper function that triggers can use to call the edge function
CREATE OR REPLACE FUNCTION public.send_push_for_notification(
  p_notification_id UUID,
  p_user_id UUID,
  p_notification_type TEXT,
  p_data JSONB
) RETURNS void AS $$
DECLARE
  supabase_url TEXT;
BEGIN
  -- Get the Supabase URL from environment or use the known URL
  supabase_url := 'https://resdvutqgrbbylknaxjp.supabase.co';
  
  -- Make async HTTP call to the edge function
  -- This is fire-and-forget - we don't wait for the response
  PERFORM net.http_post(
    url := supabase_url || '/functions/v1/send-push-notification',
    body := jsonb_build_object(
      'notification_id', p_notification_id,
      'user_id', p_user_id,
      'notificationType', p_notification_type,
      'title', '',  -- Empty - edge function resolves from CMS
      'message', '', -- Empty - edge function resolves from CMS
      'data', p_data
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json'
    )
  );
EXCEPTION
  WHEN OTHERS THEN
    -- Log warning but don't fail the transaction
    RAISE WARNING 'Failed to send push notification for %: %', p_notification_id, SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.send_push_for_notification(UUID, UUID, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_push_for_notification(UUID, UUID, TEXT, JSONB) TO service_role;

-- =============================================================
-- PHASE 2: Update notify_friend_request trigger
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_friend_request()
RETURNS TRIGGER AS $$
DECLARE
    sender_name TEXT;
    notification_id UUID;
    notification_data JSONB;
BEGIN
    IF NEW.status = 'pending'::public.friend_request_state THEN
        -- Get sender info for the data payload
        SELECT display_name INTO sender_name
        FROM public.user_profiles
        WHERE id = NEW.sender_id;

        -- Build data payload with all context needed for template resolution
        notification_data := jsonb_build_object(
            'actor_user_id', NEW.sender_id,
            'request_id', NEW.id,
            'sender_id', NEW.sender_id,
            'sender_name', COALESCE(sender_name, 'Someone'),
            'user_id', NEW.sender_id
        );

        -- Insert with EMPTY title/message - edge function resolves from CMS templates
        INSERT INTO public.notifications (
            user_id, type, title, message, data, is_read, created_at
        ) VALUES (
            NEW.receiver_id,
            'friend_request'::public.notification_type,
            '',  -- Empty - resolved by edge function from CMS
            '',  -- Empty - resolved by edge function from CMS
            notification_data,
            false,
            CURRENT_TIMESTAMP
        ) RETURNING id INTO notification_id;

        -- Call edge function to resolve templates and send push
        PERFORM public.send_push_for_notification(
            notification_id,
            NEW.receiver_id,
            'friend_request',
            notification_data
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =============================================================
-- PHASE 3: Update notify_new_follower trigger
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_new_follower()
RETURNS TRIGGER AS $$
DECLARE
    follower_name TEXT;
    notification_id UUID;
    notification_data JSONB;
BEGIN
    -- Get follower info
    SELECT display_name INTO follower_name
    FROM public.user_profiles
    WHERE id = NEW.follower_id;

    -- Build data payload
    notification_data := jsonb_build_object(
        'actor_user_id', NEW.follower_id,
        'follower_id', NEW.follower_id,
        'follower_name', COALESCE(follower_name, 'Someone'),
        'sender_name', COALESCE(follower_name, 'Someone'),
        'user_id', NEW.follower_id
    );

    -- Insert with empty title/message
    INSERT INTO public.notifications (
        user_id, type, title, message, data, is_read, created_at
    ) VALUES (
        NEW.following_id,
        'followed'::public.notification_type,
        '',
        '',
        notification_data,
        false,
        CURRENT_TIMESTAMP
    ) RETURNING id INTO notification_id;

    -- Call edge function
    PERFORM public.send_push_for_notification(
        notification_id,
        NEW.following_id,
        'followed',
        notification_data
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =============================================================
-- PHASE 4: Update notify_new_story trigger  
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_new_story()
RETURNS TRIGGER AS $$
DECLARE
    memory_title TEXT;
    contributor_name TEXT;
    contributor_user_id UUID;
    notification_id UUID;
    notification_data JSONB;
BEGIN
    -- Get memory title and contributor name
    SELECT m.title, up.display_name
    INTO memory_title, contributor_name
    FROM public.memories m
    JOIN public.user_profiles up ON up.id = NEW.contributor_id
    WHERE m.id = NEW.memory_id;

    -- Notify all other contributors in this memory
    FOR contributor_user_id IN
        SELECT DISTINCT mc.user_id
        FROM public.memory_contributors mc
        WHERE mc.memory_id = NEW.memory_id
        AND mc.user_id != NEW.contributor_id
    LOOP
        -- Build data payload
        notification_data := jsonb_build_object(
            'actor_user_id', NEW.contributor_id,
            'story_id', NEW.id,
            'memory_id', NEW.memory_id,
            'memory_title', COALESCE(memory_title, 'a memory'),
            'contributor_id', NEW.contributor_id,
            'contributor_name', COALESCE(contributor_name, 'Someone'),
            'sender_name', COALESCE(contributor_name, 'Someone'),
            'user_id', NEW.contributor_id
        );

        -- Insert with empty title/message
        INSERT INTO public.notifications (
            user_id, type, title, message, data, is_read, created_at
        ) VALUES (
            contributor_user_id,
            'new_story'::public.notification_type,
            '',
            '',
            notification_data,
            false,
            CURRENT_TIMESTAMP
        ) RETURNING id INTO notification_id;

        -- Call edge function
        PERFORM public.send_push_for_notification(
            notification_id,
            contributor_user_id,
            'new_story',
            notification_data
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =============================================================
-- PHASE 5: Update notify_memory_sealed trigger
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_memory_sealed()
RETURNS TRIGGER AS $$
DECLARE
  contributor_user_id UUID;
  current_actor_id UUID;
  notification_id UUID;
  notification_data JSONB;
BEGIN
  current_actor_id := auth.uid();
  
  -- Only notify when state changes to sealed
  IF OLD.state = 'open'::public.memory_state AND NEW.state = 'sealed'::public.memory_state THEN
    FOR contributor_user_id IN
      SELECT DISTINCT user_id
      FROM public.memory_contributors
      WHERE memory_id = NEW.id
    LOOP
      -- Skip the actor who sealed the memory
      IF current_actor_id IS NOT NULL AND contributor_user_id = current_actor_id THEN
        CONTINUE;
      END IF;
      
      -- Build data payload
      notification_data := jsonb_build_object(
        'memory_id', NEW.id,
        'memory_title', NEW.title,
        'sealed_at', NEW.sealed_at,
        'actor_user_id', current_actor_id
      );
      
      -- Insert with empty title/message
      INSERT INTO public.notifications (
        user_id, type, title, message, data, is_read, created_at
      ) VALUES (
        contributor_user_id,
        'memory_sealed'::public.notification_type,
        '',
        '',
        notification_data,
        false,
        CURRENT_TIMESTAMP
      ) RETURNING id INTO notification_id;

      -- Call edge function
      PERFORM public.send_push_for_notification(
        notification_id,
        contributor_user_id,
        'memory_sealed',
        notification_data
      );
    END LOOP;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =============================================================
-- PHASE 6: Update notify_memory_update trigger
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_memory_update()
RETURNS TRIGGER AS $$
DECLARE
  contributor_user_id UUID;
  update_type TEXT;
  current_actor_id UUID;
  notification_id UUID;
  notification_data JSONB;
BEGIN
  current_actor_id := auth.uid();
  
  -- Determine what changed
  IF OLD.title != NEW.title THEN
    update_type := 'title';
  ELSIF OLD.visibility != NEW.visibility THEN
    update_type := 'visibility';
  ELSIF OLD.location_name IS DISTINCT FROM NEW.location_name THEN
    update_type := 'location';
  ELSE
    RETURN NEW; -- No significant change
  END IF;
  
  -- Notify all contributors except the actor
  FOR contributor_user_id IN
    SELECT DISTINCT mc.user_id
    FROM public.memory_contributors mc
    WHERE mc.memory_id = NEW.id
    AND (current_actor_id IS NULL OR mc.user_id != current_actor_id)
  LOOP
    -- Build data payload
    notification_data := jsonb_build_object(
      'memory_id', NEW.id,
      'memory_title', NEW.title,
      'update_type', update_type,
      'actor_user_id', current_actor_id
    );
    
    -- Insert with empty title/message
    INSERT INTO public.notifications (
      user_id, type, title, message, data, is_read, created_at
    ) VALUES (
      contributor_user_id,
      'memory_update'::public.notification_type,
      '',
      '',
      notification_data,
      false,
      CURRENT_TIMESTAMP
    ) RETURNING id INTO notification_id;

    -- Call edge function
    PERFORM public.send_push_for_notification(
      notification_id,
      contributor_user_id,
      'memory_update',
      notification_data
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =============================================================
-- PHASE 7: Update notify_memory_expiring function
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_memory_expiring()
RETURNS void AS $$
DECLARE
    memory_record RECORD;
    contributor_user_id UUID;
    notification_id UUID;
    notification_data JSONB;
BEGIN
    -- Find memories expiring in approximately 1 hour
    FOR memory_record IN
        SELECT id, title, creator_id, expires_at
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
            -- Build data payload
            notification_data := jsonb_build_object(
                'memory_id', memory_record.id,
                'memory_title', memory_record.title,
                'expires_at', memory_record.expires_at
            );

            -- Insert with empty title/message
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
                '',
                '',
                notification_data,
                false,
                CURRENT_TIMESTAMP
            ) RETURNING id INTO notification_id;

            -- Call edge function
            PERFORM public.send_push_for_notification(
                notification_id,
                contributor_user_id,
                'memory_expiring',
                notification_data
            );
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =============================================================
-- PHASE 8: Create notify_memory_invite_created trigger (if not exists)
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_memory_invite_created()
RETURNS TRIGGER AS $$
DECLARE
    memory_title TEXT;
    inviter_name TEXT;
    notification_id UUID;
    notification_data JSONB;
BEGIN
    IF NEW.status = 'pending'::public.memory_invite_status THEN
        -- Get memory and inviter info
        SELECT m.title, up.display_name
        INTO memory_title, inviter_name
        FROM public.memories m
        JOIN public.user_profiles up ON up.id = NEW.invited_by
        WHERE m.id = NEW.memory_id;

        -- Build data payload
        notification_data := jsonb_build_object(
            'actor_user_id', NEW.invited_by,
            'invite_id', NEW.id,
            'memory_id', NEW.memory_id,
            'memory_title', COALESCE(memory_title, 'a memory'),
            'invited_by', NEW.invited_by,
            'sender_name', COALESCE(inviter_name, 'Someone'),
            'user_id', NEW.invited_by
        );

        -- Insert with empty title/message
        INSERT INTO public.notifications (
            user_id, type, title, message, data, is_read, created_at
        ) VALUES (
            NEW.user_id,
            'memory_invite'::public.notification_type,
            '',
            '',
            notification_data,
            false,
            CURRENT_TIMESTAMP
        ) RETURNING id INTO notification_id;

        -- Call edge function
        PERFORM public.send_push_for_notification(
            notification_id,
            NEW.user_id,
            'memory_invite',
            notification_data
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS on_memory_invite_created ON public.memory_invites;
CREATE TRIGGER on_memory_invite_created
    AFTER INSERT ON public.memory_invites
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_memory_invite_created();

-- =============================================================
-- PHASE 9: Create/Update notify_group_join trigger
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_group_join()
RETURNS TRIGGER AS $$
DECLARE
    group_name TEXT;
    group_creator_id UUID;
    member_name TEXT;
    notification_id UUID;
    notification_data JSONB;
BEGIN
    -- Get group info and new member name
    SELECT g.name, g.creator_id, up.display_name
    INTO group_name, group_creator_id, member_name
    FROM public.groups g
    JOIN public.user_profiles up ON up.id = NEW.user_id
    WHERE g.id = NEW.group_id;

    -- Only notify if the joiner is not the creator
    IF NEW.user_id != group_creator_id THEN
        -- Build data payload
        notification_data := jsonb_build_object(
            'actor_user_id', NEW.user_id,
            'group_id', NEW.group_id,
            'group_name', COALESCE(group_name, 'a group'),
            'member_id', NEW.user_id,
            'member_name', COALESCE(member_name, 'Someone'),
            'sender_name', COALESCE(member_name, 'Someone'),
            'user_id', NEW.user_id
        );

        -- Notify the group creator
        INSERT INTO public.notifications (
            user_id, type, title, message, data, is_read, created_at
        ) VALUES (
            group_creator_id,
            'group_join'::public.notification_type,
            '',
            '',
            notification_data,
            false,
            CURRENT_TIMESTAMP
        ) RETURNING id INTO notification_id;

        -- Call edge function
        PERFORM public.send_push_for_notification(
            notification_id,
            group_creator_id,
            'group_join',
            notification_data
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS on_group_member_join ON public.group_members;
CREATE TRIGGER on_group_member_join
    AFTER INSERT ON public.group_members
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_group_join();

-- =============================================================
-- PHASE 10: Create notify_friend_accepted function  
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_friend_accepted()
RETURNS TRIGGER AS $$
DECLARE
    accepter_name TEXT;
    notification_id UUID;
    notification_data JSONB;
BEGIN
    -- Only trigger when status changes from pending to accepted
    IF OLD.status = 'pending'::public.friend_request_state 
       AND NEW.status = 'accepted'::public.friend_request_state THEN
        
        -- Get the accepter's name (receiver who accepted)
        SELECT display_name INTO accepter_name
        FROM public.user_profiles
        WHERE id = NEW.receiver_id;

        -- Build data payload
        notification_data := jsonb_build_object(
            'actor_user_id', NEW.receiver_id,
            'request_id', NEW.id,
            'friend_id', NEW.receiver_id,
            'sender_name', COALESCE(accepter_name, 'Someone'),
            'user_id', NEW.receiver_id
        );

        -- Notify the original sender that their request was accepted
        INSERT INTO public.notifications (
            user_id, type, title, message, data, is_read, created_at
        ) VALUES (
            NEW.sender_id,
            'friend_accepted'::public.notification_type,
            '',
            '',
            notification_data,
            false,
            CURRENT_TIMESTAMP
        ) RETURNING id INTO notification_id;

        -- Call edge function
        PERFORM public.send_push_for_notification(
            notification_id,
            NEW.sender_id,
            'friend_accepted',
            notification_data
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger for friend acceptance
DROP TRIGGER IF EXISTS on_friend_request_accepted ON public.friend_requests;
CREATE TRIGGER on_friend_request_accepted
    AFTER UPDATE ON public.friend_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_friend_accepted();

-- =============================================================
-- PHASE 11: Fill missing CMS templates in notification_types
-- =============================================================

-- Update memory_sealed to have a proper body template
UPDATE public.notification_types
SET push_config = jsonb_set(
    COALESCE(push_config, '{}'::jsonb),
    '{body_template}',
    '"{memory_title} has been sealed and is now a permanent memory"'::jsonb
)
WHERE type = 'memory_sealed';

-- Update memory_expiring to have a proper body template
UPDATE public.notification_types
SET push_config = jsonb_set(
    COALESCE(push_config, '{}'::jsonb),
    '{body_template}',
    '"Add your final moments before it seals forever"'::jsonb
)
WHERE type = 'memory_expiring';

-- Update daily_capsule_reminder with templates if missing
UPDATE public.notification_types
SET push_config = jsonb_set(
    jsonb_set(
        COALESCE(push_config, '{}'::jsonb),
        '{title_template}',
        '"Time for your Daily Capsule!"'::jsonb
    ),
    '{body_template}',
    '"Capture today''s moment before midnight"'::jsonb
)
WHERE type = 'daily_capsule_reminder'
AND (push_config IS NULL OR push_config->>'title_template' IS NULL);;
