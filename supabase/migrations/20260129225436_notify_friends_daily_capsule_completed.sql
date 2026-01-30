-- Friend Daily Capsule Completed notifications (push + in-app)

-- 1) Add new notification type enum value
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'notification_type'
      AND e.enumlabel = 'friend_daily_capsule_completed'
  ) THEN
    ALTER TYPE public.notification_type ADD VALUE 'friend_daily_capsule_completed';
  END IF;
END
$$;

-- 2) Ensure notification_types config exists for template resolution + deep link
INSERT INTO public.notification_types (
  type,
  label,
  icon,
  color,
  description,
  is_active,
  push_config,
  trigger_info,
  scheduling_config,
  targeting_config,
  requires_manual_trigger
)
VALUES (
  'friend_daily_capsule_completed',
  'Friend Daily Capsule',
  'Sun',
  'text-yellow-500',
  'Sent when a friend completes their Daily Capsule',
  TRUE,
  jsonb_build_object(
    'sound', 'default',
    'priority', 'normal',
    'show_badge', true,
    'image_source', 'user_avatar',
    'android_channel_id', 'social',
    'title_template', '{sender_name} completed their Daily Capsule',
    'body_template', 'Tap to open your Daily Capsule',
    'deep_link_template', '/app/daily-capsule'
  ),
  'Trigger: daily_capsule_entries INSERT/UPDATE when completed_at transitions from NULL -> NOT NULL. Recipient: all friends of the user. Sender context: daily_capsule_entries.user_id. Skips: self.',
  jsonb_build_object('enabled', true, 'cooldown_hours', 6, 'max_per_day_per_user', 2),
  '{}'::jsonb,
  FALSE
)
ON CONFLICT (type) DO UPDATE SET
  label = EXCLUDED.label,
  icon = EXCLUDED.icon,
  color = EXCLUDED.color,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active,
  push_config = EXCLUDED.push_config,
  trigger_info = EXCLUDED.trigger_info,
  scheduling_config = EXCLUDED.scheduling_config,
  targeting_config = EXCLUDED.targeting_config,
  requires_manual_trigger = EXCLUDED.requires_manual_trigger;

-- 3) Trigger function
CREATE OR REPLACE FUNCTION public.notify_friend_daily_capsule_completed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  notification_config RECORD;
  actor_name TEXT;
  friend_record RECORD;
  notification_id UUID;
  notification_data JSONB;
BEGIN
  -- Only send on first completion for that local_date (transition NULL -> NOT NULL)
  IF NEW.completed_at IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.completed_at IS NOT NULL THEN
    RETURN NEW;
  END IF;

  -- Check if this notification type is active
  SELECT is_active INTO notification_config
  FROM public.notification_types
  WHERE type = 'friend_daily_capsule_completed'
  LIMIT 1;

  IF notification_config IS NULL OR notification_config.is_active = FALSE THEN
    RETURN NEW;
  END IF;

  -- Actor name
  SELECT COALESCE(up.display_name, up.username, 'Someone')
  INTO actor_name
  FROM public.user_profiles up
  WHERE up.id = NEW.user_id;

  -- Notify all friends (both directions)
  FOR friend_record IN
    SELECT f.friend_id AS user_id
    FROM public.friends f
    WHERE f.user_id = NEW.user_id
    UNION
    SELECT f.user_id AS user_id
    FROM public.friends f
    WHERE f.friend_id = NEW.user_id
  LOOP
    -- Skip self
    IF friend_record.user_id = NEW.user_id THEN
      CONTINUE;
    END IF;

    notification_data := jsonb_build_object(
      'actor_user_id', NEW.user_id,
      'sender_name', actor_name,
      'user_id', NEW.user_id,
      'local_date', NEW.local_date,
      'completion_type', NEW.completion_type,
      'deep_link', '/app/daily-capsule'
    );

    -- Insert with EMPTY title/message - edge function resolves from notification_types.push_config
    INSERT INTO public.notifications (user_id, type, title, message, data, is_read, created_at)
    VALUES (
      friend_record.user_id,
      'friend_daily_capsule_completed'::public.notification_type,
      '',
      '',
      notification_data,
      FALSE,
      CURRENT_TIMESTAMP
    )
    RETURNING id INTO notification_id;

    -- Send push and allow edge function to enrich notification row
    PERFORM public.send_push_for_notification(
      notification_id,
      friend_record.user_id,
      'friend_daily_capsule_completed',
      notification_data
    );
  END LOOP;

  RETURN NEW;
END;
$$;

-- 4) Trigger on daily_capsule_entries
DROP TRIGGER IF EXISTS notify_friend_daily_capsule_completed_trigger ON public.daily_capsule_entries;
CREATE TRIGGER notify_friend_daily_capsule_completed_trigger
AFTER INSERT OR UPDATE OF completed_at ON public.daily_capsule_entries
FOR EACH ROW
EXECUTE FUNCTION public.notify_friend_daily_capsule_completed();
;
