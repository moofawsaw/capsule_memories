import '../models/notification_settings_model.dart';
import '../../../core/app_export.dart';

part 'notification_settings_state.dart';

final notificationSettingsNotifier = StateNotifierProvider.autoDispose<
    NotificationSettingsNotifier, NotificationSettingsState>(
  (ref) => NotificationSettingsNotifier(
    NotificationSettingsState(
      notificationSettingsModel: NotificationSettingsModel(),
    ),
  ),
);

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier(NotificationSettingsState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      pushNotificationsEnabled: true,
      memoryInvitesEnabled: true,
      memoryActivityEnabled: true,
      memorySealedEnabled: true,
      reactionsEnabled: true,
      newFollowersEnabled: true,
      friendRequestsEnabled: true,
      groupInvitesEnabled: true,
      isLoading: false,
    );
  }

  void updatePushNotifications(bool value) {
    state = state.copyWith(
      pushNotificationsEnabled: value,
    );
  }

  void updateMemoryInvites(bool value) {
    state = state.copyWith(
      memoryInvitesEnabled: value,
    );
  }

  void updateMemoryActivity(bool value) {
    state = state.copyWith(
      memoryActivityEnabled: value,
    );
  }

  void updateMemorySealed(bool value) {
    state = state.copyWith(
      memorySealedEnabled: value,
    );
  }

  void updateReactions(bool value) {
    state = state.copyWith(
      reactionsEnabled: value,
    );
  }

  void updateNewFollowers(bool value) {
    state = state.copyWith(
      newFollowersEnabled: value,
    );
  }

  void updateFriendRequests(bool value) {
    state = state.copyWith(
      friendRequestsEnabled: value,
    );
  }

  void updateGroupInvites(bool value) {
    state = state.copyWith(
      groupInvitesEnabled: value,
    );
  }

  void saveSettings() {
    state = state.copyWith(
      isLoading: true,
    );

    // Simulate API call to save settings
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
        );
      }
    });
  }
}
