INSERT INTO notification_types (type, label, icon, color, description, is_active, trigger_info, requires_manual_trigger)
VALUES (
  'daily_capsule_reminder',
  'Daily Capsule Reminder',
  'Sun',
  'text-yellow-500',
  'Scheduled reminder for users to log their daily mood/moment',
  true,
  'Triggered by scheduled edge function based on user daily_capsule_settings.reminder_hour',
  false
);;
