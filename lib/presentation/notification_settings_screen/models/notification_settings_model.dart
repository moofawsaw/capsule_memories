import '../../../core/app_export.dart';

/// This class is used in the [NotificationSettingsScreen] screen.

// ignore_for_file: must_be_immutable
class NotificationSettingsModel extends Equatable {
  NotificationSettingsModel({
    this.pushNotificationsEnabled,
    this.memoryInvitesEnabled,
    this.memoryActivityEnabled,
    this.memorySealedEnabled,
    this.newFollowersEnabled,
    this.friendRequestsEnabled,
    this.groupInvitesEnabled,
    this.dailyCapsuleEnabled,
    this.id,
    this.createdAt,
  }) {
    pushNotificationsEnabled = pushNotificationsEnabled ?? true;
    memoryInvitesEnabled = memoryInvitesEnabled ?? true;
    memoryActivityEnabled = memoryActivityEnabled ?? true;
    memorySealedEnabled = memorySealedEnabled ?? true;
    newFollowersEnabled = newFollowersEnabled ?? true;
    friendRequestsEnabled = friendRequestsEnabled ?? true;
    groupInvitesEnabled = groupInvitesEnabled ?? true;
    dailyCapsuleEnabled = dailyCapsuleEnabled ?? true;
    id = id ?? "";
  }

  bool? pushNotificationsEnabled;
  bool? memoryInvitesEnabled;
  bool? memoryActivityEnabled;
  bool? memorySealedEnabled;
  bool? newFollowersEnabled;
  bool? friendRequestsEnabled;
  bool? groupInvitesEnabled;
  bool? dailyCapsuleEnabled;
  String? id;
  final DateTime? createdAt;

  NotificationSettingsModel copyWith({
    bool? pushNotificationsEnabled,
    bool? memoryInvitesEnabled,
    bool? memoryActivityEnabled,
    bool? memorySealedEnabled,
    bool? newFollowersEnabled,
    bool? friendRequestsEnabled,
    bool? groupInvitesEnabled,
    bool? dailyCapsuleEnabled,
    String? id,
    DateTime? createdAt,
  }) {
    return NotificationSettingsModel(
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      memoryInvitesEnabled: memoryInvitesEnabled ?? this.memoryInvitesEnabled,
      memoryActivityEnabled:
          memoryActivityEnabled ?? this.memoryActivityEnabled,
      memorySealedEnabled: memorySealedEnabled ?? this.memorySealedEnabled,
      newFollowersEnabled: newFollowersEnabled ?? this.newFollowersEnabled,
      friendRequestsEnabled:
          friendRequestsEnabled ?? this.friendRequestsEnabled,
      groupInvitesEnabled: groupInvitesEnabled ?? this.groupInvitesEnabled,
      dailyCapsuleEnabled: dailyCapsuleEnabled ?? this.dailyCapsuleEnabled,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        pushNotificationsEnabled,
        memoryInvitesEnabled,
        memoryActivityEnabled,
        memorySealedEnabled,
        newFollowersEnabled,
        friendRequestsEnabled,
        groupInvitesEnabled,
        dailyCapsuleEnabled,
        id,
      ];
}
