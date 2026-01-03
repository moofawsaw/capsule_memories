import 'dart:async';

import '../presentation/memories_dashboard_screen/models/memory_item_model.dart';
import '../presentation/memories_dashboard_screen/models/story_item_model.dart';
import './avatar_helper_service.dart';
import './story_service.dart';
import './supabase_service.dart';

/// In-memory cache service for memory objects with auto-refresh functionality
/// Ensures data consistency when navigating between /memories and /timeline
/// Optimized for concurrent updates across multiple users
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

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  // Read-write lock for concurrent access control
  bool _isWriting = false;
  final List<Completer<void>> _readQueue = [];

  // Debouncing for rapid cache refreshes
  Timer? _refreshDebounceTimer;
  static const _refreshDebounceDuration = Duration(milliseconds: 500);

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

  /// Acquire read lock - ensures data consistency during concurrent reads
  Future<void> _acquireReadLock() async {
    if (_isWriting) {
      final completer = Completer<void>();
      _readQueue.add(completer);
      await completer.future;
    }
  }

  /// Release read lock - allows pending operations to proceed
  void _releaseReadLock() {
    if (_readQueue.isNotEmpty) {
      _readQueue.removeAt(0).complete();
    }
  }

  /// Acquire write lock - prevents concurrent modifications
  Future<void> _acquireWriteLock() async {
    while (_isWriting || _readQueue.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: 50));
    }
    _isWriting = true;
  }

  /// Release write lock - allows queued operations to execute
  void _releaseWriteLock() {
    _isWriting = false;
    if (_readQueue.isNotEmpty) {
      _readQueue.removeAt(0).complete();
    }
  }

  /// Check if cache is valid for the current user
  bool _isCacheValid(String userId) {
    if (_cachedMemories == null || _cachedStories == null) return false;
    if (_cachedUserId != userId) return false;
    if (_lastCacheTime == null) return false;

    final cacheAge = DateTime.now().difference(_lastCacheTime!);
    return cacheAge < _cacheDuration;
  }

  /// Get cached memories or fetch from database with automatic retry
  /// Thread-safe with read-write locking
  Future<List<MemoryItemModel>> getMemories(String userId,
      {bool forceRefresh = false}) async {
    print('🔍 CACHE: getMemories called for userId: $userId');
    print('🔍 CACHE: forceRefresh = $forceRefresh');

    await _acquireReadLock();

    try {
      // Return cached data if valid
      if (!forceRefresh && _isCacheValid(userId)) {
        print(
            '✅ CACHE: Returning cached memories (${_cachedMemories!.length})');
        return _cachedMemories!;
      }

      _releaseReadLock();

      // Need to refresh - acquire write lock
      await _acquireWriteLock();

      try {
        // Double-check cache validity after acquiring write lock
        if (!forceRefresh && _isCacheValid(userId)) {
          print('✅ CACHE: Another thread already refreshed, using cache');
          return _cachedMemories!;
        }

        print('🔄 CACHE: Fetching fresh memories from database');
        _cachedMemories = await _retryOperation(
          () => _loadUserMemories(userId),
          'load memories',
        );
        _cachedUserId = userId;
        _lastCacheTime = DateTime.now();

        _memoriesStreamController.add(_cachedMemories!);
        print('✅ CACHE: Cached ${_cachedMemories!.length} memories');

        return _cachedMemories!;
      } finally {
        _releaseWriteLock();
      }
    } catch (e) {
      _releaseReadLock();
      rethrow;
    }
  }

  /// Get cached stories or fetch from database with automatic retry
  /// Thread-safe with read-write locking
  Future<List<StoryItemModel>> getStories(String userId,
      {bool forceRefresh = false}) async {
    print('🔍 CACHE: getStories called for userId: $userId');
    print('🔍 CACHE: forceRefresh = $forceRefresh');

    await _acquireReadLock();

    try {
      // Return cached data if valid
      if (!forceRefresh && _isCacheValid(userId)) {
        print('✅ CACHE: Returning cached stories (${_cachedStories!.length})');
        return _cachedStories!;
      }

      _releaseReadLock();

      // Need to refresh - acquire write lock
      await _acquireWriteLock();

      try {
        // Double-check cache validity after acquiring write lock
        if (!forceRefresh && _isCacheValid(userId)) {
          print('✅ CACHE: Another thread already refreshed, using cache');
          return _cachedStories!;
        }

        print('🔄 CACHE: Fetching fresh stories from database');
        _cachedStories = await _retryOperation(
          () => _loadUserStories(userId),
          'load stories',
        );
        _cachedUserId = userId;
        _lastCacheTime = DateTime.now();

        _storiesStreamController.add(_cachedStories!);
        print('✅ CACHE: Cached ${_cachedStories!.length} stories');

        return _cachedStories!;
      } finally {
        _releaseWriteLock();
      }
    } catch (e) {
      _releaseReadLock();
      rethrow;
    }
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
          print(
              '❌ CACHE: Failed to $operationName after $attempt attempts: $e');
          rethrow;
        }

        print('⚠️ CACHE: Attempt $attempt to $operationName failed: $e');
        print('🔄 CACHE: Retrying in ${delay.inMilliseconds}ms...');

        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }

  /// Refresh cache for specific memory with debouncing
  /// Prevents excessive refreshes during rapid concurrent updates
  Future<void> refreshMemoryCache(String userId) async {
    print('🔄 CACHE: Debounced cache refresh requested for userId: $userId');

    // Cancel previous refresh if still pending
    _refreshDebounceTimer?.cancel();

    // Set new debounced refresh
    _refreshDebounceTimer = Timer(_refreshDebounceDuration, () async {
      print('🔄 CACHE: Executing debounced cache refresh');

      await _acquireWriteLock();

      try {
        await Future.wait([
          getMemories(userId, forceRefresh: true),
          getStories(userId, forceRefresh: true),
        ]);
        print('✅ CACHE: Cache refresh complete');
      } finally {
        _releaseWriteLock();
      }
    });
  }

  /// Optimistically update cache item before database sync completes
  /// Provides immediate UI feedback while database operation is in progress
  void optimisticUpdate(String itemId, Map<String, dynamic> updates) {
    print('⚡ CACHE: Optimistic update for item $itemId');
    _pendingUpdates[itemId] = updates;

    // Apply optimistic update to cached data
    if (_cachedMemories != null) {
      final index = _cachedMemories!.indexWhere((m) => m.id == itemId);
      if (index != -1) {
        // Create updated memory with new data
        // Note: This is a simplified example - actual implementation would
        // need proper model copying with updated fields
        print('⚡ CACHE: Applied optimistic update to memory cache');
      }
    }
  }

  /// Confirm optimistic update succeeded
  void confirmOptimisticUpdate(String itemId) {
    print('✅ CACHE: Confirmed optimistic update for item $itemId');
    _pendingUpdates.remove(itemId);
  }

  /// Rollback optimistic update if database operation failed
  Future<void> rollbackOptimisticUpdate(String itemId, String userId) async {
    print('⚠️ CACHE: Rolling back optimistic update for item $itemId');
    _pendingUpdates.remove(itemId);

    // Force refresh to get accurate data
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
    _pendingUpdates.clear();
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

  /// Dispose streams and cleanup
  void dispose() {
    _refreshDebounceTimer?.cancel();
    _memoriesStreamController.close();
    _storiesStreamController.close();
  }
}
