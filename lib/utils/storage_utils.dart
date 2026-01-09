import 'package:supabase_flutter/supabase_flutter.dart';

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

    return Supabase.instance.client.storage.from('avatars').getPublicUrl(normalized);
  }

  /// Accepts:
  /// - Full URL: "https://.../category-icons/graduation.svg"
  /// - Bucket path: "category-icons/graduation.svg" or "/category-icons/graduation.svg"
  /// - File name: "graduation.svg" / "graduation.png"
  /// - Raw name: "graduation"  -> tries .svg then .png fallback (optional)
  static String? resolveMemoryCategoryIconUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();

    if (_isFullUrl(raw)) return raw;

    String normalized = _stripLeadingSlash(raw);

    // If DB stored "category-icons/....", strip the bucket prefix
    if (normalized.startsWith('category-icons/')) {
      normalized = normalized.substring('category-icons/'.length);
    }

    // If it already has an extension, use it as-is
    final lower = normalized.toLowerCase();
    final hasExt = lower.endsWith('.svg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');

    if (hasExt) {
      return Supabase.instance.client.storage
          .from('category-icons')
          .getPublicUrl(normalized);
    }

    // Default strategy: SVG-first (swap if your bucket is mostly PNG)
    return Supabase.instance.client.storage
        .from('category-icons')
        .getPublicUrl('$normalized.svg');
  }
}
