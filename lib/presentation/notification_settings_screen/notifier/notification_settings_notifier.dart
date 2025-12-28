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
    memoryActivityEnabled: true,
    memorySealedEnabled: true,
    reactionsEnabled: true,
    newFollowersEnabled: true,
    friendRequestsEnabled: true,
    groupInvitesEnabled: true,
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
        state = state.copyWith(
          pushNotificationsEnabled: prefs['push_notifications_enabled'] ?? true,
          memoryInvitesEnabled: prefs['push_memory_invites'] ?? true,
          memoryActivityEnabled: prefs['push_memory_activity'] ?? true,
          memorySealedEnabled: prefs['push_memory_sealed'] ?? true,
          reactionsEnabled: prefs['push_reactions'] ?? true,
          newFollowersEnabled: prefs['push_new_followers'] ?? true,
          friendRequestsEnabled: prefs['push_friend_requests'] ?? true,
          groupInvitesEnabled: prefs['push_group_invites'] ?? true,
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
      memoryActivityEnabled: value,
      memorySealedEnabled: value,
      reactionsEnabled: value,
      newFollowersEnabled: value,
      friendRequestsEnabled: value,
      groupInvitesEnabled: value,
    );

    // Persist to database
    await _preferencesService.updatePushNotifications(value);
  }

  void updateMemoryInvites(bool value) async {
    state = state.copyWith(memoryInvitesEnabled: value);
    await _preferencesService.updatePreference('push_memory_invites', value);
  }

  void updateMemoryActivity(bool value) async {
    state = state.copyWith(memoryActivityEnabled: value);
    await _preferencesService.updatePreference('push_memory_activity', value);
  }

  void updateMemorySealed(bool value) async {
    state = state.copyWith(memorySealedEnabled: value);
    await _preferencesService.updatePreference('push_memory_sealed', value);
  }

  void updateReactions(bool value) async {
    state = state.copyWith(reactionsEnabled: value);
    await _preferencesService.updatePreference('push_reactions', value);
  }

  void updateNewFollowers(bool value) async {
    state = state.copyWith(newFollowersEnabled: value);
    await _preferencesService.updatePreference('push_new_followers', value);
  }

  void updateFriendRequests(bool value) async {
    state = state.copyWith(friendRequestsEnabled: value);
    await _preferencesService.updatePreference('push_friend_requests', value);
  }

  void updateGroupInvites(bool value) async {
    state = state.copyWith(groupInvitesEnabled: value);
    await _preferencesService.updatePreference('push_group_invites', value);
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
