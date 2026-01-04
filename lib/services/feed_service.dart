import 'package:supabase_flutter/supabase_flutter.dart';

import './avatar_helper_service.dart';
import './story_service.dart';
import './supabase_service.dart';

/// Service for fetching feed data from Supabase
class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  SupabaseClient? get _client => SupabaseService.instance.client;

  // Pagination constants
  static const int _pageSize = 10;

  // CRITICAL FIX: Add StoryService for URL resolution (same pattern as /memories)
  final _storyService = StoryService();

  // NEW: Real-time subscription management
  RealtimeChannel? _storyViewsChannel;

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

  /// NEW METHOD: Subscribe to real-time story_views updates
  /// Calls the provided callback whenever a story view is inserted
  RealtimeChannel? subscribeToStoryViews({
    required Function(String storyId, String userId) onStoryViewed,
  }) {
    if (_client == null) {
      print('❌ ERROR: Cannot subscribe to story views - client is null');
      return null;
    }

    try {
      // Dispose existing subscription if any
      _storyViewsChannel?.unsubscribe();

      // Create new real-time channel for story_views table
      _storyViewsChannel = _client!
          .channel('story_views_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'story_views',
            callback: (payload) {
              print('🔄 REALTIME: Story view detected');
              print('   - Payload: ${payload.newRecord}');

              final storyId = payload.newRecord['story_id'] as String?;
              final userId = payload.newRecord['user_id'] as String?;

              if (storyId != null && userId != null) {
                print('   - Story ID: $storyId');
                print('   - User ID: $userId');
                onStoryViewed(storyId, userId);
              }
            },
          )
          .subscribe();

      print('✅ SUCCESS: Subscribed to real-time story views');
      return _storyViewsChannel;
    } catch (e) {
      print('❌ ERROR subscribing to story views: $e');
      return null;
    }
  }

  /// NEW METHOD: Unsubscribe from real-time story_views updates
  void unsubscribeFromStoryViews() {
    if (_storyViewsChannel != null) {
      _storyViewsChannel!.unsubscribe();
      _storyViewsChannel = null;
      print('✅ SUCCESS: Unsubscribed from real-time story views');
    }
  }

  /// Fetch recent stories for "Happening Now" section with pagination
  /// Returns stories from the last 24 hours sorted by creation time
  Future<List<Map<String, dynamic>>> fetchHappeningNowStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      // Get current user ID for read status check
      final currentUserId = _client!.auth.currentUser?.id;

      // CRITICAL: Use user_profiles_public for anonymous/public access
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
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte('created_at',
              DateTime.now().subtract(Duration(hours: 24)).toIso8601String())
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // 🛡️ VALIDATION: Filter out stories with incomplete data
      final validatedStories = <Map<String, dynamic>>[];

      for (final item in response) {
        // CRITICAL FIX: Update validation to use user_profiles_public
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        // Validate required fields
        if (memory?['title'] == null ||
            contributor['display_name'] == null ||
            item['thumbnail_url'] == null) {
          print(
              '⚠️ WARNING: Skipping story "${item['id']}" - missing required data');
          continue;
        }

        // NEW: Check if current user has viewed this story
        bool isRead = false;
        if (currentUserId != null) {
          try {
            final viewResponse = await _client!
                .from('story_views')
                .select('id')
                .eq('story_id', item['id'])
                .eq('user_id', currentUserId)
                .maybeSingle();

            isRead = viewResponse != null;
          } catch (e) {
            print(
                '⚠️ WARNING: Failed to check view status for story "${item['id']}": $e');
          }
        }

        // CRITICAL FIX: Resolve thumbnail URL using StoryService helper
        final resolvedThumbnailUrl = _storyService.getStoryMediaUrl(item);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': resolvedThumbnailUrl ?? '',
          'created_at': item['created_at'] ?? '',
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributor['display_name'] ?? 'Unknown User',
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'memory_title': memory?['title'] ?? 'Untitled Memory',
          'category_name': category?['name'] ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead, // NEW: Include read status
        });
      }

      print(
          '✅ VALIDATION: ${validatedStories.length} stories passed validation');
      return validatedStories;
    } catch (e) {
      print('❌ ERROR fetching happening now stories: $e');
      return [];
    }
  }

  /// Fetch public memories for "Public Memories" section with pagination
  Future<List<Map<String, dynamic>>> fetchPublicMemories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
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
          .range(offset, offset + limit - 1);

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

        // CRITICAL: Fetch contributors using user_profiles_public for anonymous access
        final contributorsResponse = await _client!
            .from('memory_contributors')
            .select('user_id, user_profiles_public!inner(avatar_url)')
            .eq('memory_id', memory['id'])
            .limit(3);

        final contributorAvatars = (contributorsResponse as List)
            .map((c) {
              final profile =
                  c['user_profiles_public'] as Map<String, dynamic>?;
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

  /// Fetch trending stories with pagination
  Future<List<Map<String, dynamic>>> fetchTrendingStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      // CRITICAL: Use user_profiles_public for anonymous/public access
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
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte('created_at',
              DateTime.now().subtract(Duration(days: 7)).toIso8601String())
          .order('view_count', ascending: false)
          .range(offset, offset + limit - 1);

      // 🛡️ VALIDATION: Filter out stories with incomplete data
      final validatedStories = <Map<String, dynamic>>[];

      for (final item in response) {
        // CRITICAL FIX: Update to use user_profiles_public
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        // Validate required fields
        if (memory?['title'] == null ||
            contributor['display_name'] == null ||
            item['thumbnail_url'] == null) {
          print(
              '⚠️ WARNING: Skipping trending story "${item['id']}" - missing required data');
          continue;
        }

        // CRITICAL FIX: Resolve thumbnail URL using StoryService helper
        final resolvedThumbnailUrl = _storyService.getStoryMediaUrl(item);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': resolvedThumbnailUrl ?? '',
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

      print(
          '✅ VALIDATION: ${validatedStories.length} trending stories passed validation');
      return validatedStories;
    } catch (e) {
      print('Error fetching trending stories: $e');
      return [];
    }
  }

  /// Fetch longest streak stories with pagination
  Future<List<Map<String, dynamic>>> fetchLongestStreakStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      // CRITICAL: Use user_profiles_public for anonymous/public access
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
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              posting_streak
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte('created_at',
              DateTime.now().subtract(Duration(days: 30)).toIso8601String())
          .order('user_profiles_public(posting_streak)', ascending: false)
          .range(offset, offset + limit - 1);

      // 🛡️ VALIDATION: Filter out stories with incomplete data
      final validatedStories = <Map<String, dynamic>>[];

      for (final item in response) {
        // CRITICAL FIX: Update to use user_profiles_public
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        // Validate required fields
        if (memory?['title'] == null ||
            contributor['display_name'] == null ||
            item['thumbnail_url'] == null) {
          print(
              '⚠️ WARNING: Skipping longest streak story "${item['id']}" - missing required data');
          continue;
        }

        // CRITICAL FIX: Resolve thumbnail URL using StoryService helper
        final resolvedThumbnailUrl = _storyService.getStoryMediaUrl(item);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': resolvedThumbnailUrl ?? '',
          'created_at': item['created_at'] ?? '',
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributor['display_name'] ?? 'Unknown User',
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'posting_streak': contributor['posting_streak'] ?? 0,
          'memory_title': memory?['title'] ?? 'Untitled Memory',
          'category_name': category?['name'] ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
        });
      }

      print(
          '✅ VALIDATION: ${validatedStories.length} longest streak stories passed validation');
      return validatedStories;
    } catch (e) {
      print('❌ ERROR fetching longest streak stories: $e');
      return [];
    }
  }

  /// Fetch popular user stories with pagination
  Future<List<Map<String, dynamic>>> fetchPopularUserStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      // CRITICAL: Use user_profiles_public for anonymous/public access
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
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              popularity_score
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte('created_at',
              DateTime.now().subtract(Duration(days: 30)).toIso8601String())
          .order('user_profiles_public(popularity_score)', ascending: false)
          .range(offset, offset + limit - 1);

      // 🛡️ VALIDATION: Filter out stories with incomplete data
      final validatedStories = <Map<String, dynamic>>[];

      for (final item in response) {
        // CRITICAL FIX: Update to use user_profiles_public
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        // Validate required fields
        if (memory?['title'] == null ||
            contributor['display_name'] == null ||
            item['thumbnail_url'] == null) {
          print(
              '⚠️ WARNING: Skipping popular user story "${item['id']}" - missing required data');
          continue;
        }

        // CRITICAL FIX: Resolve thumbnail URL using StoryService helper
        final resolvedThumbnailUrl = _storyService.getStoryMediaUrl(item);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': resolvedThumbnailUrl ?? '',
          'created_at': item['created_at'] ?? '',
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributor['display_name'] ?? 'Unknown User',
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'popularity_score': contributor['popularity_score'] ?? 0,
          'memory_title': memory?['title'] ?? 'Untitled Memory',
          'category_name': category?['name'] ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
        });
      }

      print(
          '✅ VALIDATION: ${validatedStories.length} popular user stories passed validation');
      return validatedStories;
    } catch (e) {
      print('❌ ERROR fetching popular user stories: $e');
      return [];
    }
  }

  /// Fetch popular memories with pagination
  Future<List<Map<String, dynamic>>> fetchPopularMemories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
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
            popularity_score,
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
          .order('popularity_score', ascending: false)
          .range(offset, offset + limit - 1);

      // Debug logging for category data
      print('🔍 DEBUG: Fetched ${(response as List).length} popular memories');

      final List<Map<String, dynamic>> transformedMemories = [];

      for (final memory in response) {
        // 🛡️ VALIDATION: Validate memory data before processing
        if (!_validateMemoryData(memory, 'PopularMemories')) {
          continue; // Skip this memory if validation fails
        }

        final category = memory['memory_categories'] as Map<String, dynamic>?;
        final categoryIconUrl = category?['icon_url'] ?? '';

        // Debug log for category icon
        print(
            '🔍 DEBUG: Popular Memory "${memory['title']}" - Category: ${category?['name']}, Icon URL: "$categoryIconUrl", Popularity Score: ${memory['popularity_score']}');

        // CRITICAL: Fetch contributors using user_profiles_public for anonymous access
        final contributorsResponse = await _client!
            .from('memory_contributors')
            .select('user_id, user_profiles_public!inner(avatar_url)')
            .eq('memory_id', memory['id'])
            .limit(3);

        final contributorAvatars = (contributorsResponse as List)
            .map((c) {
              final profile =
                  c['user_profiles_public'] as Map<String, dynamic>?;
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
              '⚠️ WARNING: Skipping popular memory "${memory['title']}" - no valid media items');
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
          'popularity_score': memory['popularity_score'] ?? 0,
        });
      }

      print(
          '✅ VALIDATION: ${transformedMemories.length} popular memories passed validation');
      return transformedMemories;
    } catch (e) {
      print('❌ ERROR fetching popular memories: $e');
      return [];
    }
  }

  /// NEW METHOD: Fetch latest stories (all stories ordered by date)
  /// Returns stories from all memories the user is a contributor to, ordered by creation date
  Future<List<Map<String, dynamic>>> fetchLatestStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ ERROR: No authenticated user for latest stories');
        return [];
      }

      // Get memory IDs where user is a contributor
      final contributorResponse = await _client!
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

      // Fetch stories from these memories ordered by date
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
          .inFilter('memory_id', memoryIds)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // 🛡️ VALIDATION: Filter out stories with incomplete data
      final validatedStories = <Map<String, dynamic>>[];

      for (final item in response) {
        if (_validateStoryData(item, 'LatestStories')) {
          final memory = item['memories'] as Map<String, dynamic>?;
          final contributor =
              item['user_profiles'] as Map<String, dynamic>? ?? {};
          final category =
              memory?['memory_categories'] as Map<String, dynamic>?;

          // CRITICAL FIX: Resolve thumbnail URL using StoryService helper
          final resolvedThumbnailUrl = _storyService.getStoryMediaUrl(item);

          validatedStories.add({
            'id': item['id'] ?? '',
            'thumbnail_url': resolvedThumbnailUrl ?? '',
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
          '✅ VALIDATION: ${validatedStories.length} latest stories passed validation');
      return validatedStories;
    } catch (e) {
      print('❌ ERROR fetching latest stories: $e');
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

  /// Fetch user's active memories where they are a contributor
  /// Returns memories with state='open' that haven't expired
  Future<List<Map<String, dynamic>>> fetchUserActiveMemories() async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ ERROR: No authenticated user');
        return [];
      }

      // Get memory IDs where user is a contributor
      final contributorResponse = await _client!
          .from('memory_contributors')
          .select('memory_id')
          .eq('user_id', currentUserId);

      if (contributorResponse.isEmpty) {
        print('⚠️ INFO: User is not a contributor to any memories');
        return [];
      }

      final memoryIds = (contributorResponse as List)
          .map((c) => c['memory_id'] as String)
          .toList();

      // Fetch active (open) memories that haven't expired
      final response = await _client!
          .from('memories')
          .select('''
            id,
            title,
            state,
            created_at,
            expires_at,
            category_id,
            memory_categories:category_id(
              name,
              icon_url
            )
          ''')
          .inFilter('id', memoryIds)
          .eq('state', 'open')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      final activeMemories = (response as List).map((memory) {
        final category = memory['memory_categories'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(memory['created_at']);
        final expiresAt = DateTime.parse(memory['expires_at']);

        return {
          'id': memory['id'] ?? '',
          'title': memory['title'] ?? 'Untitled Memory',
          'category_name': category?['name'] ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'created_at': memory['created_at'] ?? '',
          'expires_at': memory['expires_at'] ?? '',
          'created_date': _formatDate(createdAt),
          'expiration_text': _formatExpirationTime(expiresAt),
        };
      }).toList();

      print(
          '✅ SUCCESS: Fetched ${activeMemories.length} active memories for user');
      return activeMemories;
    } catch (e) {
      print('❌ ERROR fetching user active memories: $e');
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

  /// Helper method to format expiration time as human-readable text
  String _formatExpirationTime(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'expired';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'expires in ${minutes} ${minutes == 1 ? 'minute' : 'minutes'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'expires in ${hours} ${hours == 1 ? 'hour' : 'hours'}';
    } else {
      final days = difference.inDays;
      return 'expires in ${days} ${days == 1 ? 'day' : 'days'}';
    }
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

      // CRITICAL: Fetch contributors using user_profiles_public for anonymous access
      final contributorsResponse =
          await _client!.from('memory_contributors').select('''
            id,
            user_id,
            user_profiles_public!inner(
              id,
              display_name,
              avatar_url
            )
          ''').eq('memory_id', memoryId);

      final contributors = (contributorsResponse as List).map((c) {
        final profile = c['user_profiles_public'] as Map<String, dynamic>?;
        return {
          'contributorId': c['user_id'] ?? '',
          'contributorName': profile?['display_name'] ?? 'Unknown User',
          'contributorImage': AvatarHelperService.getAvatarUrl(
            profile?['avatar_url'],
          ),
        };
      }).toList();

      // Fetch stories for this memory - ORDER CHANGED TO ASCENDING TO MATCH STORY VIEWER
      final storiesResponse = await _client!.from('stories').select('''
            id,
            thumbnail_url,
            video_url,
            created_at
          ''').eq('memory_id', memoryId).order('created_at', ascending: true);

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
      // CRITICAL FIX: Join with memories table to fetch memory name
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
            memory_id,
            memories!inner(
              id,
              title,
              created_at,
              location_name,
              visibility
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              username
            )
          ''').eq('id', storyId).single();

      final contributor =
          response['user_profiles_public'] as Map<String, dynamic>?;
      final memory = response['memories'] as Map<String, dynamic>?;
      final textOverlays = response['text_overlays'] as List? ?? [];

      // Extract caption from text overlays
      String? caption;
      if (textOverlays.isNotEmpty && textOverlays[0] is Map) {
        caption = textOverlays[0]['text'] as String?;
      }

      // CRITICAL FIX: Properly resolve video/image URLs from Supabase storage
      final mediaType = response['media_type'] as String? ?? 'image';
      String mediaUrl = '';

      if (mediaType == 'video') {
        // For video, prefer video_url, fallback to thumbnail_url
        final rawVideoPath =
            response['video_url'] ?? response['thumbnail_url'] ?? '';

        // CRITICAL: Use static helper to resolve storage URL
        mediaUrl = StoryService.resolveStoryMediaUrl(rawVideoPath) ?? '';

        print(
            '🎬 FEED SERVICE: Resolved video URL from "$rawVideoPath" to "$mediaUrl"');
      } else {
        // For image, prefer image_url, fallback to thumbnail_url
        final rawImagePath =
            response['image_url'] ?? response['thumbnail_url'] ?? '';

        // CRITICAL: Use static helper to resolve storage URL
        mediaUrl = StoryService.resolveStoryMediaUrl(rawImagePath) ?? '';

        print(
            '📸 FEED SERVICE: Resolved image URL from "$rawImagePath" to "$mediaUrl"');
      }

      // CRITICAL FIX: Use correct column name 'title' instead of 'name'
      return {
        'media_url': mediaUrl,
        'media_type': mediaType,
        'user_name': contributor?['display_name'] ?? 'Unknown User',
        'user_id': contributor?['id'] ?? '',
        'user_avatar': AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'],
        ),
        'created_at': response['created_at'] ?? '',
        'location': response['location_name'],
        'caption': caption,
        'view_count': response['view_count'] ?? 0,
        'memory_id': response['memory_id'] ?? '',
        'memory_title': memory?['title'] ?? 'Untitled Memory',
        'memory_date': memory?['created_at'] ?? '',
        'memory_location': memory?['location_name'] ?? '',
        'memory_visibility': memory?['visibility'] ?? '',
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
          .order('created_at', ascending: true);

      return (response as List).map((item) => item['id'] as String).toList();
    } catch (e) {
      print('❌ ERROR fetching memory story IDs: $e');
      return [];
    }
  }
}
