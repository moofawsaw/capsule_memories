part of 'add_memory_upload_notifier.dart';

class AddMemoryUploadState extends Equatable {
  final PlatformFile? selectedFile;
  final bool? isUploading;
  final bool? uploadSuccess;
  final String? errorMessage;
  final AddMemoryUploadModel? addMemoryUploadModel;

  AddMemoryUploadState({
    this.selectedFile,
    this.isUploading = false,
    this.uploadSuccess = false,
    this.errorMessage,
    this.addMemoryUploadModel,
  });

  @override
  List<Object?> get props => [
        selectedFile,
        isUploading,
        uploadSuccess,
        errorMessage,
        addMemoryUploadModel,
      ];

  AddMemoryUploadState copyWith({
    PlatformFile? selectedFile,
    bool? isUploading,
    bool? uploadSuccess,
    String? errorMessage,
    AddMemoryUploadModel? addMemoryUploadModel,
  }) {
    return AddMemoryUploadState(
      selectedFile: selectedFile ?? this.selectedFile,
      isUploading: isUploading ?? this.isUploading,
      uploadSuccess: uploadSuccess ?? this.uploadSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      addMemoryUploadModel: addMemoryUploadModel ?? this.addMemoryUploadModel,
    );
  }
}
