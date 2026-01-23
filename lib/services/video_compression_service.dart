import 'dart:io';

import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

import 'network_quality_service.dart';

class VideoCompressionService {
  // Tune these as you like.
  // Goal: avoid "compression tax" for videos that are already small.
  static const int _mb = 1024 * 1024;

  static Future<File> compressForNetwork({
    required File input,
    required NetworkQuality quality,
  }) async {
    if (!await input.exists()) return input;

    // ✅ FAST PATH: skip compression if file is already small.
    // These thresholds are intentionally conservative to restore "snappy" sharing.
    final int origLen = await input.length();
    if (origLen <= 0) return input;

    // On Wi-Fi, don’t waste time compressing smaller videos.
    if (quality == NetworkQuality.wifi && origLen <= 18 * _mb) {
      return input;
    }

    // On cellular/unknown, still skip if very small.
    if (quality != NetworkQuality.wifi && origLen <= 8 * _mb) {
      return input;
    }

    try {
      VideoQuality q;
      switch (quality) {
        case NetworkQuality.wifi:
          q = VideoQuality.Res1280x720Quality;
          break;
        case NetworkQuality.cellular:
          q = VideoQuality.Res1280x720Quality; // ✅ keep 720p minimum
          break;
        default:
          q = VideoQuality.Res1280x720Quality; // ✅ keep 720p minimum
          break;
      }

      final MediaInfo? info = await VideoCompress.compressVideo(
        input.path,
        quality: q,
        deleteOrigin: false,
        includeAudio: true,
      );

      final String? outPath = info?.path;
      if (outPath == null || outPath.isEmpty) return input;

      final outFile = File(outPath);
      if (!await outFile.exists()) return input;

      final int len = await outFile.length();
      if (len <= 0) return input;

      // ✅ If compression didn't help, keep the original.
      if (len >= origLen) return input;

      return outFile;
    } catch (_) {
      return input;
    } finally {
      // Do not dispose here. Dispose once at app shutdown if needed.
    }
  }

  static Future<File?> generateThumbnail({
    required File input,
    int maxWidth = 400,
    int quality = 75,
    int timeMs = 1000,
  }) async {
    try {
      if (!await input.exists()) return null;

      final tempDir = await getTemporaryDirectory();
      final thumbPath =
          '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await VideoThumbnail.thumbnailFile(
        video: input.path,
        thumbnailPath: thumbPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        quality: quality,
        timeMs: timeMs,
      );

      if (result == null) return null;

      final file = File(result);
      if (!await file.exists()) return null;

      final len = await file.length();
      if (len <= 0) return null;

      return file;
    } catch (_) {
      return null;
    }
  }
}
