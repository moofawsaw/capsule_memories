import 'package:file_picker/file_picker.dart';
import '../models/add_memory_upload_model.dart';
import '../../../core/app_export.dart';

part 'add_memory_upload_state.dart';

final addMemoryUploadNotifier = StateNotifierProvider.autoDispose<
    AddMemoryUploadNotifier, AddMemoryUploadState>(
  (ref) => AddMemoryUploadNotifier(
    AddMemoryUploadState(
      addMemoryUploadModel: AddMemoryUploadModel(),
    ),
  ),
);

class AddMemoryUploadNotifier extends StateNotifier<AddMemoryUploadState> {
  AddMemoryUploadNotifier(AddMemoryUploadState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      isUploading: false,
      selectedFile: null,
      errorMessage: null,
    );
  }

  void setSelectedFile(PlatformFile file) {
    state = state.copyWith(
      selectedFile: file,
      errorMessage: null,
    );
  }

  void setError(String message) {
    state = state.copyWith(
      errorMessage: message,
      isUploading: false,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> uploadFile() async {
    if (state.selectedFile == null) {
      setError('No file selected');
      return;
    }

    state = state.copyWith(
      isUploading: true,
      errorMessage: null,
    );

    try {
      // Simulate file upload process
      await Future.delayed(Duration(seconds: 2));

      // In a real app, you would upload the file to your server here
      // For now, we'll just simulate a successful upload

      state = state.copyWith(
        isUploading: false,
        uploadSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Failed to upload file: ${e.toString()}',
      );
    }
  }

  void resetUploadState() {
    state = state.copyWith(
      selectedFile: null,
      isUploading: false,
      uploadSuccess: false,
      errorMessage: null,
    );
  }
}
