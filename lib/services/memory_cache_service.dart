import 'dart:async';

import '../presentation/memories_dashboard_screen/models/memory_item_model.dart';
import '../presentation/memories_dashboard_screen/models/story_item_model.dart';
import './avatar_helper_service.dart';
import './story_service.dart';
import './supabase_service.dart';

/// In-memory cache service for memory objects with auto-refresh functionality.
/// Fixes deadlocks by removing custom RW locks and using in-flight request dedupe.
/// Ensures navigating away/back cannot wedge the cache.
class MemoryCacheService {
  static final MemoryCacheService _instance = MemoryCacheService._internal();
  factory MemoryCacheService() => _instance;
  MemoryCacheService._internal();

  final _storyService = StoryService();

  // Cache storage (single-user app assumption; keyed by userId)
  List<MemoryItemModel>? _cachedMemories;
  List<StoryItemModel>? _cachedStories;
  String? _cachedUserId;
  DateTime? _lastCacheTime;

  // Cache configuration
  static const _cacheDuration = Duration(minutes: 5);

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  // Debouncing for rapid cache refreshes
  Timer? _refreshDebounceTimer;
  static const _refreshDebounceDuration = Duration(milliseconds: 500);

  // In-flight request dedupe (prevents overlapping loads + wedges)
  Future<List<MemoryItemModel>>? _memoriesInFlight;
  Future<List<StoryItemModel>>? _storiesInFlight;

  // Optimistic update tracking
  final Map<String, dynamic> _pendingUpdates = {};

  // Stream controllers for cache updates
  final _memoriesStreamController =
  StreamController<List<MemoryItemModel>>.broadcast();
  final _storiesStreamController =
  StreamController<List<StoryItemModel>>.broadcast();

  Stream<List<MemoryItemModel>> get memoriesStream =>
      _memoriesStreamController.stream;
  Stream<List<StoryItemModel>> get storiesStream =>
      _storiesStreamController.stream;

  bool _isCacheValid(String userId) {
    if (_cachedMemories == null || _cachedStories == null) return false;
    if (_cachedUserId != userId) return false;
    if (_lastCacheTime == null) return false;

    final cacheAge = DateTime.now().difference(_lastCacheTime!);
    return cacheAge < _cacheDuration;
  }

  /// Public: get memories with cache + deduped fetch
  Future<List<MemoryItemModel>> getMemories(
      String userId, {
        bool forceRefresh = false,
      }) async {
    print('🔍 CACHE: getMemories called for userId: $userId (forceRefresh=$forceRefresh)');

    // If switching users, hard reset cache and in-flight
    if (_cachedUserId != null && _cachedUserId != userId) {
      print('🔄 CACHE: User changed ($_cachedUserId -> $userId). Clearing cache.');
      clearCache();
      _cachedUserId = userId;
    }

    // Return cache if valid
    if (!forceRefresh && _isCacheValid(userId)) {
      print('✅ CACHE: Returning cached memories (${_cachedMemories!.length})');
      return _cachedMemories!;
    }

    // If a fetch is already in-flight, await it instead of starting another
    if (_memoriesInFlight != null) {
      print('⏳ CACHE: Awaiting in-flight memories request...');
      return _memoriesInFlight!;
    }

    // Start a new fetch
    _memoriesInFlight = _retryOperation(
          () => _loadUserMemories(userId),
      'load memories',
    ).then((memories) {
      _cachedUserId = userId;
      _cachedMemories = memories;
      _lastCacheTime = DateTime.now();
      _memoriesStreamController.add(memories);
      print('✅ CACHE: Cached ${memories.length} memories');
      return memories;
    }).catchError((e, st) {
      print('❌ CACHE: getMemories failed: $e');
      // Do NOT poison cache; just clear inflight and rethrow
      throw e;
    }).whenComplete(() {
      _memoriesInFlight = null;
    });

    return _memoriesInFlight!;
  }

  /// Public: get stories with cache + deduped fetch
  Future<List<StoryItemModel>> getStories(
      String userId, {
        bool forceRefresh = false,
      }) async {
    print('🔍 CACHE: getStories called for userId: $userId (forceRefresh=$forceRefresh)');

    // If switching users, hard reset cache and in-flight
    if (_cachedUserId != null && _cachedUserId != userId) {
      print('🔄 CACHE: User changed ($_cachedUserId -> $userId). Clearing cache.');
      clearCache();
      _cachedUserId = userId;
    }

    // Return cache if valid
    if (!forceRefresh && _isCacheValid(userId)) {
      print('✅ CACHE: Returning cached stories (${_cachedStories!.length})');
      return _cachedStories!;
    }

    // If a fetch is already in-flight, await it instead of starting another
    if (_storiesInFlight != null) {
      print('⏳ CACHE: Awaiting in-flight stories request...');
      return _storiesInFlight!;
    }

    // Start a new fetch
    _storiesInFlight = _retryOperation(
          () => _loadUserStories(userId),
      'load stories',
    ).then((stories) {
      _cachedUserId = userId;
      _cachedStories = stories;
      _lastCacheTime = DateTime.now();
      _storiesStreamController.add(stories);
      print('✅ CACHE: Cached ${stories.length} stories');
      return stories;
    }).catchError((e, st) {
      print('❌ CACHE: getStories failed: $e');
      throw e;
    }).whenComplete(() {
      _storiesInFlight = null;
    });

    return _storiesInFlight!;
  }

  /// Retry operation with exponential backoff
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
          print('❌ CACHE: Failed to $operationName after $attempt attempts: $e');
          rethrow;
        }

        print('⚠️ CACHE: Attempt $attempt to $operationName failed: $e');
        print('🔄 CACHE: Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  /// Debounced refresh. IMPORTANT: no locks. Just forceRefresh loads.
  Future<void> refreshMemoryCache(String userId) async {
    print('🔄 CACHE: Debounced refresh requested for userId: $userId');

    _refreshDebounceTimer?.cancel();

    final completer = Completer<void>();

    _refreshDebounceTimer = Timer(_refreshDebounceDuration, () async {
      print('🔄 CACHE: Executing debounced refresh');

      try {
        // Force refresh both; in-flight dedupe will prevent overlaps
        await Future.wait([
          getMemories(userId, forceRefresh: true),
          getStories(userId, forceRefresh: true),
        ]);
        print('✅ CACHE: Debounced refresh complete');
        completer.complete();
      } catch (e) {
        print('❌ CACHE: Debounced refresh failed: $e');
        if (!completer.isCompleted) completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// Optimistic update (tracking only; keep your current behavior)
  void optimisticUpdate(String itemId, Map<String, dynamic> updates) {
    print('⚡ CACHE: Optimistic update for item $itemId');
    _pendingUpdates[itemId] = updates;
  }

  void confirmOptimisticUpdate(String itemId) {
    print('✅ CACHE: Confirmed optimistic update for item $itemId');
    _pendingUpdates.remove(itemId);
  }

  Future<void> rollbackOptimisticUpdate(String itemId, String userId) async {
    print('⚠️ CACHE: Rolling back optimistic update for item $itemId');
    _pendingUpdates.remove(itemId);
    await refreshMemoryCache(userId);
  }

  /// Clear all cached data
  void clearCache() {
    print('🗑️ CACHE: Clearing all cached data');
    _refreshDebounceTimer?.cancel();

    _cachedMemories = null;
    _cachedStories = null;
    _cachedUserId = null;
    _lastCacheTime = null;

    _memoriesInFlight = null;
    _storiesInFlight = null;

    _pendingUpdates.clear();
  }

  /// Load user stories from database
  Future<List<StoryItemModel>> _loadUserStories(String userId) async {
    try {
      final storiesData = await _storyService.fetchUserStories(userId);

      final storyIds = storiesData.map((s) => s['id'] as String).toList();

      Set<String> viewedStoryIds = {};
      if (storyIds.isNotEmpty) {
        final viewsResponse = await SupabaseService.instance.client
            ?.from('story_views')
            .select('story_id')
            .eq('user_id', userId)
            .inFilter('story_id', storyIds);

        if (viewsResponse != null) {
          viewedStoryIds =
              viewsResponse.map((view) => view['story_id'] as String).toSet();
          print('🔍 CACHE: Found ${viewedStoryIds.length} viewed stories for user');
        }
      }

      return storiesData.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(storyData['created_at'] as String);
        final storyId = storyData['id'] as String;

        final backgroundImage = _storyService.getStoryMediaUrl(storyData);
        final profileImage = AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'] as String?,
        );

        final contributorName = contributor?['display_name'] as String? ??
            contributor?['username'] as String? ??
            'Unknown';

        final isRead = viewedStoryIds.contains(storyId);

        return StoryItemModel(
          id: storyId,
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
          isRead: isRead,
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

        DateTime createdAt;
        DateTime? expiresAt;
        DateTime? sealedAt;
        DateTime startTime;
        DateTime endTime;

        try {
          createdAt = DateTime.parse(memoryData['created_at'] as String);
        } catch (_) {
          createdAt = DateTime.now();
        }

        try {
          expiresAt = memoryData['expires_at'] != null
              ? DateTime.parse(memoryData['expires_at'] as String)
              : null;
        } catch (_) {
          expiresAt = null;
        }

        try {
          sealedAt = memoryData['sealed_at'] != null
              ? DateTime.parse(memoryData['sealed_at'] as String)
              : null;
        } catch (_) {
          sealedAt = null;
        }

        try {
          startTime = memoryData['start_time'] != null
              ? DateTime.parse(memoryData['start_time'] as String)
              : createdAt;
        } catch (_) {
          startTime = createdAt;
        }

        try {
          endTime = memoryData['end_time'] != null
              ? DateTime.parse(memoryData['end_time'] as String)
              : (expiresAt ?? createdAt.add(const Duration(hours: 12)));
        } catch (_) {
          endTime = expiresAt ?? createdAt.add(const Duration(hours: 12));
        }

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
          final contributorsResponse = await SupabaseService.instance.client
              ?.from('memory_contributors')
              .select('user_id, user_profiles!inner(avatar_url, display_name)')
              .eq('memory_id', memoryId)
              .order('joined_at', ascending: true);

          if (contributorsResponse != null) {
            final currentUserAvatarData = await SupabaseService.instance.client
                ?.from('user_profiles')
                .select('avatar_url')
                .eq('id', userId)
                .maybeSingle();

            final currentUserAvatar = AvatarHelperService.getAvatarUrl(
              currentUserAvatarData?['avatar_url'] as String?,
            );

            final allContributorAvatars = contributorsResponse
                .map((contributor) {
              final userProfile =
              contributor['user_profiles'] as Map<String, dynamic>?;
              return AvatarHelperService.getAvatarUrl(
                userProfile?['avatar_url'] as String?,
              );
            })
                .where((url) => url.isNotEmpty)
                .toList();

            participantAvatars = allContributorAvatars
                .where((avatar) => avatar != currentUserAvatar)
                .take(3)
                .toList();
          }
        } catch (e) {
          print('❌ CACHE: Error fetching contributor avatars: $e');
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

      allMemories.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.now();
        final dateB = b.createdAt ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      print('✅ CACHE: Sorted ${allMemories.length} memories by newest first');
      return allMemories;
    } catch (e) {
      print('❌ CACHE: Error loading user memories: $e');
      return [];
    }
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

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

  void dispose() {
    _refreshDebounceTimer?.cancel();
    _memoriesStreamController.close();
    _storiesStreamController.close();
  }
}
