-- Add added_by column to track who added the member
ALTER TABLE public.group_members 
ADD COLUMN IF NOT EXISTS added_by UUID REFERENCES public.user_profiles(id);

-- Update existing records to set added_by = user_id (self-joined)
UPDATE public.group_members 
SET added_by = user_id 
WHERE added_by IS NULL;

-- Update the trigger function to check added_by for self-joins
CREATE OR REPLACE FUNCTION public.notify_group_added()
RETURNS TRIGGER AS $$
DECLARE
    v_group_name TEXT;
    v_adder_id UUID;
    v_adder_name TEXT;
    v_notification_id UUID;
    v_notification_data JSONB;
BEGIN
    -- If added_by is not set or equals user_id, this is a self-join (QR scan) - skip notification
    IF NEW.added_by IS NULL OR NEW.added_by = NEW.user_id THEN
        RETURN NEW;
    END IF;

    -- Get group info
    SELECT name INTO v_group_name
    FROM public.groups
    WHERE id = NEW.group_id;

    -- The adder is the person who added this member
    v_adder_id := NEW.added_by;

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
$$ LANGUAGE plpgsql SECURITY DEFINER;;
