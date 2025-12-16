part of 'group_join_confirmation_notifier.dart';

class GroupJoinConfirmationState extends Equatable {
  final bool? shouldNavigateToCreateMemory;
  final bool? shouldClose;
  final bool? isLoading;
  final GroupJoinConfirmationModel? groupJoinConfirmationModel;

  GroupJoinConfirmationState({
    this.shouldNavigateToCreateMemory = false,
    this.shouldClose = false,
    this.isLoading = false,
    this.groupJoinConfirmationModel,
  });

  @override
  List<Object?> get props => [
        shouldNavigateToCreateMemory,
        shouldClose,
        isLoading,
        groupJoinConfirmationModel,
      ];

  GroupJoinConfirmationState copyWith({
    bool? shouldNavigateToCreateMemory,
    bool? shouldClose,
    bool? isLoading,
    GroupJoinConfirmationModel? groupJoinConfirmationModel,
  }) {
    return GroupJoinConfirmationState(
      shouldNavigateToCreateMemory:
          shouldNavigateToCreateMemory ?? this.shouldNavigateToCreateMemory,
      shouldClose: shouldClose ?? this.shouldClose,
      isLoading: isLoading ?? this.isLoading,
      groupJoinConfirmationModel:
          groupJoinConfirmationModel ?? this.groupJoinConfirmationModel,
    );
  }
}
