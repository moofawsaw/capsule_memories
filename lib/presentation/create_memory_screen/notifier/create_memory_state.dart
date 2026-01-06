part of 'create_memory_notifier.dart';

class CreateMemoryState {
  final CreateMemoryModel? createMemoryModel;
  final TextEditingController? memoryNameController;
  final TextEditingController? searchController;
  final bool isLoading;
  final int? currentStep;
  final bool? shouldNavigateToInvite;
  final bool? shouldNavigateBack;
  final bool? shouldNavigateToConfirmation;
  final String? createdMemoryId;
  final String? errorMessage;

  CreateMemoryState({
    this.createMemoryModel,
    this.memoryNameController,
    this.searchController,
    this.isLoading = false,
    this.currentStep,
    this.shouldNavigateToInvite,
    this.shouldNavigateBack,
    this.shouldNavigateToConfirmation,
    this.createdMemoryId,
    this.errorMessage,
  });

  CreateMemoryState copyWith({
    CreateMemoryModel? createMemoryModel,
    TextEditingController? memoryNameController,
    TextEditingController? searchController,
    bool? isLoading,
    int? currentStep,
    bool? shouldNavigateToInvite,
    bool? shouldNavigateBack,
    bool? shouldNavigateToConfirmation,
    String? createdMemoryId,
    String? errorMessage,
  }) {
    return CreateMemoryState(
      createMemoryModel: createMemoryModel ?? this.createMemoryModel,
      memoryNameController: memoryNameController ?? this.memoryNameController,
      searchController: searchController ?? this.searchController,
      isLoading: isLoading ?? this.isLoading,
      currentStep: currentStep ?? this.currentStep,
      shouldNavigateToInvite:
          shouldNavigateToInvite ?? this.shouldNavigateToInvite,
      shouldNavigateBack: shouldNavigateBack ?? this.shouldNavigateBack,
      shouldNavigateToConfirmation:
          shouldNavigateToConfirmation ?? this.shouldNavigateToConfirmation,
      createdMemoryId: createdMemoryId ?? this.createdMemoryId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
