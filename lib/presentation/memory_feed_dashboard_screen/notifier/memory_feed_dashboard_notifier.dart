import '../../../core/app_export.dart';
import '../../../services/feed_service.dart';
import '../../../services/supabase_service.dart';
import '../model/memory_feed_dashboard_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'memory_feed_dashboard_state.dart';

final memoryFeedDashboardProvider = StateNotifierProvider.autoDispose<
    MemoryFeedDashboardNotifier, MemoryFeedDashboardState>(
  (ref) => MemoryFeedDashboardNotifier(MemoryFeedDashboardState(
    memoryFeedDashboardModel: MemoryFeedDashboardModel(),
  )),
);

/// A notifier that manages the state of the MemoryFeedDashboard screen.
class MemoryFeedDashboardNotifier
    extends StateNotifier<MemoryFeedDashboardState> {
  MemoryFeedDashboardNotifier(MemoryFeedDashboardState state) : super(state) {
    loadFeedData();
    _setupRealtimeSubscriptions();
  }

  final _feedService = FeedService();
  bool _isDisposed = false;
  static const int _pageSize = 10;

  // Real-time subscription channels
  RealtimeChannel? _storiesChannel;
  RealtimeChannel? _memoriesChannel;

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupSubscriptions();
    super.dispose();
  }

  /// Setup real-time subscriptions for stories and memories
  void _setupRealtimeSubscriptions() {
    final client = SupabaseService.instance.client;
    if (client == null) {
      print('⚠️ REALTIME: Supabase client not available');
      return;
    }

    try {
      // Subscribe to new stories
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

      // Subscribe to memory updates
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

      print('✅ REALTIME: Subscriptions setup complete');
    } catch (e) {
      print('❌ REALTIME: Error setting up subscriptions: $e');
    }
  }

  /// Cleanup real-time subscriptions
  void _cleanupSubscriptions() {
    try {
      _storiesChannel?.unsubscribe();
      _memoriesChannel?.unsubscribe();
      print('✅ REALTIME: Subscriptions cleaned up');
    } catch (e) {
      print('⚠️ REALTIME: Error cleaning up subscriptions: $e');
    }
  }

  /// Handle new story inserted
  void _handleNewStory(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    print('🔔 REALTIME: New story detected: ${payload.newRecord['id']}');

    try {
      // Fetch full story details with joins
      final storyId = payload.newRecord['id'] as String;
      final client = SupabaseService.instance.client;

      if (client == null) return;

      final response = await client.from('stories').select('''
            id,
            thumbnail_url,
            video_url,
            created_at,
            contributor_id,
            memory_id,
            user_profiles!contributor_id(
              avatar_url,
              display_name
            ),
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
        id: response['id'] as String,
        backgroundImage: response['thumbnail_url'] as String,
        profileImage: response['user_profiles']['avatar_url'] as String,
        userName: response['user_profiles']['display_name'] as String,
        categoryName:
            response['memories']['memory_categories']['name'] as String,
        categoryIcon:
            response['memories']['memory_categories']['icon_url'] as String? ??
                '',
        timestamp: 'Just now',
        isViewed: false,
      );

      // Add to happening now at the beginning
      final currentStories =
          state.memoryFeedDashboardModel?.happeningNowStories ?? [];
      final updatedStories = [newStoryData, ...currentStories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));

      print('✅ REALTIME: New story added to feed');
    } catch (e) {
      print('❌ REALTIME: Error handling new story: $e');
    }
  }

  /// Handle story update
  void _handleStoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    print('🔔 REALTIME: Story updated: ${payload.newRecord['id']}');

    try {
      final storyId = payload.newRecord['id'] as String;
      final currentModel = state.memoryFeedDashboardModel;

      if (currentModel == null) return;

      // Update story in all lists that might contain it
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
        happeningNowStories: updatedHappeningNow?.cast<HappeningNowStoryData>(),
        latestStories: updatedLatest?.cast<HappeningNowStoryData>(),
        trendingStories: updatedTrending?.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));

      print('✅ REALTIME: Story updated in feed');
    } catch (e) {
      print('❌ REALTIME: Error handling story update: $e');
    }
  }

  /// Handle new memory inserted
  void _handleNewMemory(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    print('🔔 REALTIME: New memory detected: ${payload.newRecord['id']}');

    try {
      // Fetch full memory details
      final memoryId = payload.newRecord['id'] as String;
      final client = SupabaseService.instance.client;

      if (client == null) return;

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
            .map((s) => CustomMediaItem(
                  imagePath: s['thumbnail_url'] ?? '',
                  hasPlayButton: s['video_url'] != null,
                ))
            .toList(),
        startDate: response['start_time'],
        startTime: response['start_time'],
        endDate: response['end_time'],
        endTime: response['end_time'],
        location: response['location_name'] ?? '',
        distance: '',
        isLiked: false,
      );

      // Add to public memories at the beginning
      final currentMemories =
          state.memoryFeedDashboardModel?.publicMemories ?? [];
      final updatedMemories = [newMemoryData, ...currentMemories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        publicMemories: updatedMemories,
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));

      print('✅ REALTIME: New memory added to feed');
    } catch (e) {
      print('❌ REALTIME: Error handling new memory: $e');
    }
  }

  /// Handle memory update
  void _handleMemoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    print('🔔 REALTIME: Memory updated: ${payload.newRecord['id']}');

    try {
      final memoryId = payload.newRecord['id'] as String;
      final currentModel = state.memoryFeedDashboardModel;

      if (currentModel == null || currentModel.publicMemories == null) return;

      // Update memory in public memories list
      final updatedMemories = currentModel.publicMemories!.map((memory) {
        if (memory.id == memoryId) {
          return memory.copyWith(
            title: payload.newRecord['title'] as String? ?? memory.title,
          );
        }
        return memory;
      }).toList();

      final updatedModel = currentModel.copyWith(
        publicMemories: updatedMemories,
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));

      print('✅ REALTIME: Memory updated in feed');
    } catch (e) {
      print('❌ REALTIME: Error handling memory update: $e');
    }
  }

  /// Helper to update story in a list
  List<HappeningNowStoryData>? _updateStoryInList(
    List<HappeningNowStoryData>? stories,
    String storyId,
    Map<String, dynamic> newRecord,
  ) {
    if (stories == null) return null;

    bool found = false;
    final updated = stories.map((story) {
      if (story.id == storyId) {
        found = true;
        return story.copyWith(
          backgroundImage:
              newRecord['thumbnail_url'] as String? ?? story.backgroundImage,
        );
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
      // Notifier was disposed, ignore BadState exception
      if (e.toString().contains('dispose') ||
          e.toString().contains('Bad state')) {
        _isDisposed = true;
        print('⚠️ FEED NOTIFIER: Attempted to set state after dispose');
      } else {
        rethrow;
      }
    }
  }

  /// Load initial feed data from the database
  Future<void> loadFeedData() async {
    if (_isDisposed) return;
    _safeSetState(state.copyWith(isLoading: true));

    try {
      // Fetch active memories for the current user
      final activeMemoriesData = await _feedService.fetchUserActiveMemories();

      // Fetch initial page (offset 0) for all feeds
      final happeningNowData = await _feedService.fetchHappeningNowStories();
      final latestStoriesData = await _feedService.fetchLatestStories();
      final publicMemoriesData = await _feedService.fetchPublicMemories();
      final trendingData = await _feedService.fetchTrendingStories();
      final longestStreakData = await _feedService.fetchLongestStreakStories();
      final popularUserData = await _feedService.fetchPopularUserStories();

      // Debug: Log what we received from service
      print(
          '🔍 DEBUG: Notifier received ${happeningNowData.length} happening now stories');
      print(
          '🔍 DEBUG: Notifier received ${latestStoriesData.length} latest stories');

      // Transform to model objects - NOW INCLUDING categoryIcon
      final happeningNowStories = happeningNowData.map((item) {
        final categoryIcon = item['category_icon'] as String? ?? '';
        print(
            '🔍 DEBUG: Creating HappeningNowStoryData with categoryIcon: "$categoryIcon"');

        return HappeningNowStoryData(
          id: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: categoryIcon,
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isViewed: false,
        );
      }).toList();

      // Debug: Verify transformed stories have icons
      print('🔍 DEBUG: Transformed ${happeningNowStories.length} stories');
      for (final story in happeningNowStories) {
        print('🔍 DEBUG: Story model categoryIcon: "${story.categoryIcon}"');
      }

      // Transform latest stories
      final latestStories = latestStoriesData
          .map((item) => HappeningNowStoryData(
                id: item['id'] as String,
                backgroundImage: item['thumbnail_url'] as String,
                profileImage: item['contributor_avatar'] as String,
                userName: item['contributor_name'] as String,
                categoryName: item['category_name'] as String,
                categoryIcon: item['category_icon'] as String? ?? '',
                timestamp: _getRelativeTime(
                    DateTime.parse(item['created_at'] as String)),
                isViewed: false,
              ))
          .toList();

      final publicMemories = publicMemoriesData
          .map((item) => CustomMemoryItem(
                id: item['id'],
                title: item['title'],
                date: item['date'],
                iconPath: item['category_icon'] ?? '',
                profileImages:
                    (item['contributor_avatars'] as List?)?.cast<String>() ??
                        [],
                mediaItems: (item['media_items'] as List?)
                        ?.map((media) => CustomMediaItem(
                              imagePath: media['thumbnail_url'] ?? '',
                              hasPlayButton: media['video_url'] != null,
                            ))
                        .toList() ??
                    [],
                startDate: item['start_date'],
                startTime: item['start_time'],
                endDate: item['end_date'],
                endTime: item['end_time'],
                location: item['location'],
                distance: '',
                isLiked: false,
              ))
          .toList();

      // Transform trending stories - NOW INCLUDING categoryIcon
      final trendingStories = trendingData
          .map((item) => HappeningNowStoryData(
                id: item['id'] as String,
                backgroundImage: item['thumbnail_url'] as String,
                profileImage: item['contributor_avatar'] as String,
                userName: item['contributor_name'] as String,
                categoryName: item['category_name'] as String,
                categoryIcon: item['category_icon'] as String? ?? '',
                timestamp: _getRelativeTime(
                    DateTime.parse(item['created_at'] as String)),
                isViewed: false,
              ))
          .toList();

      // Transform longest streak stories
      final longestStreakStories = longestStreakData
          .map((item) => HappeningNowStoryData(
                id: item['id'] as String,
                backgroundImage: item['thumbnail_url'] as String,
                profileImage: item['contributor_avatar'] as String,
                userName: item['contributor_name'] as String,
                categoryName: item['category_name'] as String,
                categoryIcon: item['category_icon'] as String? ?? '',
                timestamp: _getRelativeTime(
                    DateTime.parse(item['created_at'] as String)),
                isViewed: false,
              ))
          .toList();

      // Transform popular user stories
      final popularUserStories = popularUserData
          .map((item) => HappeningNowStoryData(
                id: item['id'] as String,
                backgroundImage: item['thumbnail_url'] as String,
                profileImage: item['contributor_avatar'] as String,
                userName: item['contributor_name'] as String,
                categoryName: item['category_name'] as String,
                categoryIcon: item['category_icon'] as String? ?? '',
                timestamp: _getRelativeTime(
                    DateTime.parse(item['created_at'] as String)),
                isViewed: false,
              ))
          .toList();

      if (_isDisposed) return;

      final model = MemoryFeedDashboardModel(
        happeningNowStories: happeningNowStories.isNotEmpty
            ? happeningNowStories.cast<HappeningNowStoryData>()
            : null,
        latestStories: latestStories.isNotEmpty
            ? latestStories.cast<HappeningNowStoryData>()
            : null,
        publicMemories: publicMemories.isNotEmpty ? publicMemories : null,
        trendingStories: trendingStories.isNotEmpty
            ? trendingStories.cast<HappeningNowStoryData>()
            : null,
        longestStreakStories: longestStreakStories.isNotEmpty
            ? longestStreakStories.cast<HappeningNowStoryData>()
            : null,
        popularUserStories: popularUserStories.isNotEmpty
            ? popularUserStories.cast<HappeningNowStoryData>()
            : null,
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: model,
        isLoading: false,
        activeMemories: activeMemoriesData,
        hasMoreHappeningNow: happeningNowData.length == _pageSize,
        hasMoreLatestStories: latestStoriesData.length == _pageSize,
        hasMorePublicMemories: publicMemoriesData.length == _pageSize,
        hasMoreTrending: trendingData.length == _pageSize,
        hasMoreLongestStreak: longestStreakData.length == _pageSize,
        hasMorePopularUsers: popularUserData.length == _pageSize,
        hasMorePopularMemories: false,
      ));
    } catch (e) {
      print('Error loading feed data: $e');
      if (!_isDisposed) {
        _safeSetState(state.copyWith(isLoading: false));
      }
    }
  }

  /// Load more happening now stories
  Future<void> loadMoreHappeningNow() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreHappeningNow)
      return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final newData = await _feedService.fetchHappeningNowStories();

      if (_isDisposed || newData.isEmpty) {
        _safeSetState(state.copyWith(
          isLoadingMore: false,
          hasMoreHappeningNow: false,
        ));
        return;
      }

      final newStories = newData.map((item) {
        return HappeningNowStoryData(
          id: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isViewed: false,
        );
      }).toList();

      final currentStories =
          state.memoryFeedDashboardModel?.happeningNowStories ?? [];
      final updatedStories = [...currentStories, ...newStories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreHappeningNow: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
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
      final currentStories =
          state.memoryFeedDashboardModel?.latestStories ?? [];
      final offset = currentStories.length;

      final newData = await _feedService.fetchLatestStories(offset: offset);

      if (_isDisposed || newData.isEmpty) {
        _safeSetState(state.copyWith(
          isLoadingMore: false,
          hasMoreLatestStories: false,
        ));
        return;
      }

      final newStories = newData.map((item) {
        return HappeningNowStoryData(
          id: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isViewed: false,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        latestStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreLatestStories: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      print('Error loading more latest stories: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more public memories
  Future<void> loadMorePublicMemories() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMorePublicMemories)
      return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final newData = await _feedService.fetchPublicMemories();

      if (_isDisposed || newData.isEmpty) {
        _safeSetState(state.copyWith(
          isLoadingMore: false,
          hasMorePublicMemories: false,
        ));
        return;
      }

      final newMemories = newData
          .map((item) => CustomMemoryItem(
                id: item['id'],
                title: item['title'],
                date: item['date'],
                iconPath: item['category_icon'] ?? '',
                profileImages:
                    (item['contributor_avatars'] as List?)?.cast<String>() ??
                        [],
                mediaItems: (item['media_items'] as List?)
                        ?.map((media) => CustomMediaItem(
                              imagePath: media['thumbnail_url'] ?? '',
                              hasPlayButton: media['video_url'] != null,
                            ))
                        .toList() ??
                    [],
                startDate: item['start_date'],
                startTime: item['start_time'],
                endDate: item['end_date'],
                endTime: item['end_time'],
                location: item['location'],
                distance: '',
                isLiked: false,
              ))
          .toList();

      final currentMemories =
          state.memoryFeedDashboardModel?.publicMemories ?? [];
      final updatedMemories = [...currentMemories, ...newMemories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        publicMemories: updatedMemories,
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePublicMemories: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      print('Error loading more public memories: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more trending stories
  Future<void> loadMoreTrending() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreTrending) return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final newData = await _feedService.fetchTrendingStories();

      if (_isDisposed || newData.isEmpty) {
        _safeSetState(state.copyWith(
          isLoadingMore: false,
          hasMoreTrending: false,
        ));
        return;
      }

      final newStories = newData.map((item) {
        return HappeningNowStoryData(
          id: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isViewed: false,
        );
      }).toList();

      final currentStories =
          state.memoryFeedDashboardModel?.trendingStories ?? [];
      final updatedStories = [...currentStories, ...newStories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        trendingStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreTrending: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
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
      final newData = await _feedService.fetchLongestStreakStories();

      if (_isDisposed || newData.isEmpty) {
        _safeSetState(state.copyWith(
          isLoadingMore: false,
          hasMoreLongestStreak: false,
        ));
        return;
      }

      final newStories = newData.map((item) {
        return HappeningNowStoryData(
          id: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isViewed: false,
        );
      }).toList();

      final currentStories =
          state.memoryFeedDashboardModel?.longestStreakStories ?? [];
      final updatedStories = [...currentStories, ...newStories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        longestStreakStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreLongestStreak: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
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
      final newData = await _feedService.fetchPopularUserStories();

      if (_isDisposed || newData.isEmpty) {
        _safeSetState(state.copyWith(
          isLoadingMore: false,
          hasMorePopularUsers: false,
        ));
        return;
      }

      final newStories = newData.map((item) {
        return HappeningNowStoryData(
          id: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isViewed: false,
        );
      }).toList();

      final currentStories =
          state.memoryFeedDashboardModel?.popularUserStories ?? [];
      final updatedStories = [...currentStories, ...newStories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        popularUserStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePopularUsers: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      print('Error loading more popular users: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// Load more popular memories
  Future<void> loadMorePopularMemories() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMorePopularMemories)
      return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final newData = await _feedService.fetchPublicMemories();

      if (_isDisposed || newData.isEmpty) {
        _safeSetState(state.copyWith(
          isLoadingMore: false,
          hasMorePopularMemories: false,
        ));
        return;
      }

      final newMemories = newData
          .map((item) => CustomMemoryItem(
                id: item['id'],
                title: item['title'],
                date: item['date'],
                iconPath: item['category_icon'] ?? '',
                profileImages:
                    (item['contributor_avatars'] as List?)?.cast<String>() ??
                        [],
                mediaItems: (item['media_items'] as List?)
                        ?.map((media) => CustomMediaItem(
                              imagePath: media['thumbnail_url'] ?? '',
                              hasPlayButton: media['video_url'] != null,
                            ))
                        .toList() ??
                    [],
                startDate: item['start_date'],
                startTime: item['start_time'],
                endDate: item['end_date'],
                endTime: item['end_time'],
                location: item['location'],
                distance: '',
                isLiked: false,
              ))
          .toList();

      final currentMemories =
          state.memoryFeedDashboardModel?.publicMemories ?? [];
      final updatedMemories = [...currentMemories, ...newMemories];

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        publicMemories: updatedMemories,
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePopularMemories: newData.length == _pageSize,
        isLoadingMore: false,
      ));

      if (!_isDisposed) {
        _safeSetState(state.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
      print('Error loading more popular memories: $e');
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refreshFeed() async {
    if (_isDisposed) return;
    _safeSetState(state.copyWith(isLoading: true));

    try {
      // Re-fetch all data
      await loadFeedData();

      if (!_isDisposed) {
        _safeSetState(state.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
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
      if (currentModel != null && currentModel.happeningNowStories != null) {
        final updatedStories = currentModel.happeningNowStories!.map((story) {
          if (story.id == storyId) {
            return story.copyWith(isViewed: true);
          }
          return story;
        }).toList();

        final updatedModel = currentModel.copyWith(
          happeningNowStories: updatedStories,
        );

        _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
      }
    } catch (e) {
      // Notifier was disposed, ignore
    }
  }

  void toggleMemoryLike(String memoryId) {
    if (_isDisposed) return;
    try {
      final currentModel = state.memoryFeedDashboardModel;
      if (currentModel != null && currentModel.publicMemories != null) {
        final updatedMemories = currentModel.publicMemories!.map((memory) {
          if (memory.id == memoryId) {
            return memory.copyWith(isLiked: !(memory.isLiked ?? false));
          }
          return memory;
        }).toList();

        final updatedModel = currentModel.copyWith(
          publicMemories: updatedMemories,
        );

        _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
      }
    } catch (e) {
      // Notifier was disposed, ignore
    }
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

  Future<void> _loadHappeningNowStories() async {
    try {
      final stories = await _feedService.fetchHappeningNowStories();

      if (_isDisposed) return;

      final transformedStories = stories.map((story) {
        return HappeningNowStoryData(
          id: story['id'] as String? ?? '',
          backgroundImage: story['thumbnail_url'] as String? ?? '',
          profileImage: story['contributor_avatar'] as String? ?? '',
          userName: story['contributor_name'] as String? ?? '',
          categoryName: story['category_name'] as String? ?? '',
          categoryIcon: story['category_icon'] as String? ?? '',
          timestamp: _getRelativeTime(
              DateTime.parse(story['created_at'] as String? ?? '')),
          isViewed: false,
        );
      }).toList();

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: state.memoryFeedDashboardModel?.copyWith(
          happeningNowStories: transformedStories.cast<HappeningNowStoryData>(),
        ),
      ));
    } catch (e) {
      print('Error loading happening now stories: $e');
    }
  }

  Future<void> loadCategories() async {
    try {
      state = state.copyWith(isLoadingCategories: true);

      final client = SupabaseService.instance.client;
      if (client == null) {
        state = state.copyWith(
          isLoadingCategories: false,
          categories: [],
        );
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

      state = state.copyWith(
        isLoadingCategories: false,
        categories: categories,
      );
    } catch (e) {
      print('Error loading categories: $e');
      state = state.copyWith(
        isLoadingCategories: false,
        categories: [],
      );
    }
  }
}
