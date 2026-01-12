// lib/presentation/add_memory_upload_screen/notifier/add_memory_upload_notifier.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:native_exif/native_exif.dart';
import 'package:video_player/video_player.dart';

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

  static const int _maxBytes = 50 * 1024 * 1024; // 50MB

  // ✅ Readable formats
  static final DateFormat _readableDate = DateFormat('MMM d, yyyy');
  static final DateFormat _readableDateTime = DateFormat('MMM d, yyyy • h:mm a');

  void initialize() {
    state = state.copyWith(
      isUploading: false,
      selectedFile: null,
      errorMessage: null,
      memoryId: null,
      memoryName: null,
      memoryStartDate: null,
      memoryEndDate: null,
      captureTimestamp: null,
      isWithinMemoryWindow: null,
      uploadSuccess: false,
    );
  }

  /// ✅ Set memory window immediately + fetch memory name async
  Future<void> setMemoryDetails({
    required String memoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = state.copyWith(
      memoryId: memoryId,
      memoryStartDate: startDate,
      memoryEndDate: endDate,
    );

    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final data = await client
          .from('memories')
          .select('name')
          .eq('id', memoryId)
          .single();

      state = state.copyWith(
        memoryName: data['name'] as String?,
      );
    } catch (_) {
      // Non-fatal (UI only)
      state = state.copyWith(memoryName: null);
    }
  }

  void setSelectedFile(PlatformFile file) {
    state = state.copyWith(
      selectedFile: file,
      errorMessage: null,
      captureTimestamp: null,
      isWithinMemoryWindow: null,
      uploadSuccess: false,
    );
  }

  void setError(String message) {
    state = state.copyWith(
      errorMessage: message,
      isUploading: false,
      uploadSuccess: false,
      isWithinMemoryWindow: false,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> validateFileMetadata() async {
    if (state.selectedFile == null) {
      setError('No file selected');
      return;
    }

    if (state.memoryStartDate == null || state.memoryEndDate == null) {
      setError('Memory timeline not set');
      return;
    }

    final file = state.selectedFile!;
    final filePath = file.path;

    if (filePath == null || filePath.isEmpty) {
      setError('Unable to access file path');
      return;
    }

    if (file.size > _maxBytes) {
      setError('File size must be less than 50MB');
      return;
    }

    try {
      DateTime? captureDate;
      final lowerName = file.name.toLowerCase();

      if (lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png')) {
        captureDate = await _extractImageMetadata(filePath);
      } else if (lowerName.endsWith('.mp4') || lowerName.endsWith('.mov')) {
        captureDate = await _extractVideoMetadata(filePath);
      }

      if (captureDate == null) {
        captureDate = await File(filePath).lastModified();
      }

      final captureUtc = captureDate.toUtc();
      final startUtc = state.memoryStartDate!.toUtc();
      final endUtc = state.memoryEndDate!.toUtc();

      final within = !captureUtc.isBefore(startUtc) && !captureUtc.isAfter(endUtc);

      if (!within) {
        state = state.copyWith(
          captureTimestamp: captureUtc,
          isWithinMemoryWindow: false,
          uploadSuccess: false,
          errorMessage:
          'This media was captured on ${_formatReadableDateTime(captureUtc)}, '
              'which is outside the memory timeline '
              '(${_formatReadableDate(startUtc)} → ${_formatReadableDate(endUtc)}). '
              'Please select media captured during the memory period.',
        );
        return;
      }

      state = state.copyWith(
        captureTimestamp: captureUtc,
        isWithinMemoryWindow: true,
        errorMessage: null,
      );
    } catch (e) {
      setError('Failed to read media metadata: ${e.toString()}');
    }
  }

  Future<DateTime?> _extractImageMetadata(String filePath) async {
    try {
      final exif = await Exif.fromPath(filePath);
      final dateTimeOriginal = await exif.getOriginalDate();
      await exif.close();
      return dateTimeOriginal;
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> _extractVideoMetadata(String filePath) async {
    try {
      final stat = await File(filePath).stat();
      return stat.modified;
    } catch (_) {
      return null;
    }
  }

  String _formatReadableDate(DateTime utc) {
    return _readableDate.format(utc.toLocal());
  }

  String _formatReadableDateTime(DateTime utc) {
    return _readableDateTime.format(utc.toLocal());
  }

  /// ✅ Computes duration_seconds:
  /// - images => 0
  /// - videos => real duration (fallback to 0 if any issue)
  Future<int> _computeDurationSeconds({
    required PlatformFile file,
    required bool isImage,
  }) async {
    if (isImage) return 0;

    final path = file.path;
    if (path == null || path.isEmpty) return 0;

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final seconds = controller.value.duration.inSeconds;
      return seconds < 0 ? 0 : seconds;
    } catch (_) {
      return 0;
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
    }
  }

  /// ✅ Upload file + create story
  /// Leaves bottom sheet open on errors (screen controls navigation).
  Future<void> uploadFile() async {
    if (state.selectedFile == null) {
      setError('No file selected');
      return;
    }

    if (state.memoryId == null) {
      setError('Memory not specified');
      return;
    }

    // Re-validate before upload
    await validateFileMetadata();
    if (state.isWithinMemoryWindow != true) return;

    state = state.copyWith(
      isUploading: true,
      errorMessage: null,
      uploadSuccess: false,
    );

    try {
      final supabaseService = SupabaseService.instance;
      final userId = supabaseService.client?.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fileName = state.selectedFile!.name.toLowerCase();
      final isImage = fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png');

      final mediaType = isImage ? 'image' : 'video';

      // ✅ duration_seconds (NOT NULL in DB)
      final durationSeconds = await _computeDurationSeconds(
        file: state.selectedFile!,
        isImage: isImage,
      );

      final uploadResult = await StorageUtils.uploadMedia(
        file: state.selectedFile!,
        bucket: 'story-media',
        folder: 'stories',
      );

      if (uploadResult == null) {
        throw Exception('Failed to upload file');
      }

      final storyService = StoryService();

      final story = await storyService.createStory(
        memoryId: state.memoryId!,
        contributorId: userId,
        mediaUrl: uploadResult,
        mediaType: mediaType,
        thumbnailUrl: uploadResult,
        captureTimestamp: state.captureTimestamp?.toUtc(),
        isFromCameraRoll: true,
        durationSeconds: durationSeconds, // ✅ NEW REQUIRED FIELD
      );

      if (story == null) {
        throw Exception('Create story failed');
      }

      state = state.copyWith(
        isUploading: false,
        uploadSuccess: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadSuccess: false,
        isWithinMemoryWindow: false,
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
      captureTimestamp: null,
      isWithinMemoryWindow: null,
    );
  }
}
