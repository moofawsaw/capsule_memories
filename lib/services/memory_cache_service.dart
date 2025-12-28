import 'dart:async';

import '../presentation/memories_dashboard_screen/models/memory_item_model.dart';
import '../presentation/memories_dashboard_screen/models/story_item_model.dart';
import './avatar_helper_service.dart';
import './story_service.dart';
import './supabase_service.dart';

/// In-memory cache service for memory objects with auto-refresh functionality
/// Ensures data consistency when navigating between /memories and /timeline
class MemoryCacheService {
  static final MemoryCacheService _instance = MemoryCacheService._internal();
  factory MemoryCacheService() => _instance;
  MemoryCacheService._internal();

  final _storyService = StoryService();

  // Cache storage
  List<MemoryItemModel>? _cachedMemories;
  List<StoryItemModel>? _cachedStories;
  String? _cachedUserId;
  DateTime? _lastCacheTime;

  // Cache configuration
  static const _cacheDuration = Duration(minutes: 5);

  // Stream controllers for cache updates
  final _memoriesStreamController =
      StreamController<List<MemoryItemModel>>.broadcast();
  final _storiesStreamController =
      StreamController<List<StoryItemModel>>.broadcast();

  Stream<List<MemoryItemModel>> get memoriesStream =>
      _memoriesStreamController.stream;
  Stream<List<StoryItemModel>> get storiesStream =>
      _storiesStreamController.stream;

  /// Check if cache is valid for the current user
  bool _isCacheValid(String userId) {
    if (_cachedMemories == null || _cachedStories == null) return false;
    if (_cachedUserId != userId) return false;
    if (_lastCacheTime == null) return false;

    final cacheAge = DateTime.now().difference(_lastCacheTime!);
    return cacheAge < _cacheDuration;
  }

  /// Get cached memories or fetch from database
  Future<List<MemoryItemModel>> getMemories(String userId,
      {bool forceRefresh = false}) async {
    print('🔍 CACHE: getMemories called for userId: $userId');
    print('🔍 CACHE: forceRefresh = $forceRefresh');

    if (!forceRefresh && _isCacheValid(userId)) {
      print('✅ CACHE: Returning cached memories (${_cachedMemories!.length})');
      return _cachedMemories!;
    }

    print('🔄 CACHE: Fetching fresh memories from database');
    _cachedMemories = await _loadUserMemories(userId);
    _cachedUserId = userId;
    _lastCacheTime = DateTime.now();

    _memoriesStreamController.add(_cachedMemories!);
    print('✅ CACHE: Cached ${_cachedMemories!.length} memories');

    return _cachedMemories!;
  }

  /// Get cached stories or fetch from database
  Future<List<StoryItemModel>> getStories(String userId,
      {bool forceRefresh = false}) async {
    print('🔍 CACHE: getStories called for userId: $userId');
    print('🔍 CACHE: forceRefresh = $forceRefresh');

    if (!forceRefresh && _isCacheValid(userId)) {
      print('✅ CACHE: Returning cached stories (${_cachedStories!.length})');
      return _cachedStories!;
    }

    print('🔄 CACHE: Fetching fresh stories from database');
    _cachedStories = await _loadUserStories(userId);
    _cachedUserId = userId;
    _lastCacheTime = DateTime.now();

    _storiesStreamController.add(_cachedStories!);
    print('✅ CACHE: Cached ${_cachedStories!.length} stories');

    return _cachedStories!;
  }

  /// Refresh cache for specific memory (called when navigating from /timeline)
  Future<void> refreshMemoryCache(String userId) async {
    print('🔄 CACHE: Force refreshing cache for userId: $userId');
    await Future.wait([
      getMemories(userId, forceRefresh: true),
      getStories(userId, forceRefresh: true),
    ]);
    print('✅ CACHE: Cache refresh complete');
  }

  /// Clear all cached data
  void clearCache() {
    print('🗑️ CACHE: Clearing all cached data');
    _cachedMemories = null;
    _cachedStories = null;
    _cachedUserId = null;
    _lastCacheTime = null;
  }

  /// Load user stories from database
  Future<List<StoryItemModel>> _loadUserStories(String userId) async {
    try {
      final storiesData = await _storyService.fetchUserStories(userId);

      return storiesData.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(storyData['created_at'] as String);

        final backgroundImage = _storyService.getStoryMediaUrl(storyData);
        final profileImage = AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'] as String?,
        );

        final contributorName = contributor?['display_name'] as String? ??
            contributor?['username'] as String? ??
            'Unknown';

        return StoryItemModel(
          id: storyData['id'] as String,
          backgroundImage: backgroundImage,
          profileImage: profileImage,
          timestamp: _storyService.getTimeAgo(createdAt),
          navigateTo: '/story/view',
          memoryId: storyData['memory_id'] as String,
          contributorId: storyData['contributor_id'] as String,
          mediaType: storyData['media_type'] as String? ?? 'video',
          videoUrl: storyData['video_url'] as String? ?? '',
          imageUrl: storyData['image_url'] as String? ?? '',
          contributorName: contributorName,
        );
      }).toList();
    } catch (e) {
      print('❌ CACHE: Error loading user stories: $e');
      return [];
    }
  }

  /// Load user memories from database
  Future<List<MemoryItemModel>> _loadUserMemories(String userId) async {
    try {
      final memoriesData = await _storyService.fetchUserTimelines(userId);

      final allMemories =
          await Future.wait(memoriesData.map((memoryData) async {
        final creator = memoryData['user_profiles'] as Map<String, dynamic>?;
        final category =
            memoryData['memory_categories'] as Map<String, dynamic>?;
        final stories = memoryData['stories'] as List?;
        final createdAt = DateTime.parse(memoryData['created_at'] as String);
        final expiresAt = memoryData['expires_at'] != null
            ? DateTime.parse(memoryData['expires_at'] as String)
            : null;
        final sealedAt = memoryData['sealed_at'] != null
            ? DateTime.parse(memoryData['sealed_at'] as String)
            : null;
        
        // Use start_time/end_time if available, otherwise fall back to created_at/expires_at
        final startTime = memoryData['start_time'] != null
            ? DateTime.parse(memoryData['start_time'] as String)
            : createdAt;
        final endTime = memoryData['end_time'] != null
            ? DateTime.parse(memoryData['end_time'] as String)
            : expiresAt ?? createdAt.add(Duration(hours: 12));

        final memoryThumbnails = stories
                ?.map((story) {
                  return (story['thumbnail_url'] ?? story['image_url'] ?? '')
                      as String;
                })
                .where((url) => url.isNotEmpty)
                .toList() ??
            [];

        final memoryId = memoryData['id'] as String;
        List<String> participantAvatars = [];

        try {
          print('🔍 CACHE: Fetching contributors for memory $memoryId');

          // FIXED: Query memory_contributors table (correct table name from schema)
          // Matches working /feed implementation pattern
          final contributorsResponse = await SupabaseService.instance.client
              ?.from('memory_contributors')
              .select('user_id, user_profiles!inner(avatar_url, display_name)')
              .eq('memory_id', memoryId)
              .order('joined_at', ascending: true);

          if (contributorsResponse != null) {
            print(
                '🔍 CACHE: Retrieved ${contributorsResponse.length} contributors from memory_contributors table');

            // Get current user's avatar URL for filtering
            final currentUserAvatarData = await SupabaseService.instance.client
                ?.from('user_profiles')
                .select('avatar_url')
                .eq('id', userId)
                .maybeSingle();

            final currentUserAvatar = AvatarHelperService.getAvatarUrl(
              currentUserAvatarData?['avatar_url'] as String?,
            );

            print('🔍 CACHE: Current user avatar: $currentUserAvatar');

            // Extract all contributor avatars
            final allContributorAvatars = contributorsResponse
                .map((contributor) {
                  final userProfile =
                      contributor['user_profiles'] as Map<String, dynamic>?;
                  final displayName =
                      userProfile?['display_name'] as String? ?? 'Unknown';
                  final avatarUrl = AvatarHelperService.getAvatarUrl(
                    userProfile?['avatar_url'] as String?,
                  );
                  print(
                      '🔍 CACHE: Contributor "$displayName" has avatar: $avatarUrl');
                  return avatarUrl;
                })
                .where((url) => url.isNotEmpty)
                .toList();

            print(
                '🔍 CACHE: Found ${allContributorAvatars.length} total contributor avatars');

            // Filter out current user and limit to 3 for header display
            participantAvatars = allContributorAvatars
                .where((avatar) => avatar != currentUserAvatar)
                .take(3)
                .toList();

            print(
                '✅ CACHE: Final participant avatars for header (${participantAvatars.length}): $participantAvatars');
          } else {
            print('⚠️ CACHE: No contributors found for memory $memoryId');
          }
        } catch (e) {
          print(
              '❌ CACHE: Error fetching contributor avatars from memory_contributors: $e');
          print('❌ CACHE: Stack trace: ${StackTrace.current}');
        }

        return MemoryItemModel(
          id: memoryData['id'] as String,
          title: memoryData['title'] as String,
          date: _storyService.getTimeAgo(createdAt),
          eventDate: _formatDate(startTime),
          eventTime: _formatTime(startTime),
          endDate: _formatDate(endTime),
          endTime: _formatTime(endTime),
          location: memoryData['location_name'] as String? ?? '',
          state: memoryData['state'] as String,
          visibility: memoryData['visibility'] as String,
          isLive: memoryData['state'] == 'open',
          isSealed: memoryData['state'] == 'sealed',
          categoryName: category?['name'] as String? ?? '',
          categoryIconUrl: category?['icon_url'] as String?,
          creatorId: memoryData['creator_id'] as String,
          creatorName: creator?['display_name'] as String? ??
              creator?['username'] as String? ??
              '',
          creatorAvatar: AvatarHelperService.getAvatarUrl(
            creator?['avatar_url'] as String?,
          ),
          contributorCount: memoryData['contributor_count'] as int? ?? 0,
          expiresAt: expiresAt,
          sealedAt: sealedAt,
          createdAt: createdAt,
          memoryThumbnails: memoryThumbnails,
          participantAvatars: participantAvatars,
        );
      }));

      return allMemories;
    } catch (e) {
      print('❌ CACHE: Error loading user memories: $e');
      return [];
    }
  }

  /// Format date as "Dec 4" format
  String _formatDate(DateTime dateTime) {
    const months = [
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
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  /// Format time as "3:18pm" format
  String _formatTime(DateTime dateTime) {
    var hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    
    return '$hour:${minute.toString().padLeft(2, '0')}$period';
  }

  /// Dispose streams
  void dispose() {
    _memoriesStreamController.close();
    _storiesStreamController.close();
  }
}
