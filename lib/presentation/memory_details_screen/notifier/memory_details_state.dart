part of 'memory_details_notifier.dart';

class MemoryDetailsState extends Equatable {
  final TextEditingController? titleController;
  final TextEditingController? inviteLinkController;
  final bool? isPublic;
  final bool? showSuccessMessage;
  final String? successMessage;
  final bool isSaving;
  final bool isSharing;
  final MemoryDetailsModel? memoryDetailsModel;

  MemoryDetailsState({
    this.titleController,
    this.inviteLinkController,
    this.isPublic = true,
    this.showSuccessMessage = false,
    this.successMessage,
    this.isSaving = false,
    this.isSharing = false,
    this.memoryDetailsModel,
  });

  @override
  List<Object?> get props => [
        titleController,
        inviteLinkController,
        isPublic,
        showSuccessMessage,
        successMessage,
        isSaving,
        isSharing,
        memoryDetailsModel,
      ];

  MemoryDetailsState copyWith({
    TextEditingController? titleController,
    TextEditingController? inviteLinkController,
    bool? isPublic,
    bool? showSuccessMessage,
    String? successMessage,
    bool? isSaving,
    bool? isSharing,
    MemoryDetailsModel? memoryDetailsModel,
  }) {
    return MemoryDetailsState(
      titleController: titleController ?? this.titleController,
      inviteLinkController: inviteLinkController ?? this.inviteLinkController,
      isPublic: isPublic ?? this.isPublic,
      showSuccessMessage: showSuccessMessage ?? this.showSuccessMessage,
      successMessage: successMessage ?? this.successMessage,
      isSaving: isSaving ?? this.isSaving,
      isSharing: isSharing ?? this.isSharing,
      memoryDetailsModel: memoryDetailsModel ?? this.memoryDetailsModel,
    );
  }
}
