# Push Notifications Setup Guide

This guide explains how to set up Firebase Cloud Messaging (FCM) push notifications for the Capsule app.

## Overview

The push notification system consists of:
1. **Database Storage**: FCM tokens stored in `fcm_tokens` table
2. **Edge Function**: Supabase Edge Function to send notifications via FCM REST API
3. **Flutter Service**: Push notification service using `flutter_local_notifications`
4. **Real-time Integration**: Automatic notification display when app is in foreground

## Prerequisites

1. Firebase project (create at https://console.firebase.google.com)
2. FCM Server Key from Firebase Console
3. Flutter app configured with Firebase (Android & iOS)

## Setup Steps

### 1. Firebase Console Setup

#### Get FCM Server Key
1. Go to Firebase Console → Project Settings
2. Navigate to "Cloud Messaging" tab
3. Copy the "Server key" (legacy)

#### Android Configuration
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/` directory
3. Update `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

4. Update `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.1.2'
}
```

#### iOS Configuration
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to `ios/Runner/` directory in Xcode
3. Update `ios/Podfile`:
```ruby
pod 'Firebase/Messaging'
```

### 2. Supabase Configuration

#### Set Environment Variable
In your Supabase project dashboard:
1. Go to Settings → Edge Functions
2. Add environment variable:
   - Key: `FCM_SERVER_KEY`
   - Value: Your FCM Server Key from Firebase

#### Deploy Edge Function
```bash
supabase functions deploy send-push-notification
```

### 3. Flutter App Integration

The following services are already implemented:

#### PushNotificationService
- Manages FCM token registration
- Displays local notifications
- Handles notification permissions

#### NotificationService
- Real-time notification subscription
- Automatic local notification display
- In-app notification management

### 4. Testing Push Notifications

#### Test from Supabase Dashboard
```sql
-- Call the edge function
SELECT http_post(
  url := 'YOUR_SUPABASE_URL/functions/v1/send-push-notification',
  headers := '{"Authorization": "Bearer YOUR_ANON_KEY", "Content-Type": "application/json"}',
  body := jsonb_build_object(
    'user_id', 'USER_UUID',
    'title', 'Test Notification',
    'body', 'This is a test push notification',
    'notification_type', 'system'
  )
);
```

#### Test from App
1. Login to the app
2. FCM token is automatically registered
3. Create any notification-triggering action
4. Notification should appear even when app is closed

## Architecture

### Database Schema
```sql
fcm_tokens
├── id (uuid)
├── user_id (uuid) → references user_profiles
├── token (text) - FCM token
├── device_id (text) - Unique device identifier
├── device_type (text) - 'android' | 'ios' | 'web'
├── is_active (boolean)
├── created_at (timestamptz)
├── updated_at (timestamptz)
└── last_used_at (timestamptz)
```

### Flow Diagram
```
User Action → Database Trigger → Edge Function → FCM REST API → Device
                                      ↓
                                  In-app Notification Created
```

## Notification Types

The system supports all existing notification types:
- `memory_invite` - Memory invitation
- `friend_request` - Friend request
- `new_story` - New story posted
- `followed` - New follower
- `memory_expiring` - Memory expiring soon
- `memory_sealed` - Memory sealed
- `system` - System notifications

## Troubleshooting

### Notifications not received when app is closed
1. Verify FCM Server Key is correctly set in Supabase
2. Check FCM token is registered in database
3. Ensure device has internet connection
4. Check Firebase Console for delivery logs

### iOS notifications not working
1. Enable "Push Notifications" capability in Xcode
2. Ensure APNs certificate is uploaded to Firebase
3. Check iOS permissions are granted

### Android notifications not showing
1. Verify `google-services.json` is in correct location
2. Check notification channel is created
3. Ensure app has notification permissions

## Security Considerations

1. **Token Security**: FCM tokens are stored securely with RLS policies
2. **User Authorization**: Only users can register tokens for their own account
3. **Token Cleanup**: Inactive tokens are automatically cleaned up after 90 days
4. **Rate Limiting**: Edge function should be protected with rate limiting

## Production Checklist

- [ ] Firebase project created and configured
- [ ] FCM Server Key added to Supabase environment
- [ ] Android `google-services.json` added
- [ ] iOS `GoogleService-Info.plist` added
- [ ] Edge function deployed
- [ ] Database migration applied
- [ ] Push notification permissions requested
- [ ] Token registration tested
- [ ] End-to-end notification flow tested
- [ ] Background notification delivery verified

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications Package](https://pub.dev/packages/flutter_local_notifications)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

## Support

For issues or questions, refer to:
1. Firebase Console logs
2. Supabase Edge Function logs
3. Flutter app debug logs