import '../../../core/app_export.dart';
import '../models/notification_settings_model.dart';

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
  )),
);

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier(NotificationSettingsState state) : super(state);

  void updatePushNotifications(bool value) {
    // Master toggle: when turned off, turn off all nested toggles
    // When turned on, turn on all nested toggles
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
  }

  void updateMemoryInvites(bool value) {
    state = state.copyWith(memoryInvitesEnabled: value);
  }

  void updateMemoryActivity(bool value) {
    state = state.copyWith(memoryActivityEnabled: value);
  }

  void updateMemorySealed(bool value) {
    state = state.copyWith(memorySealedEnabled: value);
  }

  void updateReactions(bool value) {
    state = state.copyWith(reactionsEnabled: value);
  }

  void updateNewFollowers(bool value) {
    state = state.copyWith(newFollowersEnabled: value);
  }

  void updateFriendRequests(bool value) {
    state = state.copyWith(friendRequestsEnabled: value);
  }

  void updateGroupInvites(bool value) {
    state = state.copyWith(groupInvitesEnabled: value);
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
