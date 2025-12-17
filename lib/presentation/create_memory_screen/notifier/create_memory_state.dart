part of 'create_memory_notifier.dart';

class CreateMemoryState {
  final CreateMemoryModel? createMemoryModel;
  final TextEditingController? memoryNameController;
  final bool? isLoading;
  final int? currentStep;
  final bool? shouldNavigateToInvite;
  final bool? shouldNavigateBack;

  CreateMemoryState({
    this.createMemoryModel,
    this.memoryNameController,
    this.isLoading = false,
    this.currentStep = 1,
    this.shouldNavigateToInvite = false,
    this.shouldNavigateBack = false,
  });

  CreateMemoryState copyWith({
    CreateMemoryModel? createMemoryModel,
    TextEditingController? memoryNameController,
    bool? isLoading,
    int? currentStep,
    bool? shouldNavigateToInvite,
    bool? shouldNavigateBack,
  }) {
    return CreateMemoryState(
      createMemoryModel: createMemoryModel ?? this.createMemoryModel,
      memoryNameController: memoryNameController ?? this.memoryNameController,
      isLoading: isLoading ?? this.isLoading,
      currentStep: currentStep ?? this.currentStep,
      shouldNavigateToInvite:
          shouldNavigateToInvite ?? this.shouldNavigateToInvite,
      shouldNavigateBack: shouldNavigateBack ?? this.shouldNavigateBack,
    );
  }
}
