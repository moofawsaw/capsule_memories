part of 'add_memory_upload_notifier.dart';

class AddMemoryUploadState extends Equatable {
  final PlatformFile? selectedFile;
  final bool? isUploading;
  final bool? uploadSuccess;
  final String? errorMessage;
  final AddMemoryUploadModel? addMemoryUploadModel;

  final String? memoryId;

  // ✅ Memory metadata
  final String? memoryName;
  final DateTime? memoryStartDate;
  final DateTime? memoryEndDate;

  // ✅ Extracted capture time + eligibility flag
  final DateTime? captureTimestamp;
  final bool? isWithinMemoryWindow;

  const AddMemoryUploadState({
    this.selectedFile,
    this.isUploading = false,
    this.uploadSuccess = false,
    this.errorMessage,
    this.addMemoryUploadModel,
    this.memoryId,
    this.memoryName,
    this.memoryStartDate,
    this.memoryEndDate,
    this.captureTimestamp,
    this.isWithinMemoryWindow,
  });

  @override
  List<Object?> get props => [
    selectedFile,
    isUploading,
    uploadSuccess,
    errorMessage,
    addMemoryUploadModel,
    memoryId,
    memoryName,
    memoryStartDate,
    memoryEndDate,
    captureTimestamp,
    isWithinMemoryWindow,
  ];

  AddMemoryUploadState copyWith({
    PlatformFile? selectedFile,
    bool? isUploading,
    bool? uploadSuccess,
    String? errorMessage,
    AddMemoryUploadModel? addMemoryUploadModel,
    String? memoryId,
    String? memoryName,
    DateTime? memoryStartDate,
    DateTime? memoryEndDate,
    DateTime? captureTimestamp,
    bool? isWithinMemoryWindow,
  }) {
    return AddMemoryUploadState(
      selectedFile: selectedFile ?? this.selectedFile,
      isUploading: isUploading ?? this.isUploading,
      uploadSuccess: uploadSuccess ?? this.uploadSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      addMemoryUploadModel: addMemoryUploadModel ?? this.addMemoryUploadModel,
      memoryId: memoryId ?? this.memoryId,
      memoryName: memoryName ?? this.memoryName,
      memoryStartDate: memoryStartDate ?? this.memoryStartDate,
      memoryEndDate: memoryEndDate ?? this.memoryEndDate,
      captureTimestamp: captureTimestamp ?? this.captureTimestamp,
      isWithinMemoryWindow: isWithinMemoryWindow ?? this.isWithinMemoryWindow,
    );
  }
}
