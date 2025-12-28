import './supabase_service.dart';
import './avatar_helper_service.dart';

class StoryService {
  final _supabase = SupabaseService.instance.client;

  /// Fetch stories ONLY from memories where user is a participant (creator or contributor)
  /// Uses explicit memory filtering to ensure user access
  Future<List<Map<String, dynamic>>> fetchUserStories(String userId) async {
    try {
      print('🔍 STORY SERVICE: Fetching stories for userId: $userId');

      // CRITICAL FIX: Explicitly filter stories by user's memories
      // Step 1: Get memory IDs where user is creator
      final createdMemoriesResponse = await _supabase
          ?.from('memories')
          .select('id')
          .eq('creator_id', userId);

      final createdMemoryIds = (createdMemoriesResponse as List?)
              ?.map((m) => m['id'] as String)
              .toList() ??
          [];

      print(
          '🔍 STORY SERVICE: User created ${createdMemoryIds.length} memories');

      // Step 2: Get memory IDs where user is contributor
      final contributorMemoriesResponse = await _supabase
          ?.from('memory_contributors')
          .select('memory_id')
          .eq('user_id', userId);

      final contributorMemoryIds = (contributorMemoriesResponse as List?)
              ?.map((m) => m['memory_id'] as String)
              .toList() ??
          [];

      print(
          '🔍 STORY SERVICE: User is contributor to ${contributorMemoryIds.length} memories');

      // Combine both lists (user's created memories + memories they contributed to)
      final allUserMemoryIds = [
        ...createdMemoryIds,
        ...contributorMemoryIds,
      ].toSet().toList(); // Use Set to remove duplicates

      print(
          '🔍 STORY SERVICE: Total memories user has access to: ${allUserMemoryIds.length}');

      if (allUserMemoryIds.isEmpty) {
        print(
            '🔍 STORY SERVICE: User is not part of any memories, returning empty list');
        return [];
      }

      // Step 3: Fetch stories ONLY from these memories with complete data
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
              creator_id
            )
          ''')
          .inFilter('memory_id', allUserMemoryIds)
          .order('created_at', ascending: false);

      final stories = List<Map<String, dynamic>>.from(response as List? ?? []);

      print('🔍 STORY SERVICE: Fetched ${stories.length} stories total');

      // Enhanced logging for debugging thumbnail display
      for (var story in stories) {
        final memory = story['memories'] as Map<String, dynamic>?;
        print('📸 Story ${story['id']}: '
            'memory_id=${story['memory_id']}, '
            'memory_title=${memory?['title']}, '
            'media_type=${story['media_type']}, '
            'thumbnail_url=${story['thumbnail_url']}, '
            'image_url=${story['image_url']}, '
            'video_url=${story['video_url']}, '
            'contributor=${story['user_profiles']?['display_name']}');
      }

      return stories;
    } catch (e) {
      print('❌ Error fetching user stories: $e');
      return [];
    }
  }

  /// Fetch timeline cards (memories) where user is associated
  Future<List<Map<String, dynamic>>> fetchUserTimelines(String userId) async {
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
      return [];
    }
  }

  /// Fetch stories for a specific memory
  Future<List<Map<String, dynamic>>> fetchMemoryStories(String memoryId) async {
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
      return [];
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
  String getStoryMediaUrl(Map<String, dynamic> story) {
    // CRITICAL FIX: Prioritize thumbnail for story card previews to match /feed behavior
    // Story cards should ALWAYS show thumbnails, not full-resolution media
    if (story['thumbnail_url'] != null &&
        (story['thumbnail_url'] as String).isNotEmpty) {
      return story['thumbnail_url'] as String;
    }

    // Fallback to full media URLs only if thumbnail is missing
    if (story['media_type'] == 'video' && story['video_url'] != null) {
      return story['video_url'] as String;
    } else if (story['image_url'] != null) {
      return story['image_url'] as String;
    }

    return '';
  }

  /// Get contributor profile image
  String getContributorAvatar(Map<String, dynamic> story) {
    final contributor = story['user_profiles'];
    if (contributor != null && contributor['avatar_url'] != null) {
      return contributor['avatar_url'] as String;
    }
    return '';
  }

  /// Get memory thumbnail from latest story
  String getMemoryThumbnail(Map<String, dynamic> memory) {
    final stories = memory['stories'] as List?;
    if (stories != null && stories.isNotEmpty) {
      final latestStory = stories.first;
      if (latestStory['thumbnail_url'] != null) {
        return latestStory['thumbnail_url'] as String;
      } else if (latestStory['image_url'] != null) {
        return latestStory['image_url'] as String;
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
      String mediaUrl = '';

      if (mediaType == 'video') {
        // For video viewing, use actual video_url, fallback to thumbnail_url
        mediaUrl = response['video_url'] ?? response['thumbnail_url'] ?? '';
        print('🎬 STORY SERVICE: Video story - using video_url: $mediaUrl');
      } else {
        // For image viewing, use actual image_url, fallback to thumbnail_url
        mediaUrl = response['image_url'] ?? response['thumbnail_url'] ?? '';
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
    required String visibility, // 'public' or 'private'
    String duration = '12_hours', // '12_hours' or '24_hours'
    DateTime? startTime,
    DateTime? endTime,
    String? locationName,
    double? locationLat,
    double? locationLng,
    List<String>? invitedUserIds,
  }) async {
    try {
      print('🔍 STORY SERVICE: Creating memory "$title"');
      
      final now = DateTime.now();
      final start = startTime ?? now;
      
      // Calculate expires_at based on duration
      Duration expiresDuration;
      switch (duration) {
        case '24_hours':
          expiresDuration = Duration(hours: 24);
          break;
        case '12_hours':
        default:
          expiresDuration = Duration(hours: 12);
          break;
      }
      final expiresAt = endTime ?? now.add(expiresDuration);

      // Insert memory (invite_code will be auto-generated by trigger)
      final memoryResponse = await _supabase
          ?.from('memories')
          .insert({
            'title': title,
            'creator_id': creatorId,
            'visibility': visibility,
            'duration': duration,
            'state': 'open',
            'expires_at': expiresAt.toIso8601String(),
            'start_time': start.toIso8601String(),
            'end_time': expiresAt.toIso8601String(),
            if (locationName != null) 'location_name': locationName,
            if (locationLat != null) 'location_lat': locationLat,
            if (locationLng != null) 'location_lng': locationLng,
          })
          .select('id')
          .single();

      if (memoryResponse == null) {
        print('❌ STORY SERVICE: Failed to create memory');
        return null;
      }

      final memoryId = memoryResponse['id'] as String;
      print('✅ STORY SERVICE: Memory created with ID: $memoryId');

      // Add creator as contributor
      await _supabase?.from('memory_contributors').insert({
        'memory_id': memoryId,
        'user_id': creatorId,
      });
      print('✅ STORY SERVICE: Creator added as contributor');

      // Add invited users as contributors (only valid UUIDs)
      if (invitedUserIds != null && invitedUserIds.isNotEmpty) {
        // Filter out invalid UUIDs (mock user IDs like "user1", "user2", etc.)
        final validUserIds = invitedUserIds.where((userId) => _isValidUUID(userId)).toList();
        
        if (validUserIds.isNotEmpty) {
          final contributors = validUserIds.map((userId) => {
            'memory_id': memoryId,
            'user_id': userId,
          }).toList();

          await _supabase?.from('memory_contributors').insert(contributors);
          print('✅ STORY SERVICE: Added ${validUserIds.length} contributors (filtered ${invitedUserIds.length - validUserIds.length} invalid IDs)');
        } else {
          print('⚠️ STORY SERVICE: No valid UUIDs found in invited user IDs');
        }
      }

      return memoryId;
    } catch (e) {
      print('❌ STORY SERVICE: Error creating memory: $e');
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
}
