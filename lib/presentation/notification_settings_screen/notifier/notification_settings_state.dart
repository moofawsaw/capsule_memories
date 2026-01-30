part of 'notification_settings_notifier.dart';

class NotificationSettingsState extends Equatable {
  final bool? pushNotificationsEnabled;
  final bool? memoryInvitesEnabled;
  // Split: independent notification types
  final bool? newStoryEnabled;
  final bool? memoryExpiringEnabled;
  final bool? memorySealedEnabled;
  final bool? followedEnabled;
  final bool? newFollowerEnabled;
  final bool? friendRequestsEnabled;
  final bool? groupInvitesEnabled;
  final bool? dailyCapsuleReminderEnabled;
  final bool? friendDailyCapsuleCompletedEnabled;

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
    this.newStoryEnabled,
    this.memoryExpiringEnabled,
    this.memorySealedEnabled,
    this.followedEnabled,
    this.newFollowerEnabled,
    this.friendRequestsEnabled,
    this.groupInvitesEnabled,
    this.dailyCapsuleReminderEnabled,
    this.friendDailyCapsuleCompletedEnabled,
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
        newStoryEnabled,
        memoryExpiringEnabled,
        memorySealedEnabled,
        followedEnabled,
        newFollowerEnabled,
        friendRequestsEnabled,
        groupInvitesEnabled,
        dailyCapsuleReminderEnabled,
        friendDailyCapsuleCompletedEnabled,
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
    bool? newStoryEnabled,
    bool? memoryExpiringEnabled,
    bool? memorySealedEnabled,
    bool? followedEnabled,
    bool? newFollowerEnabled,
    bool? friendRequestsEnabled,
    bool? groupInvitesEnabled,
    bool? dailyCapsuleReminderEnabled,
    bool? friendDailyCapsuleCompletedEnabled,
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
      newStoryEnabled: newStoryEnabled ?? this.newStoryEnabled,
      memoryExpiringEnabled: memoryExpiringEnabled ?? this.memoryExpiringEnabled,
      memorySealedEnabled: memorySealedEnabled ?? this.memorySealedEnabled,
      followedEnabled: followedEnabled ?? this.followedEnabled,
      newFollowerEnabled: newFollowerEnabled ?? this.newFollowerEnabled,
      friendRequestsEnabled:
          friendRequestsEnabled ?? this.friendRequestsEnabled,
      groupInvitesEnabled: groupInvitesEnabled ?? this.groupInvitesEnabled,
      dailyCapsuleReminderEnabled:
          dailyCapsuleReminderEnabled ?? this.dailyCapsuleReminderEnabled,
      friendDailyCapsuleCompletedEnabled: friendDailyCapsuleCompletedEnabled ??
          this.friendDailyCapsuleCompletedEnabled,
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
