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

  // Privacy settings
  final bool? privateAccountEnabled;
  final bool? showLocationEnabled;
  final bool? allowMemoryInvitesEnabled;
  final bool? allowStoryReactionsEnabled;
  final bool? allowStorySharingEnabled;

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
    this.privateAccountEnabled,
    this.showLocationEnabled,
    this.allowMemoryInvitesEnabled,
    this.allowStoryReactionsEnabled,
    this.allowStorySharingEnabled,
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
        privateAccountEnabled,
        showLocationEnabled,
        allowMemoryInvitesEnabled,
        allowStoryReactionsEnabled,
        allowStorySharingEnabled,
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
    bool? privateAccountEnabled,
    bool? showLocationEnabled,
    bool? allowMemoryInvitesEnabled,
    bool? allowStoryReactionsEnabled,
    bool? allowStorySharingEnabled,
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
      privateAccountEnabled:
          privateAccountEnabled ?? this.privateAccountEnabled,
      showLocationEnabled: showLocationEnabled ?? this.showLocationEnabled,
      allowMemoryInvitesEnabled:
          allowMemoryInvitesEnabled ?? this.allowMemoryInvitesEnabled,
      allowStoryReactionsEnabled:
          allowStoryReactionsEnabled ?? this.allowStoryReactionsEnabled,
      allowStorySharingEnabled:
          allowStorySharingEnabled ?? this.allowStorySharingEnabled,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      notificationSettingsModel:
          notificationSettingsModel ?? this.notificationSettingsModel,
    );
  }
}
