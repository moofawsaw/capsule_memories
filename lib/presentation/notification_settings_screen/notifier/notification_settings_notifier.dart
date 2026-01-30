import '../../../core/app_export.dart';
import '../models/notification_settings_model.dart';
import '../../../services/notification_preferences_service.dart';

part 'notification_settings_state.dart';

final notificationSettingsNotifier = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettingsState>(
  (ref) => NotificationSettingsNotifier(NotificationSettingsState(
    notificationSettingsModel: NotificationSettingsModel(),
    pushNotificationsEnabled: true,
    memoryInvitesEnabled: true,
    newStoryEnabled: true,
    memoryExpiringEnabled: true,
    memorySealedEnabled: true,
    followedEnabled: true,
    newFollowerEnabled: true,
    friendRequestsEnabled: true,
    groupInvitesEnabled: true,
    dailyCapsuleReminderEnabled: true,
    friendDailyCapsuleCompletedEnabled: true,
    privateAccountEnabled: false,
    showLocationEnabled: true,
    allowMemoryInvitesEnabled: true,
    allowStoryReactionsEnabled: true,
    allowStorySharingEnabled: true,
  ))
    ..loadPreferences(),
);

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier(NotificationSettingsState state) : super(state);

  final _preferencesService = NotificationPreferencesService.instance;

  /// Load preferences from database on initialization
  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await _preferencesService.loadPreferences();

      if (prefs != null) {
        // Backward compat: fall back to legacy grouped flags if split fields are missing.
        final legacyMemoryActivity = prefs['push_memory_activity'];
        final legacyNewFollowers = prefs['push_new_followers'];
        final legacyDailyCapsule = prefs['push_daily_capsule'];

        state = state.copyWith(
          pushNotificationsEnabled: prefs['push_notifications_enabled'] ?? true,
          memoryInvitesEnabled: prefs['push_memory_invites'] ?? true,
          newStoryEnabled: (prefs['push_new_story'] ?? legacyMemoryActivity) ?? true,
          memoryExpiringEnabled:
              (prefs['push_memory_expiring'] ?? legacyMemoryActivity) ?? true,
          memorySealedEnabled: prefs['push_memory_sealed'] ?? true,
          followedEnabled: (prefs['push_followed'] ?? legacyNewFollowers) ?? true,
          newFollowerEnabled: (prefs['push_new_follower'] ?? legacyNewFollowers) ?? true,
          friendRequestsEnabled: prefs['push_friend_requests'] ?? true,
          groupInvitesEnabled: prefs['push_group_invites'] ?? true,
          dailyCapsuleReminderEnabled:
              (prefs['push_daily_capsule_reminder'] ?? legacyDailyCapsule) ?? true,
          friendDailyCapsuleCompletedEnabled:
              (prefs['push_friend_daily_capsule_completed'] ?? legacyDailyCapsule) ?? true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (error) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updatePushNotifications(bool value) async {
    // Update state immediately for UI responsiveness
    state = state.copyWith(
      pushNotificationsEnabled: value,
      memoryInvitesEnabled: value,
      newStoryEnabled: value,
      memoryExpiringEnabled: value,
      memorySealedEnabled: value,
      followedEnabled: value,
      newFollowerEnabled: value,
      friendRequestsEnabled: value,
      groupInvitesEnabled: value,
      dailyCapsuleReminderEnabled: value,
      friendDailyCapsuleCompletedEnabled: value,
    );

    // Persist to database
    await _preferencesService.updatePushNotifications(value);
  }

  void updateMemoryInvites(bool value) async {
    state = state.copyWith(memoryInvitesEnabled: value);
    await _preferencesService.updatePreference('push_memory_invites', value);
  }

  void updateNewStory(bool value) async {
    state = state.copyWith(newStoryEnabled: value);
    await _preferencesService.updatePreference('push_new_story', value);
  }

  void updateMemoryExpiring(bool value) async {
    state = state.copyWith(memoryExpiringEnabled: value);
    await _preferencesService.updatePreference('push_memory_expiring', value);
  }

  void updateMemorySealed(bool value) async {
    state = state.copyWith(memorySealedEnabled: value);
    await _preferencesService.updatePreference('push_memory_sealed', value);
  }

  void updateFollowed(bool value) async {
    state = state.copyWith(followedEnabled: value);
    await _preferencesService.updatePreference('push_followed', value);
  }

  void updateNewFollower(bool value) async {
    state = state.copyWith(newFollowerEnabled: value);
    await _preferencesService.updatePreference('push_new_follower', value);
  }

  void updateFriendRequests(bool value) async {
    state = state.copyWith(friendRequestsEnabled: value);
    await _preferencesService.updatePreference('push_friend_requests', value);
  }

  void updateGroupInvites(bool value) async {
    state = state.copyWith(groupInvitesEnabled: value);
    await _preferencesService.updatePreference('push_group_invites', value);
  }

  void updateDailyCapsuleReminder(bool value) async {
    state = state.copyWith(dailyCapsuleReminderEnabled: value);
    await _preferencesService.updatePreference('push_daily_capsule_reminder', value);
  }

  void updateFriendDailyCapsuleCompleted(bool value) async {
    state = state.copyWith(friendDailyCapsuleCompletedEnabled: value);
    await _preferencesService.updatePreference(
      'push_friend_daily_capsule_completed',
      value,
    );
  }

  void updatePrivateAccount(bool value) {
    state = state.copyWith(privateAccountEnabled: value);
  }

  void updateShowLocation(bool value) {
    state = state.copyWith(showLocationEnabled: value);
  }

  void updateAllowMemoryInvites(bool value) {
    state = state.copyWith(allowMemoryInvitesEnabled: value);
  }

  void updateAllowStoryReactions(bool value) {
    state = state.copyWith(allowStoryReactionsEnabled: value);
  }

  void updateAllowStorySharing(bool value) {
    state = state.copyWith(allowStorySharingEnabled: value);
  }
}
