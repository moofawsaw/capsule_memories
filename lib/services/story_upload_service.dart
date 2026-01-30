// lib/services/story_upload_service.dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

import 'network_quality_service.dart';
import 'supabase_tus_uploader.dart';
import 'video_compression_service.dart';

class StoryUploadResult {
  StoryUploadResult({
    required this.mediaObjectPath,
    this.thumbnailObjectPath,
    required this.durationSeconds,
  });

  final String mediaObjectPath;
  final String? thumbnailObjectPath;
  final int durationSeconds;
}

class StoryUploadService {
  StoryUploadService({
    required SupabaseClient supabase,
  })  : _supabase = supabase,
        _tus = SupabaseService.instance.sharedTusUploader;

  final SupabaseClient _supabase;
  final SupabaseTusUploader _tus;

  Future<StoryUploadResult> uploadStoryMedia({
    required String bucketName, // "story-media"
    required String folder, // e.g. "stories"
    required String storyId,
    required File mediaFile,
    required String mediaType, // "image" | "video"
    required int durationSeconds,
    void Function(String stage)? onStage,
    void Function(double progress01)? onProgressMedia,
    void Function(double progress01)? onProgressThumb,
  }) async {
    final quality = await NetworkQualityService.getQuality();

    // ✅ Choose chunk size by network (cellular baseline 5MB is usually faster than 3MB)
    const int mb = 1024 * 1024;
    final int chunkSizeBytes = (quality == NetworkQuality.wifi)
        ? SupabaseTusUploader.defaultChunkWifi
        : (5 * mb);

    // ✅ Reasonable per-request timeout
    final requestTimeout = const Duration(seconds: 45);

    File uploadFile = mediaFile;
    File? thumbFile;

    if (mediaType == 'video') {
      // IMPORTANT: handle compression and thumb generation below (section B)
      onStage?.call('Preparing video...');
      // Compression decision is handled by VideoCompressionService, but we also avoid
      // even calling into it when not needed (see B).
// ✅ EXTRA fast guard: avoid even entering compression pipeline if small
      const int mb = 1024 * 1024;
      final origLen = await mediaFile.length();

      // Keep the saved/uploaded video quality consistent across networks.
      // Only compress when the file is notably large.
      final bool shouldTryCompression = origLen > 35 * mb;

      if (shouldTryCompression) {
        uploadFile = await VideoCompressionService.compressForNetwork(
          input: mediaFile,
          quality: quality,
        );
      } else {
        uploadFile = mediaFile;
      }


      onStage?.call('Generating thumbnail...');
      // ✅ Generate thumbnail from ORIGINAL file (usually faster and good enough)
      thumbFile = await VideoCompressionService.generateThumbnail(
        input: mediaFile,
      );
    }

    final ext = p.extension(uploadFile.path).isNotEmpty
        ? p.extension(uploadFile.path)
        : (mediaType == 'video' ? '.mp4' : '.jpg');

    final mediaObjectName = '$folder/$storyId$ext';
    final thumbObjectName =
    thumbFile == null ? null : '$folder/${storyId}_thumb.jpg';

    onStage?.call('Uploading...');

    if (thumbFile != null && thumbObjectName != null) {
      final results = await Future.wait<String>([
        _tus.uploadResumable(
          bucketName: bucketName,
          objectName: thumbObjectName,
          file: thumbFile,
          chunkSizeBytes: chunkSizeBytes,
          requestTimeout: requestTimeout,
          onProgress: onProgressThumb,
        ),
        _tus.uploadResumable(
          bucketName: bucketName,
          objectName: mediaObjectName,
          file: uploadFile,
          chunkSizeBytes: chunkSizeBytes,
          requestTimeout: requestTimeout,
          onProgress: onProgressMedia,
        ),
      ]);

      return StoryUploadResult(
        thumbnailObjectPath: results[0],
        mediaObjectPath: results[1],
        durationSeconds: durationSeconds,
      );
    }

    final mediaPath = await _tus.uploadResumable(
      bucketName: bucketName,
      objectName: mediaObjectName,
      file: uploadFile,
      chunkSizeBytes: chunkSizeBytes,
      requestTimeout: requestTimeout,
      onProgress: onProgressMedia,
    );

    return StoryUploadResult(
      thumbnailObjectPath: null,
      mediaObjectPath: mediaPath,
      durationSeconds: durationSeconds,
    );
  }
}
