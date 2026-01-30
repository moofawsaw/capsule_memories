import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './push_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user notification preferences
class NotificationPreferencesService {
  static final NotificationPreferencesService instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => instance;
  NotificationPreferencesService._internal();

  SupabaseClient? get _client => SupabaseService.instance.client;

  /// Load user's notification preferences from database
  Future<Map<String, dynamic>?> loadPreferences() async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Cannot load preferences: User not authenticated');
        return null;
      }

      // Use maybeSingle so a missing row doesn't throw.
      final response = await _client
          ?.from('email_preferences')
          .select(
            'push_notifications_enabled, push_memory_invites, push_memory_sealed, '
            'push_friend_requests, push_group_invites, '
            // Split per-type flags
            'push_new_story, push_memory_expiring, push_followed, push_new_follower, '
            'push_daily_capsule_reminder, push_friend_daily_capsule_completed, '
            // Legacy grouped flags (fallback during rollout)
            'push_memory_activity, push_new_followers, push_daily_capsule',
          )
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('ℹ️ No email_preferences row found; using defaults');
        return null;
      }

      debugPrint('✅ Notification preferences loaded');
      return response;
    } catch (error) {
      debugPrint('❌ Error loading notification preferences: $error');
      return null;
    }
  }

  /// Save user's notification preferences to database
  Future<bool> savePreferences({
    required bool pushNotificationsEnabled,
    required bool memoryInvitesEnabled,
    required bool newStoryEnabled,
    required bool memoryExpiringEnabled,
    required bool memorySealedEnabled,
    required bool followedEnabled,
    required bool newFollowerEnabled,
    required bool friendRequestsEnabled,
    required bool groupInvitesEnabled,
    required bool dailyCapsuleReminderEnabled,
    required bool friendDailyCapsuleCompletedEnabled,
  }) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Cannot save preferences: User not authenticated');
        return false;
      }

      await _client?.from('email_preferences').upsert({
        'user_id': userId,
        'push_notifications_enabled': pushNotificationsEnabled,
        'push_memory_invites': memoryInvitesEnabled,
        'push_new_story': newStoryEnabled,
        'push_memory_expiring': memoryExpiringEnabled,
        'push_memory_sealed': memorySealedEnabled,
        'push_followed': followedEnabled,
        'push_new_follower': newFollowerEnabled,
        'push_friend_requests': friendRequestsEnabled,
        'push_group_invites': groupInvitesEnabled,
        'push_daily_capsule_reminder': dailyCapsuleReminderEnabled,
        'push_friend_daily_capsule_completed': friendDailyCapsuleCompletedEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      debugPrint('✅ Notification preferences saved');
      return true;
    } catch (error) {
      debugPrint('❌ Error saving notification preferences: $error');
      return false;
    }
  }

  /// Update master push notification toggle
  Future<bool> updatePushNotifications(bool enabled) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) return false;

      // Upsert so the row is created if missing (source of truth).
      await _client?.from('email_preferences').upsert({
        'user_id': userId,
        'push_notifications_enabled': enabled,
        'push_memory_invites': enabled,
        'push_new_story': enabled,
        'push_memory_expiring': enabled,
        'push_memory_sealed': enabled,
        'push_followed': enabled,
        'push_new_follower': enabled,
        'push_friend_requests': enabled,
        'push_group_invites': enabled,
        'push_daily_capsule_reminder': enabled,
        'push_friend_daily_capsule_completed': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // If enabling notifications, re-register FCM token if it doesn't exist
      if (enabled) {
        final pushService = PushNotificationService.instance;

        // Check if FCM token exists and is active
        final existingToken = await _client
            ?.from('fcm_tokens')
            .select('token, is_active')
            .eq('user_id', userId)
            .maybeSingle();

        if (existingToken == null) {
          // No token exists, register new one
          debugPrint('📱 No FCM token found, re-registering...');
          final fcmToken = pushService.fcmToken;
          if (fcmToken != null) {
            await pushService.registerToken(fcmToken);
          } else {
            debugPrint('⚠️ Cannot re-register: No FCM token available');
          }
        } else if (existingToken['is_active'] == false) {
          // Token exists but is inactive, re-register it
          debugPrint('📱 FCM token inactive, re-registering...');
          final fcmToken = pushService.fcmToken ?? existingToken['token'];
          if (fcmToken != null) {
            await pushService.registerToken(fcmToken);
          }
        }
      }

      debugPrint('✅ Push notifications ${enabled ? "enabled" : "disabled"}');
      return true;
    } catch (error) {
      debugPrint('❌ Error updating push notifications: $error');
      return false;
    }
  }

  /// Update individual preference
  Future<bool> updatePreference(String field, bool enabled) async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) return false;

      // Upsert so the row is created if missing (source of truth).
      await _client?.from('email_preferences').upsert({
        'user_id': userId,
        field: enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      debugPrint('✅ Preference $field updated to $enabled');
      return true;
    } catch (error) {
      debugPrint('❌ Error updating preference: $error');
      return false;
    }
  }
}
