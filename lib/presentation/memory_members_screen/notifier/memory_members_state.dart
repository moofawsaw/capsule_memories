part of 'memory_members_notifier.dart';

class MemoryMembersState extends Equatable {
  final MemoryMembersModel? memoryMembersModel;
  final String? selectedMemberName;
  final bool? isLoading;

  MemoryMembersState({
    this.memoryMembersModel,
    this.selectedMemberName,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
        memoryMembersModel,
        selectedMemberName,
        isLoading,
      ];

  MemoryMembersState copyWith({
    MemoryMembersModel? memoryMembersModel,
    String? selectedMemberName,
    bool? isLoading,
  }) {
    return MemoryMembersState(
      memoryMembersModel: memoryMembersModel ?? this.memoryMembersModel,
      selectedMemberName: selectedMemberName ?? this.selectedMemberName,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
