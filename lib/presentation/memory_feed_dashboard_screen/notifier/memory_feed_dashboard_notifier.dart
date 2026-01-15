// lib/presentation/memory_feed_dashboard_screen/notifier/memory_feed_dashboard_notifier.dart

import '../../../core/app_export.dart';
import '../../../services/feed_service.dart';
import '../../../services/supabase_service.dart';
import '../model/memory_feed_dashboard_model.dart';
import '../../../utils/storage_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'memory_feed_dashboard_state.dart';

final memoryFeedDashboardProvider = StateNotifierProvider.autoDispose<
    MemoryFeedDashboardNotifier, MemoryFeedDashboardState>(
  (ref) => MemoryFeedDashboardNotifier(),
);

/// A notifier that manages the state of the MemoryFeedDashboard screen.
class MemoryFeedDashboardNotifier
    extends StateNotifier<MemoryFeedDashboardState> {
  final FeedService _feedService = FeedService();

  // Real-time subscription channels
  RealtimeChannel? _storyViewsSubscription;
  RealtimeChannel? _storiesChannel;
  RealtimeChannel? _memoriesChannel;

  // Lifecycle + pagination
  bool _isDisposed = false;

  /// IMPORTANT: Must match FeedService._pageSize
  static const int _pageSize = 10;

  MemoryFeedDashboardNotifier()
      : super(
          MemoryFeedDashboardState(
            memoryFeedDashboardModel: MemoryFeedDashboardModel(),
          ),
        ) {
    loadInitialData();
    _subscribeToStoryViews();
    _setupRealtimeSubscriptions();
  }

  /// Normalize a visibility value into 'public' | 'private' | ''
  String _normVisibility(dynamic v) {
    return (v ?? '').toString().trim().toLowerCase();
  }

  /// Ensure activeMemories includes `visibility`.
  /// If FeedService didn't include it, fetch visibilities from `memories` and merge.
  /// Ensure activeMemories includes `visibility` and `end_time`.
  /// If FeedService didn't include them, fetch from `memories` and merge.
  /// Also computes `expiration_text` from `end_time` so UI has a stable label.
  Future<List<Map<String, dynamic>>> _hydrateActiveMemoriesWithVisibility(
      dynamic activeMemoriesData,
      ) async {
    final client = SupabaseService.instance.client;
    if (client == null) return const [];

    final List<Map<String, dynamic>> list =
        (activeMemoriesData as List<dynamic>?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
            <Map<String, dynamic>>[];

    if (list.isEmpty) return list;

    final ids = <String>[];
    for (final m in list) {
      final id = (m['id'] ?? m['memory_id'])?.toString();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    if (ids.isEmpty) return list;

    try {
      final rows = await client
          .from('memories')
          .select('id, visibility, end_time')
          .inFilter('id', ids);

      final memMap = <String, Map<String, dynamic>>{};
      for (final row in (rows as List<dynamic>)) {
        final r = (row as Map).cast<String, dynamic>();
        final id = r['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        memMap[id] = r;
      }

      DateTime? parseEndTime(dynamic rawEndTime) {
        if (rawEndTime == null) return null;

        if (rawEndTime is DateTime) return rawEndTime;

        if (rawEndTime is int) {
          final isMillis = rawEndTime > 2000000000;
          return DateTime.fromMillisecondsSinceEpoch(
            isMillis ? rawEndTime : rawEndTime * 1000,
            isUtc: true,
          );
        }

        if (rawEndTime is double) {
          final asInt = rawEndTime.toInt();
          final isMillis = asInt > 2000000000;
          return DateTime.fromMillisecondsSinceEpoch(
            isMillis ? asInt : asInt * 1000,
            isUtc: true,
          );
        }

        final asString = rawEndTime.toString().trim();
        if (asString.isEmpty) return null;

        return DateTime.tryParse(asString);
      }

      final merged = list.map((m) {
        final id = (m['id'] ?? m['memory_id'])?.toString() ?? '';
        final server = memMap[id];

        final existingVis = _normVisibility(m['visibility']);
        final hydratedVis = existingVis.isNotEmpty
            ? existingVis
            : _normVisibility(server?['visibility']);

        final existingEndTime = m['end_time'];
        final hydratedEndTime = (existingEndTime != null &&
            existingEndTime.toString().trim().isNotEmpty)
            ? existingEndTime
            : server?['end_time'];

        final endTimeDt = parseEndTime(hydratedEndTime);
        final expirationText = endTimeDt == null ? '' : _formatExpirationTime(endTimeDt);

        return <String, dynamic>{
          ...m,
          'visibility': hydratedVis,
          'end_time': hydratedEndTime,
          // keep a stable UI string available too
          'expiration_text': expirationText.isNotEmpty ? expirationText : (m['expiration_text'] ?? ''),
        };
      }).toList();

      if (merged.isNotEmpty) {
        for (int i = 0; i < merged.length && i < 3; i++) {
          final mm = merged[i];
          // ignore: avoid_print
          print(
            '✅ ACTIVE MEMORY HYDRATE: title="${mm['title']}" id="${mm['id'] ?? mm['memory_id']}" visibility="${mm['visibility']}" end_time="${mm['end_time']}" expiration_text="${mm['expiration_text']}"',
          );
        }
      }

      return merged;
    } catch (e) {
      // ignore: avoid_print
      print('❌ HYDRATE VISIBILITY/END_TIME FAILED: $e');
      return list;
    }
  }


  /// Load initial data from the database
  Future<void> loadInitialData() async {
    if (_isDisposed) return;

    _safeSetState(
      state.copyWith(isLoading: true, isLoadingActiveMemories: true),
    );

    try {
      // Active memories for current user
      final rawActiveMemoriesData =
          await _feedService.fetchUserActiveMemories();
      final activeMemoriesData =
          await _hydrateActiveMemoriesWithVisibility(rawActiveMemoriesData);

      // Fetch initial page (offset 0) for all feeds
      final happeningNowData = await _feedService.fetchHappeningNowStories(
          offset: 0, limit: _pageSize);
      final latestStoriesData =
          await _feedService.fetchLatestStories(offset: 0, limit: _pageSize);
      final publicMemoriesData =
          await _feedService.fetchPublicMemories(offset: 0, limit: _pageSize);
      final trendingData =
          await _feedService.fetchTrendingStories(offset: 0, limit: _pageSize);
      final longestStreakData = await _feedService.fetchLongestStreakStories(
          offset: 0, limit: _pageSize);
      final popularUserData = await _feedService.fetchPopularUserStories(
          offset: 0, limit: _pageSize);

      // Transform happening now
      final happeningNowStories = happeningNowData.map((item) {
        final categoryIcon = item['category_icon'] as String? ?? '';
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: categoryIcon,
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      // Transform latest
      final latestStories = latestStoriesData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      // Transform public memories
      final publicMemories = publicMemoriesData
          .map((item) => CustomMemoryItem(
                id: item['id'],
                title: item['title'],
                date: item['date'],
                iconPath: item['category_icon'] ?? '',
                profileImages:
                    (item['contributor_avatars'] as List?)?.cast<String>() ??
                        <String>[],
                mediaItems: (item['media_items'] as List?)
                        ?.map((media) => CustomMediaItem(
                              imagePath: media['thumbnail_url'] ?? '',
                              hasPlayButton: media['video_url'] != null,
                            ))
                        .toList() ??
                    <CustomMediaItem>[],
                startDate: item['start_date'],
                startTime: item['start_time'],
                endDate: item['end_date'],
                endTime: item['end_time'],
                location: item['location'],
                distance: '',
                isLiked: false,
              ))
          .toList();

      // Transform trending
      final trendingStories = trendingData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      // Transform longest streak
      final longestStreakStories = longestStreakData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      // Transform popular users
      final popularUserStories = popularUserData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      if (_isDisposed) return;

      // IMPORTANT: keep lists as lists (never null) to make UI deterministic
      final model = MemoryFeedDashboardModel(
        happeningNowStories: happeningNowStories.cast<HappeningNowStoryData>(),
        latestStories: latestStories.cast<HappeningNowStoryData>(),
        publicMemories: publicMemories,
        trendingStories: trendingStories.cast<HappeningNowStoryData>(),
        longestStreakStories:
            longestStreakStories.cast<HappeningNowStoryData>(),
        popularUserStories: popularUserStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(
        state.copyWith(
          memoryFeedDashboardModel: model,
          isLoading: false,
          isLoadingActiveMemories: false,
          activeMemories: activeMemoriesData,
          hasMoreHappeningNow: happeningNowData.length == _pageSize,
          hasMoreLatestStories: latestStoriesData.length == _pageSize,
          hasMorePublicMemories: publicMemoriesData.length == _pageSize,
          hasMoreTrending: trendingData.length == _pageSize,
          hasMoreLongestStreak: longestStreakData.length == _pageSize,
          hasMorePopularUsers: popularUserData.length == _pageSize,
          hasMorePopularMemories: false,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error loading feed data: $e');
      if (!_isDisposed) {
        _safeSetState(
            state.copyWith(isLoading: false, isLoadingActiveMemories: false));
      }
    }
  }

  /// Subscribe to real-time story view updates
  void _subscribeToStoryViews() {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        // ignore: avoid_print
        print(
            'ℹ️ INFO: Real-time subscription skipped (optional - requires authentication)');
        return;
      }

      _storyViewsSubscription = _feedService.subscribeToStoryViews(
        onStoryViewed: (storyId, userId) {
          if (userId == currentUserId) {
            _updateStoryReadStatus(storyId);
          }
        },
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('❌ ERROR subscribing to story views: $e');
      // ignore: avoid_print
      print(st);
    }
  }

  /// Update read status for a specific story in ALL lists (not just happening now)
  void _updateStoryReadStatus(String storyId) {
    final currentModel = state.memoryFeedDashboardModel;
    if (currentModel == null) return;

    bool anyUpdated = false;

    List<HappeningNowStoryData>? updateListIfPresent(
      List<HappeningNowStoryData>? stories,
      String listName,
    ) {
      if (stories == null || stories.isEmpty) return null;

      bool foundInList = false;
      final updated = stories.map((story) {
        if (story.storyId == storyId) {
          foundInList = true;
          return story.copyWith(isRead: true);
        }
        return story;
      }).toList();

      if (foundInList) {
        anyUpdated = true;
        return updated;
      }
      return null;
    }

    final updatedHappeningNow =
        updateListIfPresent(currentModel.happeningNowStories, 'Happening Now');
    final updatedLatest =
        updateListIfPresent(currentModel.latestStories, 'Latest Stories');
    final updatedTrending =
        updateListIfPresent(currentModel.trendingStories, 'Trending');
    final updatedLongestStreak = updateListIfPresent(
        currentModel.longestStreakStories, 'Longest Streak');
    final updatedPopularUsers =
        updateListIfPresent(currentModel.popularUserStories, 'Popular Users');

    if (!anyUpdated) return;

    final updatedModel = currentModel.copyWith(
      happeningNowStories:
          updatedHappeningNow ?? currentModel.happeningNowStories,
      latestStories: updatedLatest ?? currentModel.latestStories,
      trendingStories: updatedTrending ?? currentModel.trendingStories,
      longestStreakStories:
          updatedLongestStreak ?? currentModel.longestStreakStories,
      popularUserStories:
          updatedPopularUsers ?? currentModel.popularUserStories,
    );

    _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Story views subscription
    _feedService.unsubscribeFromStoryViews();

    // Stories + memories realtime subscriptions
    _cleanupSubscriptions();

    super.dispose();
  }

  /// Setup real-time subscriptions for stories and memories
  void _setupRealtimeSubscriptions() {
    final client = SupabaseService.instance.client;
    if (client == null) {
      // ignore: avoid_print
      print('⚠️ REALTIME: Supabase client not available');
      return;
    }

    try {
      _storiesChannel = client
          .channel('public:stories')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'stories',
            callback: _handleNewStory,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'stories',
            callback: _handleStoryUpdate,
          )
          .subscribe();

      _memoriesChannel = client
          .channel('public:memories')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'memories',
            callback: _handleNewMemory,
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'memories',
            callback: _handleMemoryUpdate,
          )
          .subscribe();
    } catch (e) {
      // ignore: avoid_print
      print('❌ REALTIME: Error setting up subscriptions: $e');
    }
  }

  void _cleanupSubscriptions() {
    try {
      _storiesChannel?.unsubscribe();
      _memoriesChannel?.unsubscribe();
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ REALTIME: Error cleaning up subscriptions: $e');
    }
  }

  /// Handle new story inserted
  void _handleNewStory(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    try {
      final storyId = payload.newRecord['id'] as String;
      final contributorId = payload.newRecord['contributor_id'] as String;
      final memoryId = payload.newRecord['memory_id'] as String;
      final rawThumbnailUrl = payload.newRecord['thumbnail_url'] as String?;
      final videoUrl = payload.newRecord['video_url'] as String?;

      final client = SupabaseService.instance.client;
      if (client == null) return;

      // ✅ CRITICAL FIX: Check memory visibility BEFORE proceeding with real-time update
      final memoryVisibilityCheck = await client
          .from('memories')
          .select('visibility')
          .eq('id', memoryId)
          .single();

      if (_isDisposed) return;

      final memoryVisibility =
          _normVisibility(memoryVisibilityCheck['visibility']);

      // ⛔ STOP: If memory is private, do NOT add story to "Happening Now" feed
      if (memoryVisibility != 'public') {
        print(
            '🔒 REALTIME: Skipped private memory story from appearing in real-time feed (memory_id: $memoryId, visibility: $memoryVisibility)');
        return;
      }

      final resolvedThumbnailUrl =
          StorageUtils.resolveStoryMediaUrl(rawThumbnailUrl);

      final profileResponse = await client
          .from('user_profiles')
          .select('id, display_name, avatar_url')
          .eq('id', contributorId)
          .single();

      if (_isDisposed) return;

      final rawAvatarUrl = profileResponse['avatar_url'] as String?;
      final resolvedAvatarUrl = StorageUtils.resolveAvatarUrl(rawAvatarUrl);

      final memoryResponse = await client.from('stories').select('''
            memories!memory_id(
              title,
              memory_categories(
                name,
                icon_url
              )
            )
          ''').eq('id', storyId).single();

      if (_isDisposed) return;

      final newStoryData = HappeningNowStoryData(
        storyId: storyId,
        backgroundImage: resolvedThumbnailUrl ?? '',
        profileImage: resolvedAvatarUrl ?? '',
        userName: profileResponse['display_name'] as String? ?? 'Unknown User',
        categoryName: memoryResponse['memories']['memory_categories']['name']
                as String? ??
            '',
        categoryIcon: memoryResponse['memories']['memory_categories']
                ['icon_url'] as String? ??
            '',
        timestamp: 'Just now',
        isRead: false,
      );

      final currentModel =
          state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel();
      final currentStories =
          currentModel.happeningNowStories ?? <HappeningNowStoryData>[];
      final updatedStories = [newStoryData, ...currentStories];

      // Update memory card media (only if memory is currently in public feed)
      final currentMemories =
          currentModel.publicMemories ?? <CustomMemoryItem>[];
      final memoryIndex = currentMemories.indexWhere((m) => m.id == memoryId);

      List<CustomMemoryItem> updatedMemories = currentMemories;
      if (memoryIndex != -1) {
        final targetMemory = currentMemories[memoryIndex];
        final currentMediaItems =
            targetMemory.mediaItems ?? <CustomMediaItem>[];

        final newMediaItem = CustomMediaItem(
          imagePath: resolvedThumbnailUrl ?? '',
          hasPlayButton: videoUrl != null,
        );

        final updatedMediaItems =
            [newMediaItem, ...currentMediaItems].take(2).toList();

        final updatedMemory =
            targetMemory.copyWith(mediaItems: updatedMediaItems);

        updatedMemories = [...currentMemories];
        updatedMemories[memoryIndex] = updatedMemory;
      }

      final updatedModel = currentModel.copyWith(
        happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
        publicMemories: updatedMemories,
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (e) {
      // ignore: avoid_print
      print('❌ REALTIME: Error handling new story: $e');
    }
  }

  /// Handle story update
  void _handleStoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    try {
      final storyId = payload.newRecord['id'] as String;
      final currentModel = state.memoryFeedDashboardModel;
      if (currentModel == null) return;

      final updatedHappeningNow = _updateStoryInList(
        currentModel.happeningNowStories,
        storyId,
        payload.newRecord,
      );

      final updatedLatest = _updateStoryInList(
        currentModel.latestStories,
        storyId,
        payload.newRecord,
      );

      final updatedTrending = _updateStoryInList(
        currentModel.trendingStories,
        storyId,
        payload.newRecord,
      );

      final updatedModel = currentModel.copyWith(
        happeningNowStories:
            updatedHappeningNow ?? currentModel.happeningNowStories,
        latestStories: updatedLatest ?? currentModel.latestStories,
        trendingStories: updatedTrending ?? currentModel.trendingStories,
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (e) {
      // ignore: avoid_print
      print('❌ REALTIME: Error handling story update: $e');
    }
  }

  /// Handle new memory inserted
  void _handleNewMemory(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    try {
      final memoryId = payload.newRecord['id'] as String;
      final creatorId = payload.newRecord['creator_id'] as String;
      final visibility = _normVisibility(payload.newRecord['visibility']);

      final client = SupabaseService.instance.client;
      if (client == null) return;

      final currentUserId = client.auth.currentUser?.id;

      // Check if current user is a contributor to this memory
      bool isCurrentUserContributor = false;
      if (currentUserId != null) {
        try {
          final contributorCheck = await client
              .from('memory_contributors')
              .select('id')
              .eq('memory_id', memoryId)
              .eq('user_id', currentUserId)
              .maybeSingle();

          isCurrentUserContributor = contributorCheck != null;
        } catch (e) {
          print('⚠️ REALTIME: Failed to check contributor status: $e');
        }
      }

      // If current user is a contributor, update activeMemories list
      if (isCurrentUserContributor) {
        final memoryDetails = await client.from('memories').select('''
              id,
              title,
              state,
              visibility,
              created_at,
              end_time,
              creator_id,
              category_id,
              memory_categories:category_id(
                name,
                icon_url
              ),
              user_profiles_public:creator_id(
                id,
                display_name,
                avatar_url
              )
            ''').eq('id', memoryId).single();

        if (_isDisposed) return;

        final category =
            memoryDetails['memory_categories'] as Map<String, dynamic>?;
        final creator =
            memoryDetails['user_profiles_public'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(memoryDetails['created_at']);
        final endTime = memoryDetails['end_time'] != null
            ? DateTime.parse(memoryDetails['end_time'])
            : null;

        final creatorName = (creator?['display_name'] as String?)?.trim();
        final safeCreatorName = (creatorName != null && creatorName.isNotEmpty)
            ? creatorName
            : null;

        final newActiveMemory = {
          'id': memoryDetails['id'] ?? '',
          'title': memoryDetails['title'] ?? 'Untitled Memory',
          'visibility': memoryDetails['visibility'] ?? 'private',
          'category_name': category?['name'] ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'created_at': memoryDetails['created_at'] ?? '',
          'end_time': memoryDetails['end_time'] ?? '',
          'created_date': _formatDate(createdAt),
          'expiration_text': _formatExpirationTime(endTime),
          'creator_id': memoryDetails['creator_id'],
          'creator_name': safeCreatorName,
        };

        // Add to the beginning of active memories list
        final currentActiveMemories = state.activeMemories;
        final updatedActiveMemories = [
          newActiveMemory,
          ...currentActiveMemories
        ];

        _safeSetState(state.copyWith(activeMemories: updatedActiveMemories));

        print(
            '✅ REALTIME: Added new memory "${newActiveMemory['title']}" to active memories');
      }

      // Continue with existing logic for public feed update
      if (visibility != 'public') return;

      final response = await client.from('memories').select('''
            id,
            title,
            start_time,
            end_time,
            location_name,
            memory_categories(
              icon_url
            ),
            memory_contributors(
              user_profiles(
                avatar_url
              )
            ),
            stories(
              thumbnail_url,
              video_url
            )
          ''').eq('id', memoryId).eq('visibility', 'public').single();

      if (_isDisposed) return;

      final contributors = response['memory_contributors'] as List;
      final stories = response['stories'] as List;

      final newMemoryData = CustomMemoryItem(
        id: response['id'],
        title: response['title'],
        date: DateTime.parse(response['start_time']).toString(),
        iconPath: response['memory_categories']['icon_url'] ?? '',
        profileImages: contributors
            .map((c) => c['user_profiles']['avatar_url'] as String)
            .toList(),
        mediaItems: stories
            .map(
              (s) => CustomMediaItem(
                imagePath: s['thumbnail_url'] ?? '',
                hasPlayButton: s['video_url'] != null,
              ),
            )
            .toList(),
        startDate: response['start_time'],
        startTime: response['start_time'],
        endDate: response['end_time'],
        endTime: response['end_time'],
        location: response['location_name'] ?? '',
        distance: '',
        isLiked: false,
      );

      final currentModel =
          state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel();
      final currentMemories =
          currentModel.publicMemories ?? <CustomMemoryItem>[];
      final updatedMemories = [newMemoryData, ...currentMemories];

      final updatedModel =
          currentModel.copyWith(publicMemories: updatedMemories);
      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (e) {
      // ignore: avoid_print
      print('❌ REALTIME: Error handling new memory: $e');
    }
  }

  /// Handle memory update
  void _handleMemoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    try {
      final memoryId = payload.newRecord['id'] as String;
      final currentModel = state.memoryFeedDashboardModel;
      if (currentModel == null) return;

      final currentMemories =
          currentModel.publicMemories ?? <CustomMemoryItem>[];
      if (currentMemories.isEmpty) return;

      final updatedMemories = currentMemories.map((memory) {
        if (memory.id == memoryId) {
          return memory.copyWith(
            title: payload.newRecord['title'] as String? ?? memory.title,
          );
        }
        return memory;
      }).toList();

      final updatedModel =
          currentModel.copyWith(publicMemories: updatedMemories);
      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (e) {
      // ignore: avoid_print
      print('❌ REALTIME: Error handling memory update: $e');
    }
  }

  /// Helper to update story in a list
  List<HappeningNowStoryData>? _updateStoryInList(
    List<HappeningNowStoryData>? stories,
    String storyId,
    Map<String, dynamic> newRecord,
  ) {
    if (stories == null || stories.isEmpty) return null;

    bool found = false;

    final updated = stories.map((story) {
      if (story.storyId == storyId) {
        found = true;
        final raw = newRecord['thumbnail_url'] as String?;
        final resolved = StorageUtils.resolveStoryMediaUrl(raw) ?? raw ?? '';
        return story.copyWith(backgroundImage: resolved);
      }
      return story;
    }).toList();

    return found ? updated : null;
  }

  /// Safely set state only if notifier is not disposed
  void _safeSetState(MemoryFeedDashboardState newState) {
    if (_isDisposed) return;
    try {
      state = newState;
    } catch (e) {
      if (e.toString().contains('dispose') ||
          e.toString().contains('Bad state')) {
        _isDisposed = true;
        // ignore: avoid_print
        print('⚠️ FEED NOTIFIER: Attempted to set state after dispose');
      } else {
        rethrow;
      }
    }
  }

  // ----------------------------
  // PAGINATION (FIXED OFFSETS)
  // ----------------------------

  /// Load more happening now stories
  Future<void> loadMoreHappeningNow() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreHappeningNow)
      return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories =
          state.memoryFeedDashboardModel?.happeningNowStories ??
              <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData = await _feedService.fetchHappeningNowStories(
          offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(
            state.copyWith(isLoadingMore: false, hasMoreHappeningNow: false));
        return;
      }

      final newStories = newData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
          (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel())
              .copyWith(
        happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreHappeningNow: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('Error loading more happening now: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more latest stories
  Future<void> loadMoreLatestStories() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreLatestStories)
      return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories = state.memoryFeedDashboardModel?.latestStories ??
          <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData = await _feedService.fetchLatestStories(
          offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(
            state.copyWith(isLoadingMore: false, hasMoreLatestStories: false));
        return;
      }

      final newStories = newData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
          (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel())
              .copyWith(
        latestStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreLatestStories: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('Error loading more latest stories: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more public memories
  Future<void> loadMorePublicMemories() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMorePublicMemories) {
      // ignore: avoid_print
      print(
        '🛑 loadMorePublicMemories skipped: _isDisposed=$_isDisposed, isLoadingMore=${state.isLoadingMore}, hasMorePublicMemories=${state.hasMorePublicMemories}',
      );
      return;
    }

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentModel =
          state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel();
      final currentMemories =
          currentModel.publicMemories ?? <CustomMemoryItem>[];
      final offset = currentMemories.length;

      // ignore: avoid_print
      print('🌍 loadMorePublicMemories START offset=$offset limit=$_pageSize');

      final newData = await _feedService.fetchPublicMemories(
          offset: offset, limit: _pageSize);

      // ignore: avoid_print
      print('✅ fetchPublicMemories returned rows=${newData.length}');

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(
            state.copyWith(isLoadingMore: false, hasMorePublicMemories: false));
        return;
      }

      final List<CustomMemoryItem> newMemories =
          newData.map<CustomMemoryItem>((item) {
        return CustomMemoryItem(
          id: item['id'] as String?,
          title: item['title'] as String?,
          date: item['date'] as String?,
          iconPath: (item['category_icon'] as String?) ?? '',
          profileImages:
              (item['contributor_avatars'] as List?)?.cast<String>() ??
                  <String>[],
          mediaItems: (item['media_items'] as List?)
                  ?.map((media) => CustomMediaItem(
                        imagePath: (media['thumbnail_url'] as String?) ?? '',
                        hasPlayButton: media['video_url'] != null,
                      ))
                  .toList() ??
              <CustomMediaItem>[],
          startDate: item['start_date'] as String?,
          startTime: item['start_time'] as String?,
          endDate: item['end_date'] as String?,
          endTime: item['end_time'] as String?,
          location: item['location'] as String?,
          distance: '',
          isLiked: false,
        );
      }).toList();

      final updatedMemories = <CustomMemoryItem>[
        ...currentMemories,
        ...newMemories
      ];

      final updatedModel =
          currentModel.copyWith(publicMemories: updatedMemories);

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePublicMemories: newData.length == _pageSize,
        isLoadingMore: false,
      ));

      // ignore: avoid_print
      print(
        '🏁 loadMorePublicMemories DONE total=${updatedMemories.length} hasMore=${newData.length == _pageSize}',
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('❌ Error loading more public memories: $e');
      // ignore: avoid_print
      print(st);

      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more trending stories
  Future<void> loadMoreTrending() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreTrending) return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories = state.memoryFeedDashboardModel?.trendingStories ??
          <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData = await _feedService.fetchTrendingStories(
          offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(
            state.copyWith(isLoadingMore: false, hasMoreTrending: false));
        return;
      }

      final newStories = newData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
          (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel())
              .copyWith(
        trendingStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreTrending: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('Error loading more trending: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more longest streak stories
  Future<void> loadMoreLongestStreak() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreLongestStreak)
      return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories =
          state.memoryFeedDashboardModel?.longestStreakStories ??
              <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData = await _feedService.fetchLongestStreakStories(
          offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(
            state.copyWith(isLoadingMore: false, hasMoreLongestStreak: false));
        return;
      }

      final newStories = newData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
          (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel())
              .copyWith(
        longestStreakStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreLongestStreak: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('Error loading more longest streak: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more popular user stories
  Future<void> loadMorePopularUsers() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMorePopularUsers)
      return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories =
          state.memoryFeedDashboardModel?.popularUserStories ??
              <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData = await _feedService.fetchPopularUserStories(
          offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(
            state.copyWith(isLoadingMore: false, hasMorePopularUsers: false));
        return;
      }

      final newStories = newData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
          (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel())
              .copyWith(
        popularUserStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePopularUsers: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('Error loading more popular users: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more popular memories (if you actually show a separate "popular memories" list)
  /// NOTE: This method assumes you want to append to the same publicMemories list.
  /// If you have a separate list in the model for popular memories, wire it there instead.
  Future<void> loadMorePopularMemories() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMorePopularMemories)
      return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentModel =
          state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel();
      final currentMemories =
          currentModel.publicMemories ?? <CustomMemoryItem>[];
      final offset = currentMemories.length;

      final newData = await _feedService.fetchPopularMemories(
          offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(state.copyWith(
            isLoadingMore: false, hasMorePopularMemories: false));
        return;
      }

      final newMemories = newData.map((item) {
        return CustomMemoryItem(
          id: item['id'],
          title: item['title'],
          date: item['date'],
          iconPath: item['category_icon'] ?? '',
          profileImages:
              (item['contributor_avatars'] as List?)?.cast<String>() ??
                  <String>[],
          mediaItems: (item['media_items'] as List?)
                  ?.map((media) => CustomMediaItem(
                        imagePath: media['thumbnail_url'] ?? '',
                        hasPlayButton: media['video_url'] != null,
                      ))
                  .toList() ??
              <CustomMediaItem>[],
          startDate: item['start_date'],
          startTime: item['start_time'],
          endDate: item['end_date'],
          endTime: item['end_time'],
          location: item['location'],
          distance: '',
          isLiked: false,
        );
      }).toList();

      final updatedMemories = [...currentMemories, ...newMemories];

      final updatedModel =
          currentModel.copyWith(publicMemories: updatedMemories);

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePopularMemories: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('Error loading more popular memories: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  // ----------------------------
  // OTHER ACTIONS
  // ----------------------------

  Future<void> refreshFeed() async {
    if (_isDisposed) return;
    _safeSetState(state.copyWith(isLoading: true));

    try {
      await loadInitialData();
      if (!_isDisposed) {
        _safeSetState(state.copyWith(isLoading: false));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error refreshing feed: $e');
      if (!_isDisposed) {
        _safeSetState(state.copyWith(isLoading: false));
      }
    }
  }

  void markStoryAsViewed(String storyId) {
    if (_isDisposed) return;

    try {
      final currentModel = state.memoryFeedDashboardModel;
      final currentStories =
          currentModel?.happeningNowStories ?? <HappeningNowStoryData>[];
      if (currentStories.isEmpty) return;

      final updatedStories = currentStories.map((story) {
        if (story.storyId == storyId) return story.copyWith(isRead: true);
        return story;
      }).toList();

      final updatedModel =
          (currentModel ?? MemoryFeedDashboardModel()).copyWith(
        happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (_) {
      // ignore
    }
  }

  void toggleMemoryLike(String memoryId) {
    if (_isDisposed) return;

    try {
      final currentModel = state.memoryFeedDashboardModel;
      final currentMemories =
          currentModel?.publicMemories ?? <CustomMemoryItem>[];
      if (currentMemories.isEmpty) return;

      final updatedMemories = currentMemories.map((memory) {
        if (memory.id == memoryId) {
          return memory.copyWith(isLiked: !(memory.isLiked ?? false));
        }
        return memory;
      }).toList();

      final updatedModel =
          (currentModel ?? MemoryFeedDashboardModel()).copyWith(
        publicMemories: updatedMemories,
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (_) {
      // ignore
    }
  }

  /// Helper method to calculate relative time
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  /// Helper method to format date
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Helper method to format expiration time
  String _formatExpirationTime(DateTime? endTime) {
    if (endTime == null) return 'No expiration';

    final nowUtc = DateTime.now().toUtc();
    final endUtc = endTime.isUtc ? endTime : endTime.toUtc();

    final diff = endUtc.difference(nowUtc);

    if (diff.inSeconds <= 0) return 'Expired';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days >= 1) {
      if (hours == 0) {
        return 'Expires in ${days}d';
      }
      return 'Expires in ${days}d ${hours}h';
    }

    if (diff.inHours >= 1) {
      return 'Expires in ${diff.inHours}h ${minutes}m';
    }

    return 'Expires in ${diff.inMinutes}m';
  }



  Future<void> loadCategories() async {
    try {
      _safeSetState(state.copyWith(isLoadingCategories: true));

      final client = SupabaseService.instance.client;
      if (client == null) {
        _safeSetState(
            state.copyWith(isLoadingCategories: false, categories: []));
        return;
      }

      final response = await client
          .from('memory_categories')
          .select('id, name, tagline, icon_url, display_order')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final categories = (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();

      _safeSetState(state.copyWith(
        isLoadingCategories: false,
        categories: categories,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('Error loading categories: $e');
      _safeSetState(state.copyWith(
        isLoadingCategories: false,
        categories: [],
      ));
    }
  }
}
