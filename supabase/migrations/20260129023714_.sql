-- Drop the duplicate push notification trigger
-- This trigger was sending plain-text pushes whenever a notification row was inserted,
-- duplicating the explicit edge function calls that handle rich notifications with images/templates

DROP TRIGGER IF EXISTS on_notification_insert_send_push ON public.notifications;
DROP FUNCTION IF EXISTS public.send_push_notification_on_insert();;
