# Google Sign-In Setup Guide for Supabase

This guide will walk you through setting up Google authentication for your Capsule Memories app using Supabase.

## Prerequisites

- Active Supabase project
- Google Cloud Console account
- Flutter development environment set up

## Step 1: Google Cloud Console Setup

### 1.1 Create OAuth 2.0 Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**

### 1.2 Configure OAuth Consent Screen

Before creating credentials, you need to configure the OAuth consent screen:

1. Click **OAuth consent screen** in the left sidebar
2. Select **External** user type (or Internal if using Google Workspace)
3. Fill in required information:
   - App name: **Capsule Memories**
   - User support email: Your email
   - Developer contact information: Your email
4. Click **Save and Continue**
5. On Scopes page, click **Save and Continue** (default scopes are sufficient)
6. Add test users if needed (for External apps in testing mode)
7. Click **Save and Continue** and then **Back to Dashboard**

### 1.3 Create OAuth Client IDs

You need to create separate OAuth client IDs for:
- Web application (for Supabase)
- Android
- iOS

#### Web Application (Supabase)

1. Click **Create Credentials** → **OAuth client ID**
2. Select **Web application**
3. Name it: **Capsule Memories - Supabase**
4. Add Authorized JavaScript origins (leave empty for now)
5. Add Authorized redirect URIs:
   ```
   https://YOUR_SUPABASE_PROJECT_REF.supabase.co/auth/v1/callback
   ```
   Replace `YOUR_SUPABASE_PROJECT_REF` with your actual Supabase project reference
6. Click **Create**
7. **Save the Client ID and Client Secret** - you'll need these for Supabase

#### Android Application

1. Click **Create Credentials** → **OAuth client ID**
2. Select **Android**
3. Name it: **Capsule Memories - Android**
4. Package name: `com.capsule.app` (or your actual package name from AndroidManifest.xml)
5. Get SHA-1 fingerprint:
   
   **Debug Certificate:**
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   
   **Release Certificate (for production):**
   ```bash
   keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
   ```
   
6. Copy the SHA-1 fingerprint and paste it
7. Click **Create**
8. **Save the Client ID**

#### iOS Application

1. Click **Create Credentials** → **OAuth client ID**
2. Select **iOS**
3. Name it: **Capsule Memories - iOS**
4. Bundle ID: Get from `ios/Runner.xcodeproj/project.pbxproj` or Xcode
   - Usually format: `com.yourcompany.capsulememories`
5. App Store ID: (leave empty for development)
6. Click **Create**
7. **Save the Client ID**

## Step 2: Supabase Dashboard Configuration

### 2.1 Enable Google Provider

1. Go to your [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Navigate to **Authentication** → **Providers**
4. Find **Google** in the provider list
5. Toggle it to **Enabled**

### 2.2 Configure Google Provider

1. In the Google provider settings:
   - **Client ID (for OAuth)**: Paste the Web Application Client ID from Step 1.3
   - **Client Secret (for OAuth)**: Paste the Web Application Client Secret from Step 1.3
2. Click **Save**

### 2.3 Get Redirect URL

Your Supabase OAuth redirect URL should be:
```
https://YOUR_SUPABASE_PROJECT_REF.supabase.co/auth/v1/callback
```

Make sure this matches what you added in Google Cloud Console.

## Step 3: Flutter App Configuration

### 3.1 Deep Link Configuration

The deep link configuration has already been added to your project:

**Android:** `android/app/src/main/AndroidManifest.xml`
- Scheme: `io.supabase.capsulememories`
- Host: `login-callback`

**iOS:** `ios/Runner/Info.plist`
- URL Scheme: `io.supabase.capsulememories`

### 3.2 Update Redirect URL in Code (if needed)

The redirect URL in `login_notifier.dart` is already configured:
```dart
redirectTo: 'io.supabase.capsulememories://login-callback/'
```

If you need to change it, update it in:
- `lib/presentation/login_screen/notifier/login_notifier.dart`
- Both `loginWithGoogle()` and `loginWithFacebook()` methods

## Step 4: Testing Google Sign-In

### 4.1 Test on Android

1. Build and run the app:
   ```bash
   flutter run
   ```
2. Navigate to the login screen
3. Tap **Log in with Google**
4. You should be redirected to Google's OAuth consent screen
5. Select your Google account
6. Grant permissions
7. You should be redirected back to the app

### 4.2 Test on iOS

1. Build and run the app:
   ```bash
   flutter run
   ```
2. Follow the same steps as Android testing

### 4.3 Test on Web

1. Build and run for web:
   ```bash
   flutter run -d chrome
   ```
2. Note: Web requires additional configuration in `index.html` if needed

## Troubleshooting

### Common Issues

#### "redirect_uri_mismatch" Error
- **Cause**: The redirect URI in Google Cloud Console doesn't match Supabase
- **Solution**: Verify the redirect URI in Google Cloud Console matches:
  ```
  https://YOUR_SUPABASE_PROJECT_REF.supabase.co/auth/v1/callback
  ```

#### "invalid_client" Error
- **Cause**: Client ID or Client Secret is incorrect
- **Solution**: Double-check the credentials in Supabase dashboard match those from Google Cloud Console

#### Deep Link Not Working
- **Cause**: Deep link configuration missing or incorrect
- **Solution**: 
  - Android: Verify `AndroidManifest.xml` has the correct intent-filter
  - iOS: Verify `Info.plist` has CFBundleURLTypes configured
  - Rebuild the app after making changes

#### OAuth Consent Screen Error
- **Cause**: OAuth consent screen not configured or app not verified
- **Solution**: 
  - Complete OAuth consent screen configuration
  - Add test users if app is in testing mode
  - For production, submit app for verification

#### User Already Exists Error
- **Cause**: Email already registered with different provider
- **Solution**: User must sign in with the original provider or reset account

### Debug Mode

Enable debug logging in Supabase to see detailed OAuth flow:

```dart
// In main.dart or initialization code
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  debug: true, // Enable debug mode
);
```

### Testing with Test Users

For apps in testing mode on Google:

1. Go to Google Cloud Console → OAuth consent screen
2. Add test users under "Test users"
3. Only these users can sign in until app is verified

## Production Checklist

Before going to production:

- [ ] Submit OAuth consent screen for verification (if External)
- [ ] Generate and use production keystore for Android
- [ ] Configure proper Bundle ID and provisioning for iOS
- [ ] Test OAuth flow on real devices
- [ ] Update redirect URIs with production values
- [ ] Remove debug mode from Supabase initialization
- [ ] Set up proper error handling and user feedback
- [ ] Configure rate limiting and abuse prevention in Supabase

## Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

## Security Best Practices

1. **Never commit credentials**: Keep Client ID/Secret in environment variables
2. **Use HTTPS**: Always use secure connections for OAuth
3. **Validate tokens**: Verify tokens on the backend
4. **Implement rate limiting**: Prevent abuse of authentication endpoints
5. **Monitor auth logs**: Regularly check Supabase auth logs for suspicious activity

## Support

If you encounter issues:
1. Check Supabase auth logs in dashboard
2. Review Google Cloud Console API logs
3. Test with different Google accounts
4. Verify all configuration steps completed
5. Check Flutter console for error messages