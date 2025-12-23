part of 'memory_members_notifier.dart';

/// Represents the state of MemoryMembers in the application.

// ignore_for_file: must_be_immutable
class MemoryMembersState extends Equatable {
  MemoryMembersState({
    this.memoryMembersModel,
    this.selectedMemberId,
  });

  MemoryMembersModel? memoryMembersModel;
  String? selectedMemberId;

  @override
  List<Object?> get props => [memoryMembersModel, selectedMemberId];

  MemoryMembersState copyWith({
    MemoryMembersModel? memoryMembersModel,
    String? selectedMemberId,
  }) {
    return MemoryMembersState(
      memoryMembersModel: memoryMembersModel ?? this.memoryMembersModel,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
    );
  }
}
