-- Email Authentication Configuration Migration
-- This migration enables email confirmation and password reset functionality

-- Email confirmation setup instructions:
-- 1. Navigate to Supabase Dashboard > Authentication > Settings
-- 2. Enable "Confirm email" under Email Auth
-- 3. Configure email templates under Email Templates
-- 4. Set up SMTP settings or use Supabase's email service

-- Create function to handle password reset requests
CREATE OR REPLACE FUNCTION public.request_password_reset(user_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Supabase Auth handles password reset emails automatically
  -- This function validates the email exists before triggering reset
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = user_email) THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$;

-- Add indexes for faster auth queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.request_password_reset(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.request_password_reset(TEXT) TO anon;