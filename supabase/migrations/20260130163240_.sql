-- Create email use case settings table
CREATE TABLE public.email_use_case_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email_type TEXT UNIQUE NOT NULL,
  enabled BOOLEAN DEFAULT true NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE public.email_use_case_settings ENABLE ROW LEVEL SECURITY;

-- Admins can manage email settings
CREATE POLICY "Admins can manage email settings"
ON public.email_use_case_settings
FOR ALL
USING (has_role(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role(auth.uid(), 'admin'::app_role));

-- Create trigger for updated_at
CREATE TRIGGER set_email_use_case_settings_updated_at
  BEFORE UPDATE ON public.email_use_case_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Seed with all email types (enabled by default)
INSERT INTO public.email_use_case_settings (email_type, name, description, category) VALUES
  ('welcome', 'Welcome Email', 'Sent when a new user signs up', 'account'),
  ('password_reset', 'Password Reset', 'Sent when admin triggers a password reset', 'account'),
  ('account_banned', 'Account Suspended', 'Sent when a user account is banned', 'account'),
  ('ticket_created', 'Ticket Created', 'Confirmation when user submits contact form', 'support'),
  ('ticket_reply', 'Ticket Reply', 'When admin replies to a support ticket', 'support'),
  ('ticket_closed', 'Ticket Closed', 'When admin closes a support ticket', 'support'),
  ('general_reply', 'General Reply', 'When admin replies to general inbox emails', 'inbox'),
  ('report_confirmation', 'Report Confirmation', 'Sent when user submits a report', 'moderation'),
  ('report_update', 'Report Update', 'Sent when admin resolves a report', 'moderation'),
  ('promotional', 'Promotional Emails', 'Admin-sent marketing campaigns', 'marketing');;
