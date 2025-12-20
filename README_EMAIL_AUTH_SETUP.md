# Email Authentication Setup Guide

## ✅ What's Already Implemented

Your Capsule Memories app has a **complete email authentication system** with:

### 1. **Sign Up Functionality**
- Email/password registration with Supabase Auth
- Google OAuth sign up (requires dashboard configuration)
- Facebook OAuth sign up (requires dashboard configuration)
- Form validation (email format, password strength, password confirmation)
- Automatic user profile creation via `handle_new_user` trigger
- Error handling with user-friendly messages

### 2. **Login Functionality**
- Email/password login with Supabase Auth
- Google OAuth login (requires dashboard configuration)
- Facebook OAuth login (requires dashboard configuration)
- Form validation
- Session persistence
- Error handling for invalid credentials and unverified emails

### 3. **Password Reset**
- Forgot password link on login screen
- Email-based password reset flow
- Reset link generation via Supabase Auth
- User-friendly error messages and success notifications

### 4. **Email Verification Support**
- Error handling for unverified email addresses
- Ready for email confirmation flow (requires Supabase dashboard configuration)

## 🔧 Required Configuration in Supabase Dashboard

To **enable email verification and complete the authentication flow**, follow these steps:

### Step 1: Enable Email Confirmations

1. Go to your Supabase Dashboard
2. Navigate to **Authentication > Settings**
3. Under **Email Auth**, enable **"Confirm email"**
4. Save changes

### Step 2: Configure Email Templates

1. In the same Settings page, go to **Email Templates**
2. Customize the following templates:
   - **Confirm signup**: Sent when users register
   - **Reset password**: Sent when users request password reset
   - **Magic Link**: (Optional) For passwordless login

### Step 3: Set Up Email Service

**Option A: Use Supabase's Built-in Email Service (Recommended for Development)**
- No additional configuration needed
- Supabase handles email delivery automatically
- Limited to development/testing (rate limits apply)

**Option B: Configure Custom SMTP (Recommended for Production)**
1. Go to **Authentication > Settings > SMTP Settings**
2. Enter your SMTP credentials:
   - SMTP Host (e.g., smtp.gmail.com)
   - SMTP Port (e.g., 587)
   - SMTP Username (your email)
   - SMTP Password (app password or SMTP password)
   - Sender Email
   - Sender Name

**Popular SMTP Services:**
- **Gmail**: Use App Passwords (not your regular password)
- **SendGrid**: Free tier available, reliable delivery
- **Mailgun**: Good for transactional emails
- **AWS SES**: Cost-effective for high volume

### Step 4: Configure Redirect URLs

1. Go to **Authentication > URL Configuration**
2. Add the following redirect URLs:
   - `io.supabase.capsulememories://login-callback/` (for OAuth)
   - `io.supabase.capsulememories://reset-password/` (for password reset)

3. For web deployment, also add:
   - `https://yourdomain.com/auth/callback`
   - `https://yourdomain.com/reset-password`

### Step 5: (Optional) Configure OAuth Providers

**For Google OAuth:**
1. Go to **Authentication > Providers**
2. Enable **Google**
3. Add your Google OAuth credentials:
   - Client ID (from Google Cloud Console)
   - Client Secret (from Google Cloud Console)
4. Add redirect URL: `https://your-project.supabase.co/auth/v1/callback`

**For Facebook OAuth:**
1. Enable **Facebook** in Providers
2. Add Facebook App credentials:
   - App ID (from Facebook Developers)
   - App Secret (from Facebook Developers)
3. Add redirect URL to Facebook app settings

## 🎯 Testing Your Authentication

### Test Sign Up
1. Open the registration screen
2. Enter a valid email and password
3. Submit the form
4. **With email confirmation enabled**: Check your email for confirmation link
5. **Without email confirmation**: User is immediately created and can log in

### Test Login
1. Open the login screen
2. Use registered credentials
3. Verify successful navigation to feed screen
4. Check that user session persists across app restarts

### Test Password Reset
1. Click "Forgot password?" on login screen
2. Enter your email address
3. Check your email for the reset link
4. Click the link and set a new password
5. Log in with the new password

### Test OAuth (if configured)
1. Click Google/Facebook button
2. Complete OAuth authorization
3. Verify automatic account creation
4. Verify user profile in database

## 📱 User Experience Flow

### New User Registration:
1. User enters email/password on registration screen
2. Validation checks format and strength
3. Supabase creates auth user
4. `handle_new_user` trigger creates profile in `user_profiles` table
5. **If email confirmation enabled**: User receives confirmation email
6. User confirms email and can log in
7. **If email confirmation disabled**: User can immediately log in

### Existing User Login:
1. User enters credentials on login screen
2. Validation checks format
3. Supabase authenticates user
4. **If email not confirmed**: Error message displayed
5. **If credentials valid**: Session created, navigate to feed screen

### Password Reset Flow:
1. User clicks "Forgot password?" link
2. Enters email address
3. Receives reset email with secure link
4. Clicks link, enters new password
5. Redirected to login screen
6. Logs in with new credentials

## 🔐 Security Features

- **Password Hashing**: All passwords hashed by Supabase Auth (bcrypt)
- **Row Level Security**: Enabled on `user_profiles` table
- **Email Verification**: Prevents unauthorized account access
- **Session Tokens**: JWT-based authentication with automatic refresh
- **OAuth State Validation**: CSRF protection for social logins
- **Rate Limiting**: Built-in protection against brute force attacks

## 🚀 Your Authentication is Production-Ready!

All the code is implemented and working. You just need to:

1. ✅ Configure email confirmations in Supabase Dashboard (5 minutes)
2. ✅ Set up SMTP or use Supabase's email service (5-10 minutes)
3. ✅ (Optional) Configure OAuth providers (15 minutes per provider)
4. ✅ Test the complete flow (5 minutes)

**Total setup time: 15-30 minutes**

Your users can immediately start signing up and logging in! 🎉

## 📚 Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Email Templates Guide](https://supabase.com/docs/guides/auth/auth-email-templates)
- [OAuth Configuration Guide](https://supabase.com/docs/guides/auth/social-login)
- [Flutter Supabase SDK](https://pub.dev/packages/supabase_flutter)

## 🆘 Troubleshooting

### Email Not Sending
- Verify SMTP credentials are correct
- Check spam/junk folder
- Verify sender email is verified with SMTP provider
- Check Supabase logs for email delivery errors

### OAuth Not Working
- Verify OAuth credentials in Supabase Dashboard
- Check redirect URLs match exactly
- Verify OAuth app is enabled and approved
- Check provider-specific requirements (Google requires verified domains)

### Email Confirmation Not Working
- Verify "Confirm email" is enabled in dashboard
- Check email template is configured
- Verify redirect URL is added to URL configuration
- Test with different email providers (some block verification emails)