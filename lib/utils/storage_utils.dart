import 'package:supabase_flutter/supabase_flutter.dart';

/// Storage utility for resolving Supabase Storage URLs
/// Handles conversion of raw database paths to full Supabase Storage URLs
class StorageUtils {
  static const String supabaseUrl = 'https://resdvutqgrbbylknaxjp.supabase.co';

  /// Resolves story media URL from raw database path to full Supabase Storage URL
  ///
  /// Returns null for null/empty paths
  /// Returns full URLs unchanged
  /// Resolves relative paths to full Supabase Storage URLs
  static String? resolveStoryMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;

    // Already a full URL - return as-is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Normalize: strip leading slash or bucket prefix
    String normalized = path;
    if (normalized.startsWith('/')) normalized = normalized.substring(1);
    if (normalized.startsWith('story-media/')) {
      normalized = normalized.substring('story-media/'.length);
    }

    // Use Supabase client to get public URL
    return Supabase.instance.client.storage
        .from('story-media')
        .getPublicUrl(normalized);
  }

  /// Resolves avatar URL from raw database path to full Supabase Storage URL
  ///
  /// Returns null for null/empty paths
  /// Returns full URLs unchanged
  /// Resolves relative paths to full Supabase Storage URLs
  static String? resolveAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;

    // Already a full URL - return as-is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Normalize: strip leading slash or bucket prefix
    String normalized = path;
    if (normalized.startsWith('/')) normalized = normalized.substring(1);
    if (normalized.startsWith('avatars/')) {
      normalized = normalized.substring('avatars/'.length);
    }

    // Use Supabase client to get public URL
    return Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(normalized);
  }

  /// Resolves category icon URL from icon_name to full Supabase Storage URL
  ///
  /// Returns null for null/empty icon names
  /// Constructs proper path for category-icons bucket
  ///
  /// Example: resolveMemoryCategoryIconUrl('graduation')
  /// → https://resdvutqgrbbylknaxjp.supabase.co/storage/v1/object/public/category-icons/graduation.svg
  static String? resolveMemoryCategoryIconUrl(String? iconName) {
    if (iconName == null || iconName.isEmpty) return null;

    // Normalize: remove any path separators or file extensions
    String normalized = iconName.replaceAll('/', '').replaceAll('.svg', '');

    // Construct full path with .svg extension
    String path = '$normalized.svg';

    // Use Supabase client to get public URL from category-icons bucket
    return Supabase.instance.client.storage
        .from('category-icons')
        .getPublicUrl(path);
  }
}
