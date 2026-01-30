-- Disable unwanted in-app notifications that are created via DB triggers.
--
-- We no longer want these notification types created:
-- - group_join
-- - memory_update
--
-- (Note: "group_added" and "memory_activity" are not created by DB triggers in this schema.)

DO $$
BEGIN
  -- Group join notifications
  IF EXISTS (
    SELECT 1
    FROM information_schema.triggers
    WHERE event_object_schema = 'public'
      AND event_object_table = 'group_members'
      AND trigger_name = 'notify_group_join_trigger'
  ) THEN
    DROP TRIGGER IF EXISTS notify_group_join_trigger ON public.group_members;
  END IF;

  -- Memory update notifications
  IF EXISTS (
    SELECT 1
    FROM information_schema.triggers
    WHERE event_object_schema = 'public'
      AND event_object_table = 'memories'
      AND trigger_name = 'notify_memory_update_trigger'
  ) THEN
    DROP TRIGGER IF EXISTS notify_memory_update_trigger ON public.memories;
  END IF;

  -- Drop the trigger functions too (safe no-op if already removed).
  DROP FUNCTION IF EXISTS public.notify_group_join();
  DROP FUNCTION IF EXISTS public.notify_memory_update();
END $$;

