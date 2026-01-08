part of 'group_join_confirmation_notifier.dart';

class GroupJoinConfirmationState {
  GroupJoinConfirmationState({
    this.groupJoinConfirmationModel,
    this.isLoading,
    this.errorMessage,
    this.memoryId,
    this.memoryTitle,
    this.creatorName,
    this.creatorAvatar,
    this.memoryCategory,
    this.expiresAt,
    this.memberCount,
    this.isAccepting,
    this.shouldNavigateToTimeline,
    this.shouldNavigateToMemories,
  });

  GroupJoinConfirmationModel? groupJoinConfirmationModel;

  // Loading states
  bool? isLoading;
  bool? isAccepting;
  String? errorMessage;

  // Memory details
  String? memoryId;
  String? memoryTitle;
  String? creatorName;
  String? creatorAvatar;
  String? memoryCategory;
  DateTime? expiresAt;
  int? memberCount;

  // Navigation flags
  bool? shouldNavigateToTimeline;
  bool? shouldNavigateToMemories;

  GroupJoinConfirmationState copyWith({
    GroupJoinConfirmationModel? groupJoinConfirmationModel,
    bool? isLoading,
    bool? isAccepting,
    String? errorMessage,
    String? memoryId,
    String? memoryTitle,
    String? creatorName,
    String? creatorAvatar,
    String? memoryCategory,
    DateTime? expiresAt,
    int? memberCount,
    bool? shouldNavigateToTimeline,
    bool? shouldNavigateToMemories,
  }) {
    return GroupJoinConfirmationState(
      groupJoinConfirmationModel:
          groupJoinConfirmationModel ?? this.groupJoinConfirmationModel,
      isLoading: isLoading ?? this.isLoading,
      isAccepting: isAccepting ?? this.isAccepting,
      errorMessage: errorMessage ?? this.errorMessage,
      memoryId: memoryId ?? this.memoryId,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      memoryCategory: memoryCategory ?? this.memoryCategory,
      expiresAt: expiresAt ?? this.expiresAt,
      memberCount: memberCount ?? this.memberCount,
      shouldNavigateToTimeline:
          shouldNavigateToTimeline ?? this.shouldNavigateToTimeline,
      shouldNavigateToMemories:
          shouldNavigateToMemories ?? this.shouldNavigateToMemories,
    );
  }
}
