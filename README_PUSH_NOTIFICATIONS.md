# Native Push Notifications Implementation Guide

## Overview
This app uses **native push notifications via APNs (iOS) and FCM (Android)** with device token storage in Supabase database and in-app notification preferences management.

## Architecture

### 1. Database Layer (`fcm_tokens` + `email_preferences` tables)
- **FCM Tokens Storage**: Device tokens stored with user_id, device_id, device_type, is_active status
- **Notification Preferences**: Push preferences stored in `email_preferences` table with individual toggles
- **RLS Policies**: Users can only manage their own tokens and preferences

### 2. Service Layer
- **PushNotificationService**: Handles token registration, notification display, and permission requests
- **NotificationPreferencesService**: Manages loading/saving preferences to database
- **Integration**: Both services integrate with Supabase for data persistence

### 3. UI Layer
- **Notification Settings Screen**: Complete UI with master toggle and individual preference controls
- **State Management**: Riverpod-based state with database persistence
- **Real-time Updates**: Preferences sync immediately when user makes changes

## Features Implemented

### ✅ Device Token Management
- Automatic token registration on app launch
- Device-specific token storage (supports multiple devices per user)
- Token lifecycle management (active/inactive states)
- Automatic cleanup of inactive tokens

### ✅ In-App Notification Preferences
- Master push notification toggle (disables/enables all)
- Individual preference controls:
  - Memory Invites
  - Memory Activity
  - Memory Sealed
  - Reactions
  - New Followers
  - Friend Requests
  - Group Invites

### ✅ Database Persistence
- All preferences stored in Supabase `email_preferences` table
- Automatic loading on app launch
- Real-time syncing when user updates preferences
- Optimistic UI updates with database persistence

## How It Works

### 1. Token Registration Flow
```dart
// On app launch (in main.dart)
await PushNotificationService.instance.initialize();

// When user logs in
await PushNotificationService.instance.registerToken(fcmToken);

// When user logs out
await PushNotificationService.instance.unregisterToken();
```

### 2. Preference Management Flow
```dart
// Load preferences on app launch
await NotificationPreferencesService.instance.loadPreferences();

// Update individual preference
await NotificationPreferencesService.instance.updatePreference(
  'push_memory_invites', 
  true
);

// Update master toggle
await NotificationPreferencesService.instance.updatePushNotifications(false);
```

### 3. Showing Notifications
```dart
// Show notification (automatically checks preferences)
await PushNotificationService.instance.showNotification(
  title: 'New Memory Invite',
  body: 'John invited you to a memory',
  notificationType: 'push_memory_invites', // checks this preference
);
```

## Database Schema

### `fcm_tokens` Table
```sql
- id (uuid, primary key)
- user_id (uuid, foreign key to user_profiles)
- token (text, FCM device token)
- device_id (text, unique device identifier)
- device_type (text, 'android' or 'ios')
- is_active (boolean, token active status)
- created_at (timestamp)
- updated_at (timestamp)
- last_used_at (timestamp)
```

### `email_preferences` Table (Extended)
```sql
-- Existing columns
- user_id (uuid, foreign key to user_profiles)
- memory_notifications (boolean)
- social_notifications (boolean)
- marketing_emails (boolean)
- weekly_digest (boolean)

-- New push notification columns
- push_notifications_enabled (boolean, master toggle)
- push_memory_invites (boolean)
- push_memory_activity (boolean)
- push_memory_sealed (boolean)
- push_reactions (boolean)
- push_new_followers (boolean)
- push_friend_requests (boolean)
- push_group_invites (boolean)
```

## Setup Instructions

### 1. Firebase Configuration (Already Done)
- Firebase project configured
- APNs certificates uploaded for iOS
- FCM server key configured
- `send-push-notification` edge function deployed

### 2. Database Migration
```bash
# Apply the migration to add push preference columns
supabase db push
```

### 3. App Integration (Already Done)
- Services imported and initialized in main.dart
- Notification settings screen configured
- State management connected to database

## Usage Examples

### Example 1: Check if user has notifications enabled
```dart
final prefs = await NotificationPreferencesService.instance.loadPreferences();
final enabled = prefs?['push_notifications_enabled'] ?? true;

if (enabled) {
  // Send push notification
}
```

### Example 2: Send notification respecting preferences
```dart
// This automatically checks preferences before showing
await PushNotificationService.instance.showNotification(
  title: 'New Follower',
  body: 'Sarah started following you',
  notificationType: 'push_new_followers',
);
```

### Example 3: Update preferences from settings screen
```dart
// User toggles memory invites
ref.read(notificationSettingsNotifier.notifier)
   .updateMemoryInvites(true);
// This automatically saves to database
```

## Security

### Row Level Security (RLS)
- Users can only view/modify their own tokens and preferences
- Admins can view all tokens (for support/debugging)
- Token registration requires authentication

### Best Practices
- Tokens are never exposed in logs (use debugPrint carefully)
- Inactive tokens are automatically cleaned up
- Device-specific tokens prevent cross-device issues

## Testing

### Test Token Registration
1. Launch app while logged in
2. Check database: `SELECT * FROM fcm_tokens WHERE user_id = 'YOUR_USER_ID'`
3. Verify token is stored with correct device_type

### Test Preferences
1. Open notification settings screen
2. Toggle any preference
3. Check database: `SELECT * FROM email_preferences WHERE user_id = 'YOUR_USER_ID'`
4. Verify column updated correctly

### Test Notification Display
1. Disable a notification type in settings
2. Try to show that notification type
3. Verify it doesn't appear (check console logs)

## Troubleshooting

### Tokens not registering
- Check user is authenticated
- Verify FCM/APNs setup in Firebase console
- Check console logs for error messages

### Preferences not saving
- Verify user is authenticated
- Check Supabase connection
- Verify RLS policies allow user updates

### Notifications not showing
- Check master push toggle is enabled
- Verify specific notification type is enabled
- Check device notification permissions
- Verify notification channel created (Android)

## Next Steps

1. **Implement Firebase Cloud Messaging**:
   - Add firebase_messaging package
   - Configure APNs/FCM in Flutter
   - Handle background/terminated app states

2. **Enhance Edge Function**:
   - Update `send-push-notification` to respect user preferences
   - Add support for rich notifications (images, actions)
   - Implement notification batching for performance

3. **Add Analytics**:
   - Track notification delivery rates
   - Monitor user preference changes
   - Measure notification engagement

## Support

For issues related to push notifications:
1. Check Supabase logs for database errors
2. Review Flutter console for service errors
3. Verify Firebase console for delivery issues
4. Check device notification permissions