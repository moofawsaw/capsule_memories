-- Add 'group_added' to notification_type enum
ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS 'group_added';

-- Insert notification type config for group_added
INSERT INTO public.notification_types (type, label, icon, color, description, trigger_info, push_config, is_active)
VALUES (
  'group_added',
  'Added to Group',
  'Users',
  'bg-purple-100 text-purple-800',
  'Sent when someone adds you to a group',
  'Triggered when a user is added to a group by another member',
  jsonb_build_object(
    'title_template', 'New Group',
    'body_template', '{sender_name} added you to {group_name}',
    'deep_link_template', '/group/{group_id}',
    'image_source', 'user_avatar',
    'priority', 'normal',
    'sound', 'default',
    'show_badge', true,
    'android_channel_id', 'social'
  ),
  true
)
ON CONFLICT (type) DO UPDATE SET
  push_config = EXCLUDED.push_config,
  description = EXCLUDED.description,
  trigger_info = EXCLUDED.trigger_info;

-- Create trigger function for when a user is added to a group
CREATE OR REPLACE FUNCTION public.notify_group_added()
RETURNS TRIGGER AS $$
DECLARE
    v_group_name TEXT;
    v_group_creator_id UUID;
    v_adder_id UUID;
    v_adder_name TEXT;
    v_notification_id UUID;
    v_notification_data JSONB;
BEGIN
    -- Get group info
    SELECT name, creator_id INTO v_group_name, v_group_creator_id
    FROM public.groups
    WHERE id = NEW.group_id;

    -- The adder is either the group creator or we assume it's the creator for now
    -- In a more sophisticated system, we'd track who added whom
    v_adder_id := v_group_creator_id;

    -- Don't notify if user added themselves (creator joining their own group)
    IF NEW.user_id = v_adder_id THEN
        RETURN NEW;
    END IF;

    -- Get adder's name
    SELECT display_name INTO v_adder_name
    FROM public.user_profiles
    WHERE id = v_adder_id;

    -- Build notification data
    v_notification_data := jsonb_build_object(
        'group_id', NEW.group_id,
        'group_name', v_group_name,
        'sender_id', v_adder_id,
        'sender_name', v_adder_name,
        'actor_user_id', v_adder_id
    );

    -- Insert notification with empty title/message (edge function resolves from CMS)
    INSERT INTO public.notifications (
        user_id, type, title, message, data, is_read, created_at
    ) VALUES (
        NEW.user_id,
        'group_added'::public.notification_type,
        '',
        '',
        v_notification_data,
        false,
        CURRENT_TIMESTAMP
    ) RETURNING id INTO v_notification_id;

    -- Call edge function to resolve templates and send push
    PERFORM public.send_push_for_notification(
        v_notification_id,
        NEW.user_id,
        'group_added',
        v_notification_data
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on group_members table
DROP TRIGGER IF EXISTS trigger_notify_group_added ON public.group_members;
CREATE TRIGGER trigger_notify_group_added
    AFTER INSERT ON public.group_members
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_group_added();;
