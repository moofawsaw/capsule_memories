part of 'create_memory_notifier.dart';

class CreateMemoryState extends Equatable {
  final TextEditingController? memoryNameController;
  final bool? isLoading;
  final bool? shouldNavigateToInvite;
  final bool? shouldNavigateBack;
  final CreateMemoryModel? createMemoryModel;

  CreateMemoryState({
    this.memoryNameController,
    this.isLoading = false,
    this.shouldNavigateToInvite = false,
    this.shouldNavigateBack = false,
    this.createMemoryModel,
  });

  @override
  List<Object?> get props => [
        memoryNameController,
        isLoading,
        shouldNavigateToInvite,
        shouldNavigateBack,
        createMemoryModel,
      ];

  CreateMemoryState copyWith({
    TextEditingController? memoryNameController,
    bool? isLoading,
    bool? shouldNavigateToInvite,
    bool? shouldNavigateBack,
    CreateMemoryModel? createMemoryModel,
  }) {
    return CreateMemoryState(
      memoryNameController: memoryNameController ?? this.memoryNameController,
      isLoading: isLoading ?? this.isLoading,
      shouldNavigateToInvite:
          shouldNavigateToInvite ?? this.shouldNavigateToInvite,
      shouldNavigateBack: shouldNavigateBack ?? this.shouldNavigateBack,
      createMemoryModel: createMemoryModel ?? this.createMemoryModel,
    );
  }
}
