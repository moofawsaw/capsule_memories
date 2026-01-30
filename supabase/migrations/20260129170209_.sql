-- =============================================================
-- FIX: Update notify_friend_new_story to use new pattern
-- This trigger notifies friends when someone posts a story to a public memory
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_friend_new_story()
RETURNS TRIGGER AS $$
DECLARE
  memory_visibility TEXT;
  memory_title TEXT;
  poster_name TEXT;
  notification_config RECORD;
  cooldown_hours INT;
  max_per_day INT;
  friend_record RECORD;
  recent_count INT;
  is_memory_contributor BOOLEAN;
  notification_id UUID;
  notification_data JSONB;
  last_notification TIMESTAMPTZ;
BEGIN
  -- Only for public memories
  SELECT m.visibility, m.title INTO memory_visibility, memory_title 
  FROM memories m WHERE m.id = NEW.memory_id;
  
  IF memory_visibility != 'public' THEN
    RETURN NEW;
  END IF;

  -- Check if this notification type is active and get config
  SELECT is_active, scheduling_config INTO notification_config
  FROM notification_types WHERE type = 'friend_new_story';
  
  IF notification_config IS NULL OR notification_config.is_active = false THEN
    RETURN NEW;
  END IF;
  
  -- Get scheduling config values
  cooldown_hours := COALESCE((notification_config.scheduling_config->>'cooldown_hours')::INT, 1);
  max_per_day := COALESCE((notification_config.scheduling_config->>'max_per_day_per_user')::INT, 10);
  
  -- Get poster name
  SELECT display_name INTO poster_name 
  FROM user_profiles WHERE id = NEW.contributor_id;
  
  -- Notify all friends of the poster
  FOR friend_record IN 
    SELECT f.friend_id as user_id
    FROM friends f
    WHERE f.user_id = NEW.contributor_id
    UNION
    SELECT f.user_id as user_id
    FROM friends f
    WHERE f.friend_id = NEW.contributor_id
  LOOP
    -- SKIP if this is the actor themselves
    IF friend_record.user_id = NEW.contributor_id THEN
      CONTINUE;
    END IF;
    
    -- Skip if this friend is already a contributor to this memory
    SELECT EXISTS (
      SELECT 1 FROM memory_contributors 
      WHERE memory_id = NEW.memory_id AND user_id = friend_record.user_id
    ) INTO is_memory_contributor;
    
    IF is_memory_contributor THEN
      CONTINUE; -- They'll get a new_story notification instead
    END IF;
    
    -- Check cooldown
    SELECT created_at INTO last_notification
    FROM notifications
    WHERE user_id = friend_record.user_id
      AND type = 'friend_new_story'
    ORDER BY created_at DESC
    LIMIT 1;

    IF last_notification IS NOT NULL AND last_notification > NOW() - (cooldown_hours || ' hours')::INTERVAL THEN
      CONTINUE;
    END IF;
    
    -- Check daily limit
    SELECT COUNT(*) INTO recent_count
    FROM notifications
    WHERE user_id = friend_record.user_id
      AND type = 'friend_new_story'
      AND created_at > NOW() - INTERVAL '24 hours';
    
    IF recent_count >= max_per_day THEN
      CONTINUE;
    END IF;
    
    -- Build data payload with all context for template resolution
    notification_data := jsonb_build_object(
      'actor_user_id', NEW.contributor_id,
      'story_id', NEW.id,
      'memory_id', NEW.memory_id,
      'memory_title', COALESCE(memory_title, 'a memory'),
      'contributor_id', NEW.contributor_id,
      'sender_name', COALESCE(poster_name, 'Someone'),
      'user_id', NEW.contributor_id,
      'location_name', NEW.location_name
    );
    
    -- Insert with EMPTY title/message - edge function resolves from CMS
    INSERT INTO notifications (user_id, type, title, message, data, is_read, created_at)
    VALUES (
      friend_record.user_id,
      'friend_new_story'::notification_type,
      '',  -- Empty - resolved by edge function
      '',  -- Empty - resolved by edge function
      notification_data,
      false,
      CURRENT_TIMESTAMP
    ) RETURNING id INTO notification_id;
    
    -- Call edge function to resolve templates and send push
    PERFORM public.send_push_for_notification(
      notification_id,
      friend_record.user_id,
      'friend_new_story',
      notification_data
    );
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- =============================================================
-- FIX: Update notify_friend_new_memory to use new pattern
-- =============================================================

CREATE OR REPLACE FUNCTION public.notify_friend_new_memory()
RETURNS TRIGGER AS $$
DECLARE
  creator_record RECORD;
  friend_record RECORD;
  notification_config RECORD;
  cooldown_hours INT;
  max_per_day INT;
  recent_count INT;
  last_notification TIMESTAMPTZ;
  notification_id UUID;
  notification_data JSONB;
BEGIN
  -- Only notify for public memories
  IF NEW.visibility != 'public' THEN
    RETURN NEW;
  END IF;

  -- Get notification config
  SELECT * INTO notification_config
  FROM notification_types
  WHERE type = 'friend_new_memory' AND is_active = true;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  -- Get scheduling config
  cooldown_hours := COALESCE((notification_config.scheduling_config->>'cooldown_hours')::INT, 2);
  max_per_day := COALESCE((notification_config.scheduling_config->>'max_per_day_per_user')::INT, 5);

  -- Get creator info
  SELECT id, display_name, avatar_url INTO creator_record
  FROM user_profiles
  WHERE id = NEW.creator_id;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  -- Loop through all friends of the creator
  FOR friend_record IN
    SELECT f.friend_id as user_id
    FROM friends f
    WHERE f.user_id = NEW.creator_id
    UNION
    SELECT f.user_id as user_id
    FROM friends f
    WHERE f.friend_id = NEW.creator_id
  LOOP
    -- SKIP if this is the actor themselves
    IF friend_record.user_id = NEW.creator_id THEN
      CONTINUE;
    END IF;
    
    -- Check cooldown
    SELECT created_at INTO last_notification
    FROM notifications
    WHERE user_id = friend_record.user_id
      AND type = 'friend_new_memory'
    ORDER BY created_at DESC
    LIMIT 1;

    IF last_notification IS NOT NULL AND last_notification > NOW() - (cooldown_hours || ' hours')::INTERVAL THEN
      CONTINUE;
    END IF;

    -- Check daily limit
    SELECT COUNT(*) INTO recent_count
    FROM notifications
    WHERE user_id = friend_record.user_id
      AND type = 'friend_new_memory'
      AND created_at > NOW() - INTERVAL '24 hours';

    IF recent_count >= max_per_day THEN
      CONTINUE;
    END IF;

    -- Build data payload
    notification_data := jsonb_build_object(
      'actor_user_id', NEW.creator_id,
      'memory_id', NEW.id,
      'memory_title', NEW.title,
      'sender_name', COALESCE(creator_record.display_name, 'Someone'),
      'sender_avatar', creator_record.avatar_url,
      'location_name', NEW.location_name,
      'user_id', NEW.creator_id
    );

    -- Insert with EMPTY title/message
    INSERT INTO notifications (user_id, type, title, message, data, is_read, created_at)
    VALUES (
      friend_record.user_id,
      'friend_new_memory'::notification_type,
      '',  -- Empty - resolved by edge function
      '',  -- Empty - resolved by edge function
      notification_data,
      false,
      CURRENT_TIMESTAMP
    ) RETURNING id INTO notification_id;

    -- Call edge function
    PERFORM public.send_push_for_notification(
      notification_id,
      friend_record.user_id,
      'friend_new_memory',
      notification_data
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;;
