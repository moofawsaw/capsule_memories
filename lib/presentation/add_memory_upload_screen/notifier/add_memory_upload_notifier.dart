// lib/presentation/add_memory_upload_screen/notifier/add_memory_upload_notifier.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:native_exif/native_exif.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../models/add_memory_upload_model.dart';
import '../../../core/app_export.dart';
import '../../../services/network_quality_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/supabase_tus_uploader.dart';
import '../../../services/video_compression_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../services/android_media_store_service.dart';


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

  static const int _maxBytes = 50 * 1024 * 1024;

  static final DateFormat _readableDate = DateFormat('MMM d, yyyy');
  static final DateFormat _readableDateTime = DateFormat('MMM d, yyyy • h:mm a');

  final _uuid = const Uuid();

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

      state = state.copyWith(memoryName: data['name']);
    } catch (_) {
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

  Future<void> validateFileMetadata() async {
    final file = state.selectedFile;
    if (file == null) {
      setError('No file selected');
      return;
    }

    if (state.memoryStartDate == null || state.memoryEndDate == null) {
      setError('Memory timeline not set');
      return;
    }

    if (file.size > _maxBytes) {
      setError('File size must be less than 50MB');
      return;
    }

    final name = file.name.toLowerCase();

    final isImage = name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png');

    final isVideo = name.endsWith('.mp4') || name.endsWith('.mov');

    // Path might be temp (or null on some Android picker flows); identifier can carry content://
    final p = file.path;
    final id = file.identifier;

    try {
      DateTime? captureLocal;

      if (isImage) {
        // 1) Try EXIF from local path if available
        if (p != null && p.isNotEmpty) {
          captureLocal = await _extractImageMetadataLocal(p);
        }

        // 2) ✅ If EXIF missing, try Android MediaStore DATE_TAKEN using content:// identifier
        if (captureLocal == null && !kIsWeb && id != null && id.startsWith('content://')) {
          final millis = await AndroidMediaStoreService.getDateTakenMillis(id);
          if (millis != null && millis > 0) {
            captureLocal = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
          }
        }

        // 3) Still nothing -> strict block (your existing behavior)
        if (captureLocal == null) {
          state = state.copyWith(
            captureTimestamp: null,
            isWithinMemoryWindow: false,
            uploadSuccess: false,
            errorMessage:
            'Unable to read this photo’s original capture time (EXIF missing/stripped). '
                'Please select a different photo (not edited/screenshot) or export the original.',
          );
          return;
        }
      } else if (isVideo) {
        // Keep existing behavior for video
        if (p == null || p.isEmpty) {
          setError('Unable to access file path');
          return;
        }

        captureLocal = await _extractVideoMetadataLocal(p);
        captureLocal ??= await File(p).lastModified();
      } else {
        // Other types: fall back to lastModified
        if (p == null || p.isEmpty) {
          setError('Unable to access file path');
          return;
        }
        captureLocal = await File(p).lastModified();
      }

      final startLocal = state.memoryStartDate!.toLocal();
      final endLocal = state.memoryEndDate!.toLocal();
      final within = !captureLocal!.isBefore(startLocal) && !captureLocal.isAfter(endLocal);

      if (!within) {
        state = state.copyWith(
          captureTimestamp: captureLocal,
          isWithinMemoryWindow: false,
          uploadSuccess: false,
          errorMessage: 'Please upload a photo or video taken between:',
        );
        return;
      }

      state = state.copyWith(
        captureTimestamp: captureLocal,
        isWithinMemoryWindow: true,
        errorMessage: null,
      );
    } catch (_) {
      setError('Failed to read metadata');
    }
  }

  Future<DateTime?> _extractImageMetadataLocal(String path) async {
    Exif? exif;
    try {
      exif = await Exif.fromPath(path);

      DateTime? dt = await exif.getOriginalDate();

      if (dt == null) {
        final attrs = await exif.getAttributes();

        final candidates = <String?>[
          attrs?['DateTimeOriginal'] as String?,
          attrs?['DateTimeDigitized'] as String?,
          attrs?['DateTime'] as String?,
        ];

        for (final s in candidates) {
          final parsed = _parseExifLikeDateTime(s);
          if (parsed != null) {
            dt = parsed;
            break;
          }
        }
      }

      return dt?.toLocal();
    } catch (_) {
      return null;
    } finally {
      try {
        await exif?.close();
      } catch (_) {}
    }
  }

  DateTime? _parseExifLikeDateTime(String? s) {
    if (s == null) return null;
    final v = s.trim();
    if (v.isEmpty) return null;

    final normalized = v.replaceFirstMapped(
      RegExp(r'^(\d{4}):(\d{2}):(\d{2})'),
          (m) => '${m[1]}-${m[2]}-${m[3]}',
    );

    return DateTime.tryParse(normalized);
  }

  Future<DateTime?> _extractVideoMetadataLocal(String path) async {
    try {
      final stat = await File(path).stat();
      final changed = stat.changed.toLocal();
      final modified = stat.modified.toLocal();
      return changed.isBefore(modified) ? changed : modified;
    } catch (_) {
      return null;
    }
  }

  String _formatReadableDate(DateTime dt) => _readableDate.format(dt.toLocal());
  String _formatReadableDateTime(DateTime dt) =>
      _readableDateTime.format(dt.toLocal());

  Future<int> _computeDurationSeconds({
    required PlatformFile file,
    required bool isImage,
  }) async {
    if (isImage) return 0;

    final p = file.path;
    if (p == null) return 0;

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(p));
      await controller.initialize();
      return controller.value.duration.inSeconds;
    } catch (_) {
      return 0;
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
    }
  }

  Future<void> uploadFile() async {
    if (state.selectedFile == null || state.memoryId == null) {
      setError('Upload prerequisites missing');
      return;
    }

    await validateFileMetadata();
    if (state.isWithinMemoryWindow != true) return;

    state = state.copyWith(isUploading: true);

    File? tempThumb;

    try {
      final client = SupabaseService.instance.client;
      final userId = client?.auth.currentUser?.id;
      if (client == null || userId == null) throw Exception('Not authenticated');

      final pf = state.selectedFile!;
      final path = pf.path;
      if (path == null || path.isEmpty) throw Exception('Invalid file path');

      final name = pf.name.toLowerCase();
      final isImage =
          name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png');
      final isVideo = name.endsWith('.mp4') || name.endsWith('.mov');

      final durationSeconds = await _computeDurationSeconds(
        file: pf,
        isImage: isImage,
      );

      final uploadId = _uuid.v4();

      File uploadFile = File(path);

      // Compress video before upload (now has fast-path skips in VideoCompressionService)
      if (isVideo) {
        final net = await NetworkQualityService.getQuality();
        uploadFile = await VideoCompressionService.compressForNetwork(
          input: uploadFile,
          quality: net,
        );
      }

      final tus = SupabaseTusUploader(client);

      final mediaObjectName = isVideo ? 'stories/$uploadId.mp4' : 'stories/$uploadId.jpg';
      final String? thumbObjectName = isVideo ? 'stories/${uploadId}_thumb.jpg' : null;

      String? uploadedMediaPath;
      String? uploadedThumbPath;

      // ✅ Start media upload immediately (don’t block on thumbnail work)
      final mediaUploadFuture = tus.uploadResumable(
        bucketName: 'story-media',
        objectName: mediaObjectName,
        file: uploadFile,
      ).then((p) {
        uploadedMediaPath = p;
      });

      // ✅ Thumbnail pipeline runs in parallel
      Future<void> thumbFuture = Future.value();
      if (isVideo && thumbObjectName != null) {
        thumbFuture = () async {
          tempThumb = await VideoCompressionService.generateThumbnail(input: uploadFile);

          if (tempThumb != null && await tempThumb!.exists()) {
            final p = await tus.uploadResumable(
              bucketName: 'story-media',
              objectName: thumbObjectName,
              file: tempThumb!,
            );
            uploadedThumbPath = p;
          }
        }();
      }

      await Future.wait([mediaUploadFuture, thumbFuture]);

      if (uploadedMediaPath == null) throw Exception('Upload failed');

      final story = await StoryService().createStory(
        memoryId: state.memoryId!,
        contributorId: userId,
        mediaUrl: uploadedMediaPath!,
        mediaType: isImage ? 'image' : 'video',
        thumbnailUrl: isImage
            ? uploadedMediaPath!
            : (uploadedThumbPath ?? uploadedMediaPath!),
        captureTimestamp: state.captureTimestamp!.toUtc(),
        isFromCameraRoll: true,
        durationSeconds: durationSeconds,
      );

      if (story == null) throw Exception('Story creation failed');

      state = state.copyWith(
        isUploading: false,
        uploadSuccess: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadSuccess: false,
        errorMessage: e.toString(),
      );
    } finally {
      if (tempThumb != null) {
        try {
          await tempThumb!.delete();
        } catch (_) {}
      }
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
