part of 'group_join_confirmation_notifier.dart';

class GroupJoinConfirmationState {
  GroupJoinConfirmationState({
    this.groupJoinConfirmationModel,
    this.isLoading,
    this.errorMessage,
    this.groupId,
    this.creatorId,
    this.groupName,
    this.creatorName,
    this.creatorAvatar,
    this.memberAvatars,
    this.memberCount,
    this.createdAt,
    this.members,
    this.isAccepting,
    this.shouldNavigateToGroups,
  });

  GroupJoinConfirmationModel? groupJoinConfirmationModel;

  // Loading states
  bool? isLoading;
  bool? isAccepting;
  String? errorMessage;

  // Group details
  String? groupId;
  String? creatorId;
  String? groupName;
  String? creatorName;
  String? creatorAvatar;
  List<String>? memberAvatars;
  int? memberCount;
  DateTime? createdAt;
  List<GroupMemberPreview>? members;

  // Navigation flags
  bool? shouldNavigateToGroups;

  GroupJoinConfirmationState copyWith({
    GroupJoinConfirmationModel? groupJoinConfirmationModel,
    bool? isLoading,
    bool? isAccepting,
    String? errorMessage,
    String? groupId,
    String? creatorId,
    String? groupName,
    String? creatorName,
    String? creatorAvatar,
    List<String>? memberAvatars,
    int? memberCount,
    DateTime? createdAt,
    List<GroupMemberPreview>? members,
    bool? shouldNavigateToGroups,
  }) {
    return GroupJoinConfirmationState(
      groupJoinConfirmationModel:
          groupJoinConfirmationModel ?? this.groupJoinConfirmationModel,
      isLoading: isLoading ?? this.isLoading,
      isAccepting: isAccepting ?? this.isAccepting,
      errorMessage: errorMessage ?? this.errorMessage,
      groupId: groupId ?? this.groupId,
      creatorId: creatorId ?? this.creatorId,
      groupName: groupName ?? this.groupName,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      memberAvatars: memberAvatars ?? this.memberAvatars,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      shouldNavigateToGroups:
          shouldNavigateToGroups ?? this.shouldNavigateToGroups,
    );
  }
}
