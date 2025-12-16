part of 'notification_settings_notifier.dart';

class NotificationSettingsState extends Equatable {
  final bool? pushNotificationsEnabled;
  final bool? memoryInvitesEnabled;
  final bool? memoryActivityEnabled;
  final bool? memorySealedEnabled;
  final bool? reactionsEnabled;
  final bool? newFollowersEnabled;
  final bool? friendRequestsEnabled;
  final bool? groupInvitesEnabled;
  final bool? isLoading;
  final bool? isSuccess;
  final NotificationSettingsModel? notificationSettingsModel;

  NotificationSettingsState({
    this.pushNotificationsEnabled,
    this.memoryInvitesEnabled,
    this.memoryActivityEnabled,
    this.memorySealedEnabled,
    this.reactionsEnabled,
    this.newFollowersEnabled,
    this.friendRequestsEnabled,
    this.groupInvitesEnabled,
    this.isLoading = false,
    this.isSuccess = false,
    this.notificationSettingsModel,
  });

  @override
  List<Object?> get props => [
        pushNotificationsEnabled,
        memoryInvitesEnabled,
        memoryActivityEnabled,
        memorySealedEnabled,
        reactionsEnabled,
        newFollowersEnabled,
        friendRequestsEnabled,
        groupInvitesEnabled,
        isLoading,
        isSuccess,
        notificationSettingsModel,
      ];

  NotificationSettingsState copyWith({
    bool? pushNotificationsEnabled,
    bool? memoryInvitesEnabled,
    bool? memoryActivityEnabled,
    bool? memorySealedEnabled,
    bool? reactionsEnabled,
    bool? newFollowersEnabled,
    bool? friendRequestsEnabled,
    bool? groupInvitesEnabled,
    bool? isLoading,
    bool? isSuccess,
    NotificationSettingsModel? notificationSettingsModel,
  }) {
    return NotificationSettingsState(
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      memoryInvitesEnabled: memoryInvitesEnabled ?? this.memoryInvitesEnabled,
      memoryActivityEnabled:
          memoryActivityEnabled ?? this.memoryActivityEnabled,
      memorySealedEnabled: memorySealedEnabled ?? this.memorySealedEnabled,
      reactionsEnabled: reactionsEnabled ?? this.reactionsEnabled,
      newFollowersEnabled: newFollowersEnabled ?? this.newFollowersEnabled,
      friendRequestsEnabled:
          friendRequestsEnabled ?? this.friendRequestsEnabled,
      groupInvitesEnabled: groupInvitesEnabled ?? this.groupInvitesEnabled,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      notificationSettingsModel:
          notificationSettingsModel ?? this.notificationSettingsModel,
    );
  }
}
