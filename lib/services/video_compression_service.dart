import 'dart:io';

import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

import 'network_quality_service.dart';

class VideoCompressionService {
  // Tune these as you like.
  // Goal: avoid "compression tax" for videos that are already small.
  static const int _mb = 1024 * 1024;
  static const int _compressThresholdBytes = 35 * _mb;

  static Future<File> compressForNetwork({
    required File input,
    required NetworkQuality quality,
  }) async {
    if (!await input.exists()) return input;

    // ✅ FAST PATH: skip compression if file is already small.
    // We keep media quality consistent across cellular + Wi‑Fi.
    final int origLen = await input.length();
    if (origLen <= 0) return input;

    // Only compress when the file is notably large.
    if (origLen <= _compressThresholdBytes) {
      return input;
    }

    try {
      // If we do compress, use a predictable setting.
      final VideoQuality q = VideoQuality.Res1280x720Quality;

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
