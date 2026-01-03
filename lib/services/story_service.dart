import './supabase_service.dart';
import './avatar_helper_service.dart';

class StoryService {
  final _supabase = SupabaseService.instance.client;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  /// Fetch stories ONLY from memories where user is a participant (creator or contributor)
  /// Uses explicit memory filtering to ensure user access with automatic retry
  Future<List<Map<String, dynamic>>> fetchUserStories(String userId) async {
    return await _retryOperation(
      () => _fetchUserStoriesInternal(userId),
      'fetch user stories',
    );
  }

  /// Internal implementation of fetchUserStories with retry support
  Future<List<Map<String, dynamic>>> _fetchUserStoriesInternal(
      String userId) async {
    try {
      print('🔍 STORY SERVICE: Fetching stories for userId: $userId');

      // CRITICAL FIX: Get all memory IDs where user is a contributor
      // This ensures we fetch stories from ALL memories the user is a member of
      final contributorMemoryIds = await _supabase
          ?.from('memory_contributors')
          .select('memory_id')
          .eq('user_id', userId);

      final memoryIds = (contributorMemoryIds as List?)
              ?.map((m) => m['memory_id'] as String)
              .toList() ??
          [];

      print(
          '🔍 STORY SERVICE: User is contributor in ${memoryIds.length} memories');

      // If user is not a contributor in any memories, return empty list
      if (memoryIds.isEmpty) {
        print('⚠️ STORY SERVICE: User is not a contributor in any memories');
        return [];
      }

      // FIXED: Fetch stories from ALL memories where user is a contributor
      // This replaces the old .eq('contributor_id', userId) filter
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
          .inFilter('memory_id',
              memoryIds) // FIXED: Changed .in_() to .inFilter() for correct postgrest syntax
          .order('created_at', ascending: false);

      final stories = List<Map<String, dynamic>>.from(response as List? ?? []);

      print(
          '✅ STORY SERVICE: Fetched ${stories.length} stories from ${memoryIds.length} memories user is part of');

      // Enhanced logging for debugging thumbnail display and category info
      for (var story in stories) {
        final memory = story['memories'] as Map<String, dynamic>?;
        final category = memory?['memory_categories'] as Map<String, dynamic>?;
        print('📸 Story ${story['id']}: '
            'memory_id=${story['memory_id']}, '
            'memory_title=${memory?['title']}, '
            'memory_visibility=${memory?['visibility']}, '
            'category_name=${category?['name']}, '
            'category_icon=${category?['icon_name']}, '
            'media_type=${story['media_type']}, '
            'thumbnail_url=${story['thumbnail_url']}, '
            'contributor=${story['user_profiles']?['display_name']}');
      }

      return stories;
    } catch (e) {
      print('❌ Error fetching user stories: $e');
      rethrow;
    }
  }

  /// Fetch stories ONLY authored by a specific user (for user profile pages)
  /// Filters stories where user is the actual contributor, not just a memory participant
  /// CRITICAL FIX: Now filters for PUBLIC memories only to show on user profiles
  Future<List<Map<String, dynamic>>> fetchStoriesByAuthor(String userId) async {
    return await _retryOperation(
      () => _fetchStoriesByAuthorInternal(userId),
      'fetch stories by author',
    );
  }

  /// Internal implementation of fetchStoriesByAuthor with retry support
  Future<List<Map<String, dynamic>>> _fetchStoriesByAuthorInternal(
      String userId) async {
    try {
      print(
          '🔍 STORY SERVICE: Fetching PUBLIC stories authored by userId: $userId');

      // CRITICAL: Filter stories by contributor_id AND public memory visibility
      // This ensures only stories from public memories are shown on user profiles
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
          .eq('memories.visibility',
              'public') // CRITICAL: Filter for public memories only
          .order('created_at', ascending: false);

      final stories = List<Map<String, dynamic>>.from(response as List? ?? []);

      print(
          '✅ STORY SERVICE: Fetched ${stories.length} PUBLIC stories authored by user $userId');

      // Enhanced logging for debugging
      for (var story in stories) {
        final memory = story['memories'] as Map<String, dynamic>?;
        final category = memory?['memory_categories'] as Map<String, dynamic>?;
        print('📸 Story ${story['id']}: '
            'memory_id=${story['memory_id']}, '
            'memory_title=${memory?['title']}, '
            'memory_visibility=${memory?['visibility']}, '
            'category_name=${category?['name']}, '
            'media_type=${story['media_type']}, '
            'contributor=${story['user_profiles']?['display_name']}');
      }

      return stories;
    } catch (e) {
      print('❌ Error fetching stories by author: $e');
      rethrow;
    }
  }

  /// Fetch timeline cards (memories) where user is associated with automatic retry
  Future<List<Map<String, dynamic>>> fetchUserTimelines(String userId) async {
    return await _retryOperation(
      () => _fetchUserTimelinesInternal(userId),
      'fetch user timelines',
    );
  }

  /// Internal implementation of fetchUserTimelines with retry support
  Future<List<Map<String, dynamic>>> _fetchUserTimelinesInternal(
      String userId) async {
    try {
      // Step 1: Get memory IDs from memory_contributors
      final contributorMemoryIds = await _supabase
          ?.from('memory_contributors')
          .select('memory_id')
          .eq('user_id', userId);

      final contributorIds = (contributorMemoryIds as List?)
              ?.map((m) => m['memory_id'] as String)
              .toList() ??
          [];

      // Step 2: Query memories where user is creator OR in contributor list
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
          ''').or('creator_id.eq.$userId${contributorIds.isNotEmpty ? ',id.in.(${contributorIds.join(",")})' : ''}');

      return List<Map<String, dynamic>>.from(response as List? ?? []);
    } catch (e) {
      print('Error fetching user timelines: $e');
      rethrow;
    }
  }

  /// Fetch stories for a specific memory with automatic retry
  Future<List<Map<String, dynamic>>> fetchMemoryStories(String memoryId) async {
    return await _retryOperation(
      () => _fetchMemoryStoriesInternal(memoryId),
      'fetch memory stories',
    );
  }

  /// Internal implementation of fetchMemoryStories with retry support
  Future<List<Map<String, dynamic>>> _fetchMemoryStoriesInternal(
      String memoryId) async {
    try {
      print('🔍 STORY SERVICE: Fetching stories for memory: $memoryId');

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
            user_profiles!stories_contributor_id_fkey (
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('memory_id', memoryId).order('created_at', ascending: false);

      print(
          '🔍 STORY SERVICE: Fetched ${(response as List).length} stories for memory $memoryId');

      return List<Map<String, dynamic>>.from(response as List? ?? []);
    } catch (e) {
      print('❌ STORY SERVICE: Error fetching memory stories: $e');
      rethrow;
    }
  }

  /// Retry operation with exponential backoff for transient Supabase errors
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

        if (attempt >= _maxRetries) {
          print(
              '❌ STORY SERVICE: Failed to $operationName after $attempt attempts: $e');
          rethrow;
        }

        print(
            '⚠️ STORY SERVICE: Attempt $attempt to $operationName failed: $e');
        print('🔄 STORY SERVICE: Retrying in ${delay.inMilliseconds}ms...');

        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }

  /// Calculate relative time ago string
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

  /// Get story media URL (prioritize video over image)
  /// FIXED: Now resolves relative paths to full Supabase Storage URLs
  String getStoryMediaUrl(Map<String, dynamic> story) {
    final supabaseService = SupabaseService.instance;

    // CRITICAL FIX: Prioritize thumbnail for story card previews to match /feed behavior
    // Story cards should ALWAYS show thumbnails, not full-resolution media
    if (story['thumbnail_url'] != null &&
        (story['thumbnail_url'] as String).isNotEmpty) {
      final thumbnailPath = story['thumbnail_url'] as String;

      // Check if already a full URL (starts with http:// or https://)
      if (thumbnailPath.startsWith('http://') ||
          thumbnailPath.startsWith('https://')) {
        return thumbnailPath;
      }

      // Otherwise, resolve relative path using Supabase Storage
      return supabaseService.getStorageUrl(thumbnailPath) ?? thumbnailPath;
    }

    // Fallback to full media URLs only if thumbnail is missing
    if (story['media_type'] == 'video' && story['video_url'] != null) {
      final videoPath = story['video_url'] as String;

      // Check if already a full URL
      if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
        return videoPath;
      }

      // Resolve relative path
      return supabaseService.getStorageUrl(videoPath) ?? videoPath;
    } else if (story['image_url'] != null) {
      final imagePath = story['image_url'] as String;

      // Check if already a full URL
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return imagePath;
      }

      // Resolve relative path
      return supabaseService.getStorageUrl(imagePath) ?? imagePath;
    }

    return '';
  }

  /// Get contributor profile image
  String getContributorAvatar(Map<String, dynamic> story) {
    final contributor = story['user_profiles'];
    if (contributor != null && contributor['avatar_url'] != null) {
      final avatarPath = contributor['avatar_url'] as String;

      // Resolve avatar URL if it's a relative path
      if (!avatarPath.startsWith('http://') &&
          !avatarPath.startsWith('https://')) {
        final supabaseService = SupabaseService.instance;
        return supabaseService.getStorageUrl(avatarPath, bucket: 'avatars') ??
            avatarPath;
      }

      return avatarPath;
    }
    return '';
  }

  /// Get memory thumbnail from latest story
  String getMemoryThumbnail(Map<String, dynamic> memory) {
    final stories = memory['stories'] as List?;
    if (stories != null && stories.isNotEmpty) {
      final latestStory = stories.first;

      if (latestStory['thumbnail_url'] != null) {
        final thumbnailPath = latestStory['thumbnail_url'] as String;

        // Resolve thumbnail URL if it's a relative path
        if (!thumbnailPath.startsWith('http://') &&
            !thumbnailPath.startsWith('https://')) {
          final supabaseService = SupabaseService.instance;
          return supabaseService.getStorageUrl(thumbnailPath) ?? thumbnailPath;
        }

        return thumbnailPath;
      } else if (latestStory['image_url'] != null) {
        final imagePath = latestStory['image_url'] as String;

        // Resolve image URL if it's a relative path
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

  /// Get memory state label
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

  /// Check if memory is sealed
  bool isMemorySealed(Map<String, dynamic> memory) {
    return memory['state'] == 'sealed';
  }

  /// Fetch individual story details for story viewer
  /// Returns actual media URLs (video_url or image_url) based on media_type
  Future<Map<String, dynamic>?> fetchStoryDetails(String storyId) async {
    if (_supabase == null) return null;

    try {
      print('🔍 STORY SERVICE: Fetching story details for: $storyId');

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

      final contributor = response['user_profiles'] as Map<String, dynamic>?;
      final textOverlays = response['text_overlays'] as List? ?? [];

      // Extract caption from text overlays
      String? caption;
      if (textOverlays.isNotEmpty && textOverlays[0] is Map) {
        caption = textOverlays[0]['text'] as String?;
      }

      // CRITICAL: Get the correct FULL-RESOLUTION media URL based on media_type
      // This is for story VIEWING, not story card thumbnails
      final mediaType = response['media_type'] as String? ?? 'image';
      final supabaseService = SupabaseService.instance;
      String mediaUrl = '';

      if (mediaType == 'video') {
        // For video viewing, use actual video_url, fallback to thumbnail_url
        final videoPath =
            response['video_url'] ?? response['thumbnail_url'] ?? '';

        // Resolve relative path to full URL
        if (videoPath.isNotEmpty &&
            !videoPath.startsWith('http://') &&
            !videoPath.startsWith('https://')) {
          mediaUrl = supabaseService.getStorageUrl(videoPath) ?? videoPath;
        } else {
          mediaUrl = videoPath;
        }

        print('🎬 STORY SERVICE: Video story - using video_url: $mediaUrl');
      } else {
        // For image viewing, use actual image_url, fallback to thumbnail_url
        final imagePath =
            response['image_url'] ?? response['thumbnail_url'] ?? '';

        // Resolve relative path to full URL
        if (imagePath.isNotEmpty &&
            !imagePath.startsWith('http://') &&
            !imagePath.startsWith('https://')) {
          mediaUrl = supabaseService.getStorageUrl(imagePath) ?? imagePath;
        } else {
          mediaUrl = imagePath;
        }

        print('📸 STORY SERVICE: Image story - using image_url: $mediaUrl');
      }

      final storyDetails = {
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

      print('✅ STORY SERVICE: Successfully fetched story details');
      return storyDetails;
    } catch (e) {
      print('❌ STORY SERVICE: Error fetching story details: $e');
      return null;
    }
  }

  /// Create a new memory in the database
  Future<String?> createMemory({
    required String title,
    required String creatorId,
    required String visibility,
    required String duration,
    String? categoryId,
    List<String>? invitedUserIds,
  }) async {
    try {
      // Create memory
      final response = await _supabase?.from('memories').insert({
        'title': title,
        'creator_id': creatorId,
        'visibility': visibility,
        'duration': duration,
        if (categoryId != null) 'category_id': categoryId,
        'expires_at': _calculateExpirationTime(duration).toIso8601String(),
      }).select();

      if (response == null || response.isEmpty) {
        throw Exception('Failed to create memory');
      }

      final memoryId = response.first['id'] as String;

      // Add contributors if provided
      if (invitedUserIds != null && invitedUserIds.isNotEmpty) {
        // Filter out invalid UUIDs (like mock user IDs: "user1", "user2", etc.)
        final validUserIds =
            invitedUserIds.where((userId) => _isValidUUID(userId)).toList();

        if (validUserIds.isNotEmpty) {
          final contributorInserts = validUserIds
              .map<Map<String, dynamic>>((userId) => {
                    'memory_id': memoryId,
                    'user_id': userId,
                  })
              .toList();

          await _supabase
              ?.from('memory_contributors')
              .insert(contributorInserts);
        } else {
          print(
              '⚠️ CREATE MEMORY: No valid UUIDs found in invited user IDs, skipping contributor inserts');
        }
      }

      return memoryId;
    } catch (e) {
      print('Error creating memory: $e');
      return null;
    }
  }

  /// Check if a string is a valid UUID format
  bool _isValidUUID(String? value) {
    if (value == null || value.isEmpty) return false;
    // UUID format: 8-4-4-4-12 hexadecimal characters
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(value);
  }

  /// Calculate expiration time based on duration
  DateTime _calculateExpirationTime(String duration) {
    final now = DateTime.now();
    switch (duration) {
      case '24_hours':
        return now.add(Duration(hours: 24));
      case '12_hours':
        return now.add(Duration(hours: 12));
      default:
        return now.add(Duration(hours: 12));
    }
  }
}
