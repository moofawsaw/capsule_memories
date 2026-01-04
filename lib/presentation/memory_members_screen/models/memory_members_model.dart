import '../../../core/app_export.dart';

/// This class is used in the [MemoryMembersScreen] screen.

// ignore_for_file: must_be_immutable
class MemoryMembersModel extends Equatable {
  MemoryMembersModel({
    this.members,
    this.memoryTitle,
    this.memoryId,
    this.groupId,
    this.groupName,
    this.isLoading = false,
    this.errorMessage,
  }) {
    members = members ?? [];
    memoryTitle = memoryTitle ?? "";
    memoryId = memoryId ?? "";
  }

  List<MemberModel>? members;
  String? memoryTitle;
  String? memoryId;
  String? groupId;
  String? groupName;
  bool isLoading;
  String? errorMessage;

  MemoryMembersModel copyWith({
    List<MemberModel>? members,
    String? memoryTitle,
    String? memoryId,
    String? groupId,
    String? groupName,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MemoryMembersModel(
      members: members ?? this.members,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      memoryId: memoryId ?? this.memoryId,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        members,
        memoryTitle,
        memoryId,
        groupId,
        groupName,
        isLoading,
        errorMessage
      ];
}

// ignore_for_file: must_be_immutable
class MemberModel extends Equatable {
  MemberModel({
    this.userId,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.isCreator = false,
    this.isVerified = false,
    this.joinedAt,
  }) {
    userId = userId ?? "";
    displayName = displayName ?? "";
    username = username ?? "";
    avatarUrl = avatarUrl ?? "";
  }

  String? userId;
  String? displayName;
  String? username;
  String? avatarUrl;
  bool isCreator;
  bool isVerified;
  String? joinedAt;

  MemberModel copyWith({
    String? userId,
    String? displayName,
    String? username,
    String? avatarUrl,
    bool? isCreator,
    bool? isVerified,
    String? joinedAt,
  }) {
    return MemberModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCreator: isCreator ?? this.isCreator,
      isVerified: isVerified ?? this.isVerified,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        username,
        avatarUrl,
        isCreator,
        isVerified,
        joinedAt
      ];
}
