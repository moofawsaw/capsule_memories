part of 'add_memory_upload_notifier.dart';

class AddMemoryUploadState extends Equatable {
  final PlatformFile? selectedFile;
  final bool? isUploading;
  final bool? uploadSuccess;
  final String? errorMessage;
  final AddMemoryUploadModel? addMemoryUploadModel;
  final String? memoryId;
  final DateTime? memoryStartDate;
  final DateTime? memoryEndDate;
  final DateTime? captureTimestamp;

  AddMemoryUploadState({
    this.selectedFile,
    this.isUploading = false,
    this.uploadSuccess = false,
    this.errorMessage,
    this.addMemoryUploadModel,
    this.memoryId,
    this.memoryStartDate,
    this.memoryEndDate,
    this.captureTimestamp,
  });

  @override
  List<Object?> get props => [
        selectedFile,
        isUploading,
        uploadSuccess,
        errorMessage,
        addMemoryUploadModel,
        memoryId,
        memoryStartDate,
        memoryEndDate,
        captureTimestamp,
      ];

  AddMemoryUploadState copyWith({
    PlatformFile? selectedFile,
    bool? isUploading,
    bool? uploadSuccess,
    String? errorMessage,
    AddMemoryUploadModel? addMemoryUploadModel,
    String? memoryId,
    DateTime? memoryStartDate,
    DateTime? memoryEndDate,
    DateTime? captureTimestamp,
  }) {
    return AddMemoryUploadState(
      selectedFile: selectedFile ?? this.selectedFile,
      isUploading: isUploading ?? this.isUploading,
      uploadSuccess: uploadSuccess ?? this.uploadSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      addMemoryUploadModel: addMemoryUploadModel ?? this.addMemoryUploadModel,
      memoryId: memoryId ?? this.memoryId,
      memoryStartDate: memoryStartDate ?? this.memoryStartDate,
      memoryEndDate: memoryEndDate ?? this.memoryEndDate,
      captureTimestamp: captureTimestamp ?? this.captureTimestamp,
    );
  }
}
