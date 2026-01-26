// lib/services/story_service.dart

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import './avatar_helper_service.dart';
import './location_service.dart';
import './supabase_service.dart';

class StoryService {
  final SupabaseClient? _supabase = SupabaseService.instance.client;

  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  bool _isMissingColumn(PostgrestException e, String columnName) {
    final msg = (e.message).toLowerCase();
    final details = (e.details ?? '').toString().toLowerCase();
    final hint = (e.hint ?? '').toString().toLowerCase();
    final code = (e.code ?? '').toString();
    final col = columnName.toLowerCase();

    if (code == '42703') return true;
    if (msg.contains('column') && msg.contains(col) && msg.contains('does not exist')) return true;
    if (details.contains('column') && details.contains(col) && details.contains('does not exist')) {
      return true;
    }
    if (hint.contains('column') && hint.contains(col) && hint.contains('does not exist')) return true;
    return false;
  }

  static String? resolveStoryMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    String normalized = path;
    if (normalized.startsWith('/')) normalized = normalized.substring(1);
    if (normalized.startsWith('story-media/')) {
      normalized = normalized.substring(12);
    }

    return SupabaseService.instance.client?.storage
        .from('story-media')
        .getPublicUrl(normalized);
  }

  Future<List<Map<String, dynamic>>> fetchUserStories(
      String userId, {
        bool onlyLast24Hours = true,
      }) async {
    return await _retryOperation(
          () => _fetchUserStoriesInternal(
        userId,
        onlyLast24Hours: onlyLast24Hours,
      ),
      'fetch user stories',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserStoriesInternal(
      String userId, {
        required bool onlyLast24Hours,
      }) async {
    final supabase = _supabase;
    if (supabase == null) return [];

    try {
      final creatorMemories =
      await supabase.from('memories').select('id').eq('creator_id', userId);

      final contributorMemories = await supabase
          .from('memory_contributors')
          .select('memory_id')
          .eq('user_id', userId);

      final memoryIds = <String>{
        ...(creatorMemories as List).map((m) => m['id'] as String).toList(),
        ...(contributorMemories as List)
            .map((m) => m['memory_id'] as String)
            .toList(),
      }.toList();

      if (memoryIds.isEmpty) return [];

      PostgrestFilterBuilder<List<dynamic>> query =
          supabase.from('stories').select('''
            id,
            memory_id,
            contributor_id,
            image_url,
            video_url,
            thumbnail_url,
            media_type,
            created_at,
            capture_timestamp,
            duration_seconds,
            location_name,
            user_profiles!stories_contributor_id_fkey (
              id,
              display_name,
              avatar_url,
              username
            ),
            memories!inner (
              id,
              title,
              visibility,
              creator_id,
              state
            )
          ''')
          .inFilter('memory_id', memoryIds)
          // Hide private Daily Capsule stories from general story surfaces
          .eq('memories.is_daily_capsule', false);

      if (onlyLast24Hours) {
        query = query.gte(
          'created_at',
          DateTime.now()
              .subtract(const Duration(hours: 24))
              .toIso8601String(),
        );
      }

      try {
        final response = await query.order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response as List? ?? []);
      } on PostgrestException catch (e) {
        // Backward-compat: if migration not applied yet, retry without daily capsule filter.
        if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
        var fallback = supabase.from('stories').select('''
            id,
            memory_id,
            contributor_id,
            image_url,
            video_url,
            thumbnail_url,
            media_type,
            created_at,
            capture_timestamp,
            duration_seconds,
            location_name,
            user_profiles!stories_contributor_id_fkey (
              id,
              display_name,
              avatar_url,
              username
            ),
            memories!inner (
              id,
              title,
              visibility,
              creator_id,
              state
            )
          ''').inFilter('memory_id', memoryIds);

        if (onlyLast24Hours) {
          fallback = fallback.gte(
            'created_at',
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .toIso8601String(),
          );
        }
        final response = await fallback.order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response as List? ?? []);
      }
    } catch (e) {
      print('❌ STORY SERVICE: Error fetching user stories: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchStoriesByAuthor(String userId) async {
    return await _retryOperation(
          () => _fetchStoriesByAuthorInternal(userId),
      'fetch stories by author',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStoriesByAuthorInternal(
      String userId,
      ) async {
    try {
      try {
        final response = await _supabase
          ?.from('stories')
          .select('''
          id,
          memory_id,
          contributor_id,
          image_url,
          video_url,
          thumbnail_url,
          media_type,
          created_at,
          capture_timestamp,
          duration_seconds,
          location_name,
          user_profiles_public!stories_contributor_id_fkey (
            id,
            display_name,
            avatar_url,
            username
          ),
          memories!inner (
            id,
            title,
            visibility,
            state,
            creator_id,
            category_id,
            memory_categories (
              name,
              icon_name,
              icon_url
            )
          )
        ''')
          .eq('contributor_id', userId)
          .eq('memories.visibility', 'public')
          .eq('memories.is_daily_capsule', false)
          .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response as List? ?? []);
      } on PostgrestException catch (e) {
        if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
        final response = await _supabase
            ?.from('stories')
            .select('''
          id,
          memory_id,
          contributor_id,
          image_url,
          video_url,
          thumbnail_url,
          media_type,
          created_at,
          capture_timestamp,
          duration_seconds,
          location_name,
          user_profiles_public!stories_contributor_id_fkey (
            id,
            display_name,
            avatar_url,
            username
          ),
          memories!inner (
            id,
            title,
            visibility,
            state,
            creator_id,
            category_id,
            memory_categories (
              name,
              icon_name,
              icon_url
            )
          )
        ''')
            .eq('contributor_id', userId)
            .eq('memories.visibility', 'public')
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response as List? ?? []);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserTimelines(String userId) async {
    return await _retryOperation(
          () => _fetchUserTimelinesInternal(userId),
      'fetch user timelines',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserTimelinesInternal(
      String userId,
      ) async {
    try {
      final contributorMemoryIds = await _supabase
          ?.from('memory_contributors')
          .select('memory_id')
          .eq('user_id', userId);

      final contributorIds = (contributorMemoryIds as List?)
          ?.map((m) => m['memory_id'] as String)
          .toList() ??
          [];

      try {
        final response = await _supabase?.from('memories').select('''
            id,
            title,
            visibility,
            state,
            created_at,
            expires_at,
            sealed_at,
            start_time,
            end_time,
            location_name,
            location_lat,
            location_lng,
            contributor_count,
            creator_id,
            duration,
            memory_categories (
              name,
              icon_name,
              icon_url
            ),
            user_profiles!memories_creator_id_fkey (
              id,
              display_name,
              avatar_url,
              username
            ),
            stories (
              id,
              thumbnail_url,
              image_url,
              video_url,
              media_type
            )
          ''')
          .eq('is_daily_capsule', false)
          .or(
        'creator_id.eq.$userId${contributorIds.isNotEmpty ? ',id.in.(${contributorIds.join(",")})' : ''}',
      );

        return List<Map<String, dynamic>>.from(response as List? ?? []);
      } on PostgrestException catch (e) {
        if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
        final response = await _supabase?.from('memories').select('''
            id,
            title,
            visibility,
            state,
            created_at,
            expires_at,
            sealed_at,
            start_time,
            end_time,
            location_name,
            location_lat,
            location_lng,
            contributor_count,
            creator_id,
            duration,
            memory_categories (
              name,
              icon_name,
              icon_url
            ),
            user_profiles!memories_creator_id_fkey (
              id,
              display_name,
              avatar_url,
              username
            ),
            stories (
              id,
              thumbnail_url,
              image_url,
              video_url,
              media_type
            )
          ''').or(
          'creator_id.eq.$userId${contributorIds.isNotEmpty ? ',id.in.(${contributorIds.join(",")})' : ''}',
        );

        return List<Map<String, dynamic>>.from(response as List? ?? []);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMemoryStories(String memoryId) async {
    return await _retryOperation(
          () => _fetchMemoryStoriesInternal(memoryId),
      'fetch memory stories',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMemoryStoriesInternal(
      String memoryId,
      ) async {
    try {
      final response = await _supabase?.from('stories').select('''
      id,
      memory_id,
      contributor_id,
      media_type,
      image_url,
      video_url,
      thumbnail_url,
      created_at,
      capture_timestamp,
      duration_seconds,
      location_name,
      location_lat,
      location_lng,
      is_from_camera_roll,
      background_music,
      text_overlays,
      stickers,
      drawings,
      view_count,
      user_profiles_public!stories_contributor_id_fkey (
        id,
        username,
        display_name,
        avatar_url
      )
    ''').eq('memory_id', memoryId).order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List? ?? []);
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ FIXED:
  /// - Collect coords BEFORE insert (so first post can include location)
  /// - Optional best-effort reverse geocode BEFORE insert (short timeout)
  /// - NO background location backfill (prevents iOS prompting AFTER post)
  Future<Map<String, dynamic>?> createStory({
    required String memoryId,
    required String contributorId,
    required String mediaUrl,
    required String mediaType,
    String? thumbnailUrl,
    String? caption,
    required int durationSeconds,
    DateTime? captureTimestamp,
    bool isFromCameraRoll = false,

    // Keep the param for compatibility, but default it OFF to avoid post-submit prompts.
    bool backfillLocationAsync = false,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase client is null (not initialized)');
    }

    try {
      final nowUtc = DateTime.now().toUtc();
      final captureUtc = (captureTimestamp ?? nowUtc).toUtc();

      // ✅ Coords first (this is what triggers iOS permission prompt, and it happens BEFORE insert)
      Map<String, dynamic>? coords;
      try {
        coords = await LocationService.getCoordsOnly(
          timeout: const Duration(seconds: 3),
        );
      } catch (_) {
        coords = null;
      }

      final double? lat = (coords?['latitude'] as num?)?.toDouble();
      final double? lng = (coords?['longitude'] as num?)?.toDouble();

      // ✅ Best-effort name (does not cause permission prompt; uses coords)
      String? locationName;
      if (lat != null && lng != null) {
        try {
          locationName = await LocationService.getLocationNameBestEffort(
            lat,
            lng,
            timeout: const Duration(seconds: 6),
          );
        } catch (_) {
          locationName = null;
        }
      }

      final storyData = <String, dynamic>{
        'memory_id': memoryId,
        'contributor_id': contributorId,
        'image_url': mediaType == 'image' ? mediaUrl : null,
        'video_url': mediaType == 'video' ? mediaUrl : null,
        'thumbnail_url': thumbnailUrl,
        'media_type': mediaType,

        // ✅ Insert with location (first post has it if permission granted)
        'location_lat': lat,
        'location_lng': lng,
        'location_name': locationName,

        'created_at': nowUtc.toIso8601String(),
        'capture_timestamp': captureUtc.toIso8601String(),
        'is_from_camera_roll': isFromCameraRoll,
        'duration_seconds': durationSeconds,
        'text_overlays': caption != null ? [{'text': caption}] : [],
      };

      final inserted = await _supabase.from('stories').insert(storyData).select('''
        id,
        contributor_id,
        memory_id,
        created_at,
        capture_timestamp,
        location_name,
        location_lat,
        location_lng
      ''').single();

      final insertedMap = Map<String, dynamic>.from(inserted);

      // 🚫 Intentionally do NOT do background location fetch here.
      // This prevents iOS from prompting after the post completes.

      // If you still want async backfill, it MUST NOT request permission after insert.
      // Only safe if you pass lat/lng from earlier and ONLY reverse-geocode.
      if (backfillLocationAsync) {
        final storyId = insertedMap['id']?.toString();
        if (storyId != null &&
            storyId.isNotEmpty &&
            (locationName == null || locationName.trim().isEmpty) &&
            lat != null &&
            lng != null) {
          // Reverse geocode only; no permission request here.
          unawaited(_backfillStoryLocationNameOnly(storyId, lat, lng));
        }
      }

      return insertedMap;
    } on PostgrestException catch (e) {
      final parts = <String>[];

      if (e.message.isNotEmpty) parts.add('message=${e.message}');
      final details = e.details;
      if (details is String && details.isNotEmpty) parts.add('details=$details');
      final hint = e.hint;
      if (hint is String && hint.isNotEmpty) parts.add('hint=$hint');
      final code = e.code;
      if (code is String && code.isNotEmpty) parts.add('code=$code');

      final errorText = parts.isNotEmpty ? parts.join(' | ') : 'unknown error';
      throw Exception('Create story failed ($errorText)');
    }
  }

  /// ✅ SAFE background backfill:
  /// - DOES NOT request location permission
  /// - DOES NOT call getCoordsOnly / getCurrentLocation
  /// - ONLY reverse-geocodes using provided lat/lng, then updates location_name
  Future<void> _backfillStoryLocationNameOnly(
      String storyId,
      double lat,
      double lng,
      ) async {
    try {
      final name = await LocationService.getLocationNameBestEffort(
        lat,
        lng,
        timeout: const Duration(seconds: 6),
      );

      if (name == null || name.trim().isEmpty) return;

      await _supabase!.from('stories').update({
        'location_name': name,
      }).eq('id', storyId);

      print('✅ Backfilled story location_name for $storyId: $name');
    } catch (e) {
      print('⚠️ Backfill location_name failed for $storyId: $e');
    }
  }

  Future<T> _retryOperation<T>(
      Future<T> Function() operation,
      String operationName,
      ) async {
    int attempt = 0;
    Duration delay = _initialRetryDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= _maxRetries) rethrow;

        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  String getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
    } else {
      return 'just now';
    }
  }

  String getStoryMediaUrl(Map<String, dynamic> story) {
    if (story['thumbnail_url'] != null &&
        (story['thumbnail_url'] as String).isNotEmpty) {
      return resolveStoryMediaUrl(story['thumbnail_url'] as String) ?? '';
    }

    if (story['media_type'] == 'video' && story['video_url'] != null) {
      return resolveStoryMediaUrl(story['video_url'] as String) ?? '';
    } else if (story['image_url'] != null) {
      return resolveStoryMediaUrl(story['image_url'] as String) ?? '';
    }

    return '';
  }

  String getContributorAvatar(Map<String, dynamic> story) {
    final contributor = (story['user_profiles_public'] as Map<String, dynamic>?) ??
        (story['user_profiles'] as Map<String, dynamic>?);

    final avatarUrl = contributor?['avatar_url'] as String?;
    return AvatarHelperService.getAvatarUrl(avatarUrl);
  }

  String getMemoryThumbnail(Map<String, dynamic> memory) {
    final stories = memory['stories'] as List?;
    if (stories != null && stories.isNotEmpty) {
      final latestStory = stories.first;

      if (latestStory['thumbnail_url'] != null) {
        final thumbnailPath = latestStory['thumbnail_url'] as String;

        if (!thumbnailPath.startsWith('http://') &&
            !thumbnailPath.startsWith('https://')) {
          final supabaseService = SupabaseService.instance;
          return supabaseService.getStorageUrl(thumbnailPath) ?? thumbnailPath;
        }

        return thumbnailPath;
      } else if (latestStory['image_url'] != null) {
        final imagePath = latestStory['image_url'] as String;

        if (!imagePath.startsWith('http://') &&
            !imagePath.startsWith('https://')) {
          final supabaseService = SupabaseService.instance;
          return supabaseService.getStorageUrl(imagePath) ?? imagePath;
        }

        return imagePath;
      }
    }
    return '';
  }

  String getMemoryStateLabel(String state) {
    switch (state) {
      case 'open':
        return 'Live';
      case 'sealed':
        return 'Sealed';
      default:
        return 'Unknown';
    }
  }

  bool isMemorySealed(Map<String, dynamic> memory) {
    return memory['state'] == 'sealed';
  }

  Future<bool> deleteStory(String storyId) async {
    if (_supabase == null) return false;

    return await _retryOperation(
          () => _deleteStoryInternal(storyId),
      'delete story',
    );
  }

  Future<bool> _deleteStoryInternal(String storyId) async {
    try {
      await _supabase?.from('stories').delete().eq('id', storyId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchStoryDetails(String storyId) async {
    if (_supabase == null) return null;

    try {
      final response = await _supabase.from('stories').select('''
            id,
            image_url,
            video_url,
            media_type,
            thumbnail_url,
            text_overlays,
            location_name,
            created_at,
            view_count,
            contributor_id,
            user_profiles!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              username
            )
          ''').eq('id', storyId).eq('is_disabled', false).single();

      final contributor =
          (response['user_profiles_public'] as Map<String, dynamic>?) ??
              (response['user_profiles'] as Map<String, dynamic>?);

      final textOverlays = response['text_overlays'] as List? ?? [];

      String? caption;
      if (textOverlays.isNotEmpty && textOverlays[0] is Map) {
        caption = (textOverlays[0] as Map)['text'] as String?;
      }

      final mediaType = response['media_type'] as String? ?? 'image';
      final supabaseService = SupabaseService.instance;
      String mediaUrl = '';

      if (mediaType == 'video') {
        final videoPath =
        (response['video_url'] ?? response['thumbnail_url'] ?? '') as String;

        if (videoPath.isNotEmpty &&
            !videoPath.startsWith('http://') &&
            !videoPath.startsWith('https://')) {
          mediaUrl = supabaseService.getStorageUrl(videoPath) ?? videoPath;
        } else {
          mediaUrl = videoPath;
        }
      } else {
        final imagePath =
        (response['image_url'] ?? response['thumbnail_url'] ?? '') as String;

        if (imagePath.isNotEmpty &&
            !imagePath.startsWith('http://') &&
            !imagePath.startsWith('https://')) {
          mediaUrl = supabaseService.getStorageUrl(imagePath) ?? imagePath;
        } else {
          mediaUrl = imagePath;
        }
      }

      return {
        'media_url': mediaUrl,
        'media_type': mediaType,
        'user_name': contributor?['display_name'] ?? 'Unknown User',
        'user_avatar': AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'],
        ),
        'created_at': response['created_at'] ?? '',
        'location': response['location_name'],
        'caption': caption,
        'view_count': response['view_count'] ?? 0,
      };
    } catch (e) {
      return null;
    }
  }

  // ignore: unused_element
  DateTime _calculateExpirationTime(String duration) {
    final now = DateTime.now();
    switch (duration) {
      case '24_hours':
        return now.add(const Duration(hours: 24));
      case '12_hours':
        return now.add(const Duration(hours: 12));
      default:
        return now.add(const Duration(hours: 12));
    }
  }
}