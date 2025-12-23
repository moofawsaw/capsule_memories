import '../core/app_export.dart';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized service for handling avatar URL generation across the app
/// Converts Supabase storage paths to public URLs
class AvatarHelperService {
  static SupabaseClient? get _supabase => SupabaseService.instance.client;

  /// Generates public URL for avatar from storage path
  ///
  /// Handles:
  /// - Empty/null paths → returns empty string
  /// - Already full URLs → returns as-is
  /// - Storage paths → converts to public Supabase storage URL
  static String getAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return '';
    }

    // If it's already a full URL, return as is
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }

    // If it's a storage path, generate public URL
    try {
      if (_supabase != null) {
        // Remove leading slash if present
        final cleanPath =
            avatarPath.startsWith('/') ? avatarPath.substring(1) : avatarPath;

        return _supabase!.storage.from('avatars').getPublicUrl(cleanPath);
      }
    } catch (e) {
      debugPrint('Error generating avatar URL for path "$avatarPath": $e');
    }

    return avatarPath;
  }

  /// Batch process multiple avatar paths to URLs
  /// Useful for fetching multiple user avatars at once
  static List<String> getAvatarUrls(List<String?> avatarPaths) {
    return avatarPaths
        .map((path) => getAvatarUrl(path))
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
