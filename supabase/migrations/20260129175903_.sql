-- Fix notify_group_added trigger to use 'sender_name' (matching template) instead of 'added_by_name'
-- Also ensure group_id is passed correctly for deep link resolution

CREATE OR REPLACE FUNCTION public.notify_group_added()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group_name TEXT;
  v_adder_id UUID;
  v_adder_name TEXT;
  v_notification_id UUID;
BEGIN
  -- Get group name
  SELECT name INTO v_group_name
  FROM groups
  WHERE id = NEW.group_id;

  -- Determine who added this member
  -- If added_by is NULL, use the group creator as the adder
  IF NEW.added_by IS NOT NULL THEN
    v_adder_id := NEW.added_by;
  ELSE
    SELECT creator_id INTO v_adder_id
    FROM groups
    WHERE id = NEW.group_id;
  END IF;

  -- Don't notify if user added themselves (self-join via invite code)
  IF v_adder_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Get adder's display name
  SELECT display_name INTO v_adder_name
  FROM user_profiles
  WHERE id = v_adder_id;

  -- Generate notification ID
  v_notification_id := gen_random_uuid();

  -- Insert notification with empty title/message (edge function resolves templates)
  -- Use 'sender_name' and 'sender_id' to match template variables
  INSERT INTO notifications (id, user_id, type, title, message, data)
  VALUES (
    v_notification_id,
    NEW.user_id,
    'group_added',
    '',
    '',
    jsonb_build_object(
      'group_id', NEW.group_id,
      'group_name', COALESCE(v_group_name, 'a group'),
      'sender_id', v_adder_id,
      'sender_name', COALESCE(v_adder_name, 'Someone')
    )
  );

  -- Trigger push notification via edge function
  PERFORM send_push_for_notification(
    v_notification_id,
    NEW.user_id,
    'group_added',
    jsonb_build_object(
      'group_id', NEW.group_id,
      'group_name', COALESCE(v_group_name, 'a group'),
      'sender_id', v_adder_id,
      'sender_name', COALESCE(v_adder_name, 'Someone')
    )
  );

  RETURN NEW;
END;
$$;;
