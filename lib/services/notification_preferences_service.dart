import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user notification preferences
class NotificationPreferencesService {
  static final NotificationPreferencesService instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => instance;
  NotificationPreferencesService._internal();

  final SupabaseClient? _client = SupabaseService.instance.client;

  /// Load user's notification preferences from database
  Future<Map<String, dynamic>?> loadPreferences() async {
    try {
      final userId = _client?.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Cannot load preferences: User not authenticated');
        return null;
      }

      final response = await _client
          ?.from('email_preferences')
          .select(
              'push_notifications_enabled, push_memory_invites, push_memory_activity, '
              'push_memory_sealed, push_reactions, push_new_followers, '
              'push_friend_requests, push_group_invites')
          .eq('user_id', userId)
          .single();

      if (response == null) {
        debugPrint('⚠️ No preferences found for user');
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
    required bool memoryActivityEnabled,
    required bool memorySealedEnabled,
    required bool reactionsEnabled,
    required bool newFollowersEnabled,
    required bool friendRequestsEnabled,
    required bool groupInvitesEnabled,
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
        'push_memory_activity': memoryActivityEnabled,
        'push_memory_sealed': memorySealedEnabled,
        'push_reactions': reactionsEnabled,
        'push_new_followers': newFollowersEnabled,
        'push_friend_requests': friendRequestsEnabled,
        'push_group_invites': groupInvitesEnabled,
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

      // When master toggle is disabled, disable all individual preferences
      // When enabled, enable all individual preferences
      await _client?.from('email_preferences').update({
        'push_notifications_enabled': enabled,
        'push_memory_invites': enabled,
        'push_memory_activity': enabled,
        'push_memory_sealed': enabled,
        'push_reactions': enabled,
        'push_new_followers': enabled,
        'push_friend_requests': enabled,
        'push_group_invites': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

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

      await _client?.from('email_preferences').update({
        field: enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      debugPrint('✅ Preference $field updated to $enabled');
      return true;
    } catch (error) {
      debugPrint('❌ Error updating preference: $error');
      return false;
    }
  }
}
