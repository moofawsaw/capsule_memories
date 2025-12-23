import 'package:supabase_flutter/supabase_flutter.dart';

import './avatar_helper_service.dart';
import './supabase_service.dart';

/// Service for fetching feed data from Supabase
class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  SupabaseClient? get _client => SupabaseService.instance.client;

  /// 🛡️ VALIDATION: Validates story data completeness before rendering
  /// Returns true if all critical data is present, false if validation fails
  bool _validateStoryData(Map<String, dynamic> item, String context) {
    final memory = item['memories'] as Map<String, dynamic>?;
    final contributor = item['user_profiles'] as Map<String, dynamic>?;
    final category = memory?['memory_categories'] as Map<String, dynamic>?;

    final categoryId = memory?['category_id'] as String?;
    final categoryIconUrl = category?['icon_url'] as String?;
    final categoryName = category?['name'] as String?;
    final contributorName = contributor?['display_name'] as String?;
    final thumbnailUrl = item['thumbnail_url'] as String?;

    // CRITICAL: Check for null/missing data
    final validationErrors = <String>[];

    if (categoryId != null && category == null) {
      validationErrors
          .add('Category join failed for category_id "$categoryId"');
    }

    if (categoryId != null && categoryIconUrl == null) {
      validationErrors
          .add('Category icon_url is null for category "$categoryName"');
    }

    if (contributorName == null || contributorName.isEmpty) {
      validationErrors.add('Contributor display_name is missing');
    }

    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      validationErrors.add('Story thumbnail_url is missing');
    }

    if (validationErrors.isNotEmpty) {
      print('❌ VALIDATION FAILED [$context] for story "${item['id']}":');
      for (final error in validationErrors) {
        print('  - $error');
      }
      return false;
    }

    return true;
  }

  /// 🛡️ VALIDATION: Validates memory data completeness before rendering
  /// Returns true if all critical data is present, false if validation fails
  bool _validateMemoryData(Map<String, dynamic> memory, String context) {
    final category = memory['memory_categories'] as Map<String, dynamic>?;
    final categoryIconUrl = category?['icon_url'] as String?;
    final categoryName = category?['name'] as String?;
    final title = memory['title'] as String?;
    final stories = memory['stories'] as List? ?? [];

    final validationErrors = <String>[];

    if (title == null || title.isEmpty) {
      validationErrors.add('Memory title is missing');
    }

    if (category == null) {
      validationErrors.add('Category join failed');
    }

    if (categoryIconUrl == null || categoryIconUrl.isEmpty) {
      validationErrors.add('Category icon_url is missing for "$categoryName"');
    }

    if (stories.isEmpty) {
      validationErrors.add('No stories found in memory');
    }

    if (validationErrors.isNotEmpty) {
      print('❌ VALIDATION FAILED [$context] for memory "${memory['id']}":');
      for (final error in validationErrors) {
        print('  - $error');
      }
      return false;
    }

    return true;
  }

  /// Fetch recent stories for "Happening Now" section
  /// Returns stories from the last 24 hours sorted by creation time
  Future<List<Map<String, dynamic>>> fetchHappeningNowStories() async {
    if (_client == null) return [];

    try {
      // First, validate category icons exist in memory_categories table
      print('🔍 VALIDATION: Checking memory_categories table for icon data...');
      final categoriesValidation = await _client!
          .from('memory_categories')
          .select('id, name, icon_url')
          .limit(10);

      print(
          '🔍 VALIDATION: Found ${(categoriesValidation as List).length} categories in database:');
      for (final cat in categoriesValidation) {
        print(
            '  - Category: ${cat['name']}, Icon URL: "${cat['icon_url']}", ID: ${cat['id']}');
      }

      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            contributor_id,
            memory_id,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id(
                id,
                name,
                icon_url
              )
            ),
            user_profiles!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('is_disabled', false)
          .eq('memories.visibility', 'public')
          .gte('created_at',
              DateTime.now().subtract(Duration(hours: 24)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(10);

      // Debug logging for happening now stories
      print(
          '🔍 DEBUG: Fetched ${(response as List).length} happening now stories');

      // 🛡️ VALIDATION: Filter out stories with incomplete data
      final validatedStories = <Map<String, dynamic>>[];

      for (final item in response) {
        if (_validateStoryData(item, 'HappeningNow')) {
          final memory = item['memories'] as Map<String, dynamic>?;
          final contributor =
              item['user_profiles'] as Map<String, dynamic>? ?? {};
          final category =
              memory?['memory_categories'] as Map<String, dynamic>?;

          validatedStories.add({
            'id': item['id'] ?? '',
            'thumbnail_url': item['thumbnail_url'] ?? '',
            'created_at': item['created_at'] ?? '',
            'memory_id': item['memory_id'] ?? '',
            'contributor_name': contributor['display_name'] ?? 'Unknown User',
            'contributor_avatar': AvatarHelperService.getAvatarUrl(
              contributor['avatar_url'],
            ),
            'memory_title': memory?['title'] ?? 'Untitled Memory',
            'category_name': category?['name'] ?? 'Custom',
            'category_icon': category?['icon_url'] ?? '',
          });
        }
      }

      print(
          '✅ VALIDATION: ${validatedStories.length} stories passed validation');
      return validatedStories;
    } catch (e) {
      print('❌ ERROR fetching happening now stories: $e');
      return [];
    }
  }

  /// Fetch public memories for "Public Memories" section
  /// Returns public memories with their first story thumbnail
  Future<List<Map<String, dynamic>>> fetchPublicMemories() async {
    if (_client == null) return [];

    try {
      final response = await _client!
          .from('memories')
          .select('''
            id,
            title,
            created_at,
            expires_at,
            location_name,
            contributor_count,
            state,
            visibility,
            creator_id,
            category_id,
            memory_categories:category_id(
              name,
              icon_url
            ),
            stories(
              thumbnail_url,
              video_url
            )
          ''')
          .eq('visibility', 'public')
          .eq('state', 'open')
          .order('created_at', ascending: false)
          .limit(20);

      // Debug logging for category data
      print('🔍 DEBUG: Fetched ${(response as List).length} public memories');

      final List<Map<String, dynamic>> transformedMemories = [];

      for (final memory in response) {
        // 🛡️ VALIDATION: Validate memory data before processing
        if (!_validateMemoryData(memory, 'PublicMemories')) {
          continue; // Skip this memory if validation fails
        }

        final category = memory['memory_categories'] as Map<String, dynamic>?;
        final categoryIconUrl = category?['icon_url'] ?? '';

        // Debug log for category icon
        print(
            '🔍 DEBUG: Memory "${memory['title']}" - Category: ${category?['name']}, Icon URL: "$categoryIconUrl"');

        // Fetch contributors for this memory
        final contributorsResponse = await _client!
            .from('memory_contributors')
            .select('user_id, user_profiles!inner(avatar_url)')
            .eq('memory_id', memory['id'])
            .limit(3);

        final contributorAvatars = (contributorsResponse as List)
            .map((c) {
              final profile = c['user_profiles'] as Map<String, dynamic>?;
              return AvatarHelperService.getAvatarUrl(
                profile?['avatar_url'],
              );
            })
            .where((url) => url.isNotEmpty)
            .toList();

        final stories = memory['stories'] as List? ?? [];
        final mediaItems = stories
            .where((s) =>
                s['thumbnail_url'] != null &&
                s['thumbnail_url'].toString().isNotEmpty)
            .take(2)
            .map((s) => {
                  'thumbnail_url': s['thumbnail_url'],
                  'video_url': s['video_url'],
                })
            .toList();

        // 🛡️ VALIDATION: Skip memory if no valid media items
        if (mediaItems.isEmpty) {
          print(
              '⚠️ WARNING: Skipping memory "${memory['title']}" - no valid media items');
          continue;
        }

        final createdAt = DateTime.parse(memory['created_at']);
        final expiresAt = DateTime.parse(memory['expires_at']);

        transformedMemories.add({
          'id': memory['id'],
          'title': memory['title'] ?? 'Untitled Memory',
          'date': _formatDate(createdAt),
          'category_icon': categoryIconUrl,
          'contributor_avatars': contributorAvatars,
          'media_items': mediaItems,
          'start_date': _formatDate(createdAt),
          'start_time': _formatTime(createdAt),
          'end_date': _formatDate(expiresAt),
          'end_time': _formatTime(expiresAt),
          'location': memory['location_name'] ?? '',
          'state': memory['state'] ?? 'open',
        });
      }

      print(
          '✅ VALIDATION: ${transformedMemories.length} memories passed validation');
      return transformedMemories;
    } catch (e) {
      print('❌ ERROR fetching public memories: $e');
      return [];
    }
  }

  /// Fetch trending stories based on view count
  /// Returns most viewed stories from the last 7 days
  Future<List<Map<String, dynamic>>> fetchTrendingStories() async {
    if (_client == null) return [];

    try {
      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            view_count,
            contributor_id,
            memory_id,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id!inner(
                name,
                icon_url
              )
            ),
            user_profiles!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('is_disabled', false)
          .eq('memories.visibility', 'public')
          .gte('created_at',
              DateTime.now().subtract(Duration(days: 7)).toIso8601String())
          .order('view_count', ascending: false)
          .limit(10);

      // 🛡️ VALIDATION: Filter out stories with incomplete data
      final validatedStories = <Map<String, dynamic>>[];

      for (final item in response) {
        if (_validateStoryData(item, 'TrendingStories')) {
          final memory = item['memories'] as Map<String, dynamic>?;
          final contributor =
              item['user_profiles'] as Map<String, dynamic>? ?? {};
          final category =
              memory?['memory_categories'] as Map<String, dynamic>?;

          validatedStories.add({
            'id': item['id'] ?? '',
            'thumbnail_url': item['thumbnail_url'] ?? '',
            'created_at': item['created_at'] ?? '',
            'view_count': item['view_count'] ?? 0,
            'contributor_name': contributor['display_name'] ?? 'Unknown User',
            'contributor_avatar': AvatarHelperService.getAvatarUrl(
              contributor['avatar_url'],
            ),
            'memory_title': memory?['title'] ?? 'Untitled Memory',
            'category_name': category?['name'] ?? 'Custom',
            'category_icon': category?['icon_url'] ?? '',
          });
        }
      }

      print(
          '✅ VALIDATION: ${validatedStories.length} trending stories passed validation');
      return validatedStories;
    } catch (e) {
      print('Error fetching trending stories: $e');
      return [];
    }
  }

  /// NEW METHOD: Fetch all latest story IDs in chronological order (not grouped by memory)
  /// Filters stories to only include those from memories where current user is a contributor
  Future<List<String>> fetchLatestStoryIds() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        print('❌ ERROR: Supabase client not initialized');
        return [];
      }

      // Get current user ID
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ ERROR: No authenticated user');
        return [];
      }

      // First, get all memory IDs where current user is a contributor
      final contributorResponse = await client
          .from('memory_contributors')
          .select('memory_id')
          .eq('user_id', currentUserId);

      if (contributorResponse.isEmpty) {
        print('⚠️ WARNING: User is not a contributor to any memories');
        return [];
      }

      final memoryIds = (contributorResponse as List)
          .map((c) => c['memory_id'] as String)
          .toList();

      print(
          '🔍 DEBUG: User is contributor to ${memoryIds.length} memories: $memoryIds');

      // Fetch all stories from these memories in chronological order
      final response = await client
          .from('stories')
          .select('id, created_at, memory_id')
          .inFilter('memory_id', memoryIds)
          .eq('is_disabled', false)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        print('⚠️ WARNING: No stories found in user\'s memories');
        return [];
      }

      final storyIds =
          (response as List).map((story) => story['id'] as String).toList();

      print('✅ SUCCESS: Fetched ${storyIds.length} story IDs from latest feed');
      print(
          '🔍 DEBUG: Stories belong to these memories: ${(response).map((s) => s['memory_id']).toSet().toList()}');

      return storyIds;
    } catch (e) {
      print('❌ ERROR fetching latest story IDs: $e');
      return [];
    }
  }

  /// Helper method to format date
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Helper method to format time
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute$period';
  }

  /// Helper method to calculate relative time
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  /// Fetch memory details with stories and contributors for event view
  Future<Map<String, dynamic>?> fetchMemoryDetails(String memoryId) async {
    if (_client == null) return null;

    try {
      // Fetch memory details
      final memoryResponse = await _client!.from('memories').select('''
            id,
            title,
            created_at,
            expires_at,
            location_name,
            view_count,
            contributor_count
          ''').eq('id', memoryId).single();

      // Fetch contributors for this memory
      final contributorsResponse =
          await _client!.from('memory_contributors').select('''
            id,
            user_id,
            user_profiles!inner(
              id,
              display_name,
              avatar_url
            )
          ''').eq('memory_id', memoryId);

      final contributors = (contributorsResponse as List).map((c) {
        final profile = c['user_profiles'] as Map<String, dynamic>?;
        return {
          'contributorId': c['user_id'] ?? '',
          'contributorName': profile?['display_name'] ?? 'Unknown User',
          'contributorImage': AvatarHelperService.getAvatarUrl(
            profile?['avatar_url'],
          ),
        };
      }).toList();

      // Fetch stories for this memory - ORDER CHANGED TO ASCENDING TO MATCH STORY VIEWER
      final storiesResponse = await _client!
          .from('stories')
          .select('''
            id,
            thumbnail_url,
            video_url,
            created_at
          ''')
          .eq('memory_id', memoryId)
          .eq('is_disabled', false)
          .order('created_at', ascending: true);

      final stories = (storiesResponse as List).map((s) {
        return {
          'storyId': s['id'] ?? '',
          'storyImage': s['thumbnail_url'] ?? '',
          'timeAgo': _getRelativeTime(DateTime.parse(s['created_at'])),
        };
      }).toList();

      final createdAt = DateTime.parse(memoryResponse['created_at']);

      return {
        'eventTitle': memoryResponse['title'] ?? 'Untitled Memory',
        'eventDate': _formatDate(createdAt),
        'eventLocation': memoryResponse['location_name'] ?? '',
        'viewCount': memoryResponse['view_count']?.toString() ?? '0',
        'contributorsList': contributors,
        'storiesList': stories,
      };
    } catch (e) {
      print('Error fetching memory details: $e');
      return null;
    }
  }

  /// Fetch individual story details for story viewer
  Future<Map<String, dynamic>?> fetchStoryDetails(String storyId) async {
    if (_client == null) return null;

    try {
      final response = await _client!.from('stories').select('''
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

      // Get the correct media URL based on media_type from database
      final mediaType = response['media_type'] as String? ?? 'image';
      String mediaUrl = '';

      if (mediaType == 'video') {
        // For video, prefer video_url, fallback to thumbnail_url
        mediaUrl = response['video_url'] ?? response['thumbnail_url'] ?? '';
      } else {
        // For image, prefer image_url, fallback to thumbnail_url
        mediaUrl = response['image_url'] ?? response['thumbnail_url'] ?? '';
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
      print('❌ ERROR fetching story details: $e');
      return null;
    }
  }

  /// Fetch all stories for a given memory in chronological order
  /// Used for story cycling functionality
  Future<List<String>> fetchMemoryStoryIds(String memoryId) async {
    if (_client == null) return [];

    try {
      final response = await _client!
          .from('stories')
          .select('id')
          .eq('memory_id', memoryId)
          .eq('is_disabled', false)
          .order('created_at', ascending: true);

      return (response as List).map((item) => item['id'] as String).toList();
    } catch (e) {
      print('❌ ERROR fetching memory story IDs: $e');
      return [];
    }
  }
}
