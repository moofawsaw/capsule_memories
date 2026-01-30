part of 'group_join_confirmation_notifier.dart';

class GroupJoinConfirmationState {
  GroupJoinConfirmationState({
    this.groupJoinConfirmationModel,
    this.isLoading,
    this.errorMessage,
    this.groupId,
    this.groupName,
    this.creatorName,
    this.creatorAvatar,
    this.memberAvatars,
    this.memberCount,
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
  String? groupName;
  String? creatorName;
  String? creatorAvatar;
  List<String>? memberAvatars;
  int? memberCount;

  // Navigation flags
  bool? shouldNavigateToGroups;

  GroupJoinConfirmationState copyWith({
    GroupJoinConfirmationModel? groupJoinConfirmationModel,
    bool? isLoading,
    bool? isAccepting,
    String? errorMessage,
    String? groupId,
    String? groupName,
    String? creatorName,
    String? creatorAvatar,
    List<String>? memberAvatars,
    int? memberCount,
    bool? shouldNavigateToGroups,
  }) {
    return GroupJoinConfirmationState(
      groupJoinConfirmationModel:
          groupJoinConfirmationModel ?? this.groupJoinConfirmationModel,
      isLoading: isLoading ?? this.isLoading,
      isAccepting: isAccepting ?? this.isAccepting,
      errorMessage: errorMessage ?? this.errorMessage,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      memberAvatars: memberAvatars ?? this.memberAvatars,
      memberCount: memberCount ?? this.memberCount,
      shouldNavigateToGroups:
          shouldNavigateToGroups ?? this.shouldNavigateToGroups,
    );
  }
}
