part of 'memory_details_notifier.dart';

class MemoryDetailsState {
  final MemoryDetailsModel? memoryDetailsModel;
  final TextEditingController? titleController;
  final TextEditingController? inviteLinkController;
  final bool isPublic;
  final bool isSaving;
  final bool isSharing;
  final bool showSuccessMessage;
  final String? successMessage;
  final bool isLoading;
  final String? errorMessage;
  final bool isCreator;
  final String? memoryId;

  MemoryDetailsState({
    this.memoryDetailsModel,
    this.titleController,
    this.inviteLinkController,
    this.isPublic = false,
    this.isSaving = false,
    this.isSharing = false,
    this.showSuccessMessage = false,
    this.successMessage,
    this.isLoading = false,
    this.errorMessage,
    this.isCreator = false,
    this.memoryId,
  });

  MemoryDetailsState copyWith({
    MemoryDetailsModel? memoryDetailsModel,
    TextEditingController? titleController,
    TextEditingController? inviteLinkController,
    bool? isPublic,
    bool? isSaving,
    bool? isSharing,
    bool? showSuccessMessage,
    String? successMessage,
    bool? isLoading,
    String? errorMessage,
    bool? isCreator,
    String? memoryId,
  }) {
    return MemoryDetailsState(
      memoryDetailsModel: memoryDetailsModel ?? this.memoryDetailsModel,
      titleController: titleController ?? this.titleController,
      inviteLinkController: inviteLinkController ?? this.inviteLinkController,
      isPublic: isPublic ?? this.isPublic,
      isSaving: isSaving ?? this.isSaving,
      isSharing: isSharing ?? this.isSharing,
      showSuccessMessage: showSuccessMessage ?? this.showSuccessMessage,
      successMessage: successMessage ?? this.successMessage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isCreator: isCreator ?? this.isCreator,
      memoryId: memoryId ?? this.memoryId,
    );
  }
}
