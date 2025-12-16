part of 'memory_invitation_notifier.dart';

class MemoryInvitationState extends Equatable {
  final bool? isLoading;
  final bool? isJoined;
  final MemoryInvitationModel? memoryInvitationModel;

  MemoryInvitationState({
    this.isLoading = false,
    this.isJoined = false,
    this.memoryInvitationModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        isJoined,
        memoryInvitationModel,
      ];

  MemoryInvitationState copyWith({
    bool? isLoading,
    bool? isJoined,
    MemoryInvitationModel? memoryInvitationModel,
  }) {
    return MemoryInvitationState(
      isLoading: isLoading ?? this.isLoading,
      isJoined: isJoined ?? this.isJoined,
      memoryInvitationModel:
          memoryInvitationModel ?? this.memoryInvitationModel,
    );
  }
}
