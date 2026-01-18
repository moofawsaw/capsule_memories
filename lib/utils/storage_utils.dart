import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageUtils {
  static const String supabaseUrl = 'https://resdvutqgrbbylknaxjp.supabase.co';

  static bool _isFullUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  static String _stripLeadingSlash(String s) =>
      s.startsWith('/') ? s.substring(1) : s;

  static String? resolveStoryMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final raw = path.trim();

    if (_isFullUrl(raw)) return raw;

    String normalized = _stripLeadingSlash(raw);
    if (normalized.startsWith('story-media/')) {
      normalized = normalized.substring('story-media/'.length);
    }

    return Supabase.instance.client.storage
        .from('story-media')
        .getPublicUrl(normalized);
  }

  static String? resolveAvatarUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final raw = path.trim();

    if (_isFullUrl(raw)) return raw;

    String normalized = _stripLeadingSlash(raw);
    if (normalized.startsWith('avatars/')) {
      normalized = normalized.substring('avatars/'.length);
    }

    return Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(normalized);
  }

  /// Accepts:
  /// - Full URL: "https://.../category-icons/graduation.svg"
  /// - Bucket path: "category-icons/graduation.svg" or "/category-icons/graduation.svg"
  /// - File name: "graduation.svg" / "graduation.png"
  /// - Raw name: "graduation"  -> tries .svg then .png fallback (optional)
  /// Always returns a non-null String.
  /// If input is null/empty or resolution fails, returns '' (empty string).
  static String resolveMemoryCategoryIconUrl(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final raw = value.trim();

    if (_isFullUrl(raw)) return raw;

    String normalized = _stripLeadingSlash(raw);

    // If DB stored "category-icons/....", strip the bucket prefix
    if (normalized.startsWith('category-icons/')) {
      normalized = normalized.substring('category-icons/'.length);
    }

    final lower = normalized.toLowerCase();
    final hasExt = lower.endsWith('.svg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');

    // If it already has an extension, use it as-is
    if (hasExt) {
      return Supabase.instance.client.storage
          .from('category-icons')
          .getPublicUrl(normalized);
    }

    // Default strategy: SVG-first
    return Supabase.instance.client.storage
        .from('category-icons')
        .getPublicUrl('$normalized.svg');
  }


  /// Upload media file to Supabase storage
  /// Returns the path of the uploaded file or null if upload fails
  static Future<String?> uploadMedia({
    required PlatformFile file,
    required String bucket,
    required String folder,
  }) async {
    try {
      final filePath = file.path;
      if (filePath == null) {
        throw Exception('File path is null');
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(file.name);
      final fileName = '${timestamp}_${file.name}';
      final storagePath = '$folder/$fileName';

      // Read file bytes
      final fileBytes = await File(filePath).readAsBytes();

      // Upload to Supabase storage
      final uploadPath =
          await Supabase.instance.client.storage.from(bucket).uploadBinary(
                storagePath,
                fileBytes,
                fileOptions: FileOptions(
                  contentType: _getContentType(fileExtension),
                ),
              );

      // Return the storage path
      return uploadPath;
    } catch (e) {
      print('Error uploading media: $e');
      return null;
    }
  }

  /// Determine content type based on file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }
}
