import '../../../core/app_export.dart';

/// This class is used in the [NotificationSettingsScreen] screen.

// ignore_for_file: must_be_immutable
class NotificationSettingsModel extends Equatable {
  NotificationSettingsModel({
    this.pushNotificationsEnabled,
    this.memoryInvitesEnabled,
    this.memoryActivityEnabled,
    this.memorySealedEnabled,
    this.reactionsEnabled,
    this.newFollowersEnabled,
    this.friendRequestsEnabled,
    this.groupInvitesEnabled,
    this.id,
  }) {
    pushNotificationsEnabled = pushNotificationsEnabled ?? true;
    memoryInvitesEnabled = memoryInvitesEnabled ?? true;
    memoryActivityEnabled = memoryActivityEnabled ?? true;
    memorySealedEnabled = memorySealedEnabled ?? true;
    reactionsEnabled = reactionsEnabled ?? true;
    newFollowersEnabled = newFollowersEnabled ?? true;
    friendRequestsEnabled = friendRequestsEnabled ?? true;
    groupInvitesEnabled = groupInvitesEnabled ?? true;
    id = id ?? "";
  }

  bool? pushNotificationsEnabled;
  bool? memoryInvitesEnabled;
  bool? memoryActivityEnabled;
  bool? memorySealedEnabled;
  bool? reactionsEnabled;
  bool? newFollowersEnabled;
  bool? friendRequestsEnabled;
  bool? groupInvitesEnabled;
  String? id;

  NotificationSettingsModel copyWith({
    bool? pushNotificationsEnabled,
    bool? memoryInvitesEnabled,
    bool? memoryActivityEnabled,
    bool? memorySealedEnabled,
    bool? reactionsEnabled,
    bool? newFollowersEnabled,
    bool? friendRequestsEnabled,
    bool? groupInvitesEnabled,
    String? id,
  }) {
    return NotificationSettingsModel(
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
      id: id ?? this.id,
    );
  }

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
        id,
      ];
}
