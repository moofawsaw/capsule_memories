import 'dart:io';

import 'package:video_compress/video_compress.dart';

import 'network_quality_service.dart';

class VideoCompressorService {
  /// Compresses a video and returns the compressed File.
  /// If compression fails, returns the original file.
  static Future<File> compressVideoIfNeeded({
    required File input,
    required NetworkQuality quality,
  }) async {
    try {
      // Map network quality to a compression preset.
      // You can tune these later, but this is a strong starting point.
      final VideoQuality preset;
      switch (quality) {
        case NetworkQuality.wifi:
          preset = VideoQuality.Res960x540Quality; // moderate; change to higher if desired
          break;
        case NetworkQuality.cellularFast:
          preset = VideoQuality.Res640x480Quality;
          break;
        case NetworkQuality.cellularSlow:
          preset = VideoQuality.LowQuality;
          break;
        case NetworkQuality.unknown:
          preset = VideoQuality.Res640x480Quality;
          break;
      }

      final info = await VideoCompress.compressVideo(
        input.path,
        quality: preset,
        deleteOrigin: false,
        includeAudio: true,
      );

      final file = info?.file;
      if (file == null) return input;

      return file;
    } catch (_) {
      return input;
    } finally {
      // Keep VideoCompress internal state tidy
      try {
        await VideoCompress.deleteAllCache();
      } catch (_) {}
    }
  }

  static Future<File?> generateThumbnail({
    required File input,
  }) async {
    try {
      final thumbFile = await VideoCompress.getFileThumbnail(
        input.path,
        quality: 60,
        position: -1,
      );
      return thumbFile;
    } catch (_) {
      return null;
    }
  }
}