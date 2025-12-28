part of 'memory_invitation_notifier.dart';

class MemoryInvitationState {
  final bool? isLoading;
  final bool? isJoined;
  final Map<String, dynamic>? memoryInvitationModel;

  MemoryInvitationState({
    this.isLoading = false,
    this.isJoined = false,
    this.memoryInvitationModel,
  });

  List<Object?> get props => [
        isLoading,
        isJoined,
        memoryInvitationModel,
      ];

  MemoryInvitationState copyWith({
    bool? isLoading,
    bool? isJoined,
    Map<String, dynamic>? memoryInvitationModel,
  }) {
    return MemoryInvitationState(
      isLoading: isLoading ?? this.isLoading,
      isJoined: isJoined ?? this.isJoined,
      memoryInvitationModel:
          memoryInvitationModel ?? this.memoryInvitationModel,
    );
  }
}