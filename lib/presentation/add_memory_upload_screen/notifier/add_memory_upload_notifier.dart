import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:native_exif/native_exif.dart';

import '../models/add_memory_upload_model.dart';
import '../../../core/app_export.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/storage_utils.dart';

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
      memoryStartDate: null,
      memoryEndDate: null,
    );
  }

  /// Set memory details for date validation
  void setMemoryDetails({
    required String memoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    state = state.copyWith(
      memoryId: memoryId,
      memoryStartDate: startDate,
      memoryEndDate: endDate,
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

  /// Extract metadata from selected file and validate date
  Future<void> validateFileMetadata() async {
    if (state.selectedFile == null) {
      setError('No file selected');
      return;
    }

    if (state.memoryStartDate == null || state.memoryEndDate == null) {
      setError('Memory timeline not set');
      return;
    }

    try {
      final filePath = state.selectedFile!.path;
      if (filePath == null) {
        setError('Unable to access file path');
        return;
      }

      // Extract metadata based on file type
      DateTime? captureDate;

      if (state.selectedFile!.name.toLowerCase().endsWith('.jpg') ||
          state.selectedFile!.name.toLowerCase().endsWith('.jpeg') ||
          state.selectedFile!.name.toLowerCase().endsWith('.png')) {
        // Extract EXIF data from image
        captureDate = await _extractImageMetadata(filePath);
      } else if (state.selectedFile!.name.toLowerCase().endsWith('.mp4') ||
          state.selectedFile!.name.toLowerCase().endsWith('.mov')) {
        // Extract metadata from video
        captureDate = await _extractVideoMetadata(filePath);
      }

      if (captureDate == null) {
        // If no metadata found, use file's last modified date
        final file = File(filePath);
        captureDate = await file.lastModified();
      }

      // Validate date against memory timeline
      if (captureDate.isBefore(state.memoryStartDate!) ||
          captureDate.isAfter(state.memoryEndDate!)) {
        final formattedDate = _formatDate(captureDate);
        final formattedStart = _formatDate(state.memoryStartDate!);
        final formattedEnd = _formatDate(state.memoryEndDate!);

        setError(
          'This media was captured on $formattedDate, which is outside the memory timeline ($formattedStart - $formattedEnd). Please select media captured during the memory period.',
        );
        return;
      }

      // Store validated capture date
      state = state.copyWith(
        captureTimestamp: captureDate,
        errorMessage: null,
      );
    } catch (e) {
      print('Error extracting metadata: $e');
      setError('Failed to read media metadata: ${e.toString()}');
    }
  }

  /// Extract metadata from image file
  Future<DateTime?> _extractImageMetadata(String filePath) async {
    try {
      final exif = await Exif.fromPath(filePath);

      // Try to get the date taken from EXIF data
      final dateTimeOriginal = await exif.getOriginalDate();
      await exif.close();

      return dateTimeOriginal;
    } catch (e) {
      print('Error reading image EXIF data: $e');
      return null;
    }
  }

  /// Extract metadata from video file
  Future<DateTime?> _extractVideoMetadata(String filePath) async {
    try {
      // For videos, we use file creation date as native_exif doesn't support video metadata
      final file = File(filePath);
      final stat = await file.stat();
      return stat.modified;
    } catch (e) {
      print('Error reading video metadata: $e');
      return null;
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> uploadFile() async {
    if (state.selectedFile == null) {
      setError('No file selected');
      return;
    }

    if (state.memoryId == null) {
      setError('Memory not specified');
      return;
    }

    // Validate metadata before uploading
    await validateFileMetadata();
    if (state.errorMessage != null) {
      return; // Stop if validation failed
    }

    state = state.copyWith(
      isUploading: true,
      errorMessage: null,
    );

    try {
      final supabaseService = SupabaseService.instance;
      final userId = supabaseService.client?.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Determine media type
      final fileName = state.selectedFile!.name.toLowerCase();
      final isImage = fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png');
      final mediaType = isImage ? 'image' : 'video';

      // Upload to Supabase Storage
      final uploadResult = await StorageUtils.uploadMedia(
        file: state.selectedFile!,
        bucket: 'story-media',
        folder: 'stories',
      );

      if (uploadResult == null) {
        throw Exception('Failed to upload file');
      }

      // Create story with original capture timestamp
      final storyService = StoryService();
      final story = await storyService.createStory(
        memoryId: state.memoryId!,
        contributorId: userId,
        mediaUrl: uploadResult,
        mediaType: mediaType,
        thumbnailUrl: uploadResult,
      );

      if (story == null) {
        throw Exception('Failed to create story');
      }

      // Update the story with the original capture timestamp
      await supabaseService.client?.from('stories').update({
        'capture_timestamp': state.captureTimestamp!.toIso8601String(),
        'is_from_camera_roll': true,
      }).eq('id', story['id']);

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