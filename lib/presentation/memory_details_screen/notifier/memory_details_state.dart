part of 'memory_details_notifier.dart';

class MemoryDetailsState extends Equatable {
  final TextEditingController? titleController;
  final TextEditingController? inviteLinkController;
  final bool? isPublic;
  final bool? showSuccessMessage;
  final String? successMessage;
  final MemoryDetailsModel? memoryDetailsModel;

  MemoryDetailsState({
    this.titleController,
    this.inviteLinkController,
    this.isPublic = true,
    this.showSuccessMessage = false,
    this.successMessage,
    this.memoryDetailsModel,
  });

  @override
  List<Object?> get props => [
        titleController,
        inviteLinkController,
        isPublic,
        showSuccessMessage,
        successMessage,
        memoryDetailsModel,
      ];

  MemoryDetailsState copyWith({
    TextEditingController? titleController,
    TextEditingController? inviteLinkController,
    bool? isPublic,
    bool? showSuccessMessage,
    String? successMessage,
    MemoryDetailsModel? memoryDetailsModel,
  }) {
    return MemoryDetailsState(
      titleController: titleController ?? this.titleController,
      inviteLinkController: inviteLinkController ?? this.inviteLinkController,
      isPublic: isPublic ?? this.isPublic,
      showSuccessMessage: showSuccessMessage ?? this.showSuccessMessage,
      successMessage: successMessage ?? this.successMessage,
      memoryDetailsModel: memoryDetailsModel ?? this.memoryDetailsModel,
    );
  }
}
