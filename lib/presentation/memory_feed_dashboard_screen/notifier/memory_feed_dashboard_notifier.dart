// lib/presentation/memory_feed_dashboard_screen/notifier/memory_feed_dashboard_notifier.dart

import '../../../core/app_export.dart';
import '../../../services/feed_service.dart';
import '../../../services/create_memory_preload_service.dart';
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
  bool _realtimeStarted = false;
  bool _categoriesLoadRequested = false;
  bool _createMemoryWarmRequested = false;

  /// IMPORTANT: Must match FeedService._pageSize
  static const int _pageSize = 10;

  MemoryFeedDashboardNotifier()
      : super(
    MemoryFeedDashboardState(
      memoryFeedDashboardModel: MemoryFeedDashboardModel(),
    ),
  ) {
    loadInitialData();
  }

  void _startRealtimeIfNeeded() {
    if (_isDisposed) return;
    if (_realtimeStarted) return;
    _realtimeStarted = true;
    _subscribeToStoryViews();
    _setupRealtimeSubscriptions();
  }

  void _maybeLoadCategories() {
    if (_isDisposed) return;
    if (_categoriesLoadRequested) return;

    final client = SupabaseService.instance.client;
    final isAuthed = client?.auth.currentUser != null;
    if (!isAuthed) return;

    final cats = state.categories ?? const [];
    if (cats.isNotEmpty || state.isLoadingCategories) return;

    _categoriesLoadRequested = true;
    // Avoid blocking initial paint. Categories are below the fold anyway.
    Future.microtask(loadCategories);
  }

  void _maybeWarmCreateMemoryDependencies() {
    if (_isDisposed) return;
    if (_createMemoryWarmRequested) return;

    final client = SupabaseService.instance.client;
    final isAuthed = client?.auth.currentUser != null;
    if (!isAuthed) return;

    _createMemoryWarmRequested = true;
    // Fire-and-forget warm cache; CreateMemoryNotifier will consume it.
    Future.microtask(() => CreateMemoryPreloadService.instance.warm());
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
      dynamic rows;
      try {
        rows = await client
            .from('memories')
            .select('id, visibility, end_time')
            .eq('is_daily_capsule', false)
            .inFilter('id', ids);
      } on PostgrestException catch (e) {
        // Backward-compat: if migration not applied yet, retry without is_daily_capsule.
        final msg = e.message.toLowerCase();
        final code = (e.code ?? '').toString();
        final isMissing =
            code == '42703' || (msg.contains('is_daily_capsule') && msg.contains('does not exist'));
        if (!isMissing) rethrow;
        rows = await client
            .from('memories')
            .select('id, visibility, end_time')
            .inFilter('id', ids);
      }

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
        final hydratedEndTime =
        (existingEndTime != null && existingEndTime.toString().trim().isNotEmpty)
            ? existingEndTime
            : server?['end_time'];

        final endTimeDt = parseEndTime(hydratedEndTime);
        final expirationText =
        endTimeDt == null ? '' : _formatExpirationTime(endTimeDt);

        return <String, dynamic>{
          ...m,
          'visibility': hydratedVis,
          'end_time': hydratedEndTime,
          // keep a stable UI string available too
          'expiration_text': expirationText.isNotEmpty
              ? expirationText
              : (m['expiration_text'] ?? ''),
        };
      }).toList();

      return merged;
    } catch (e) {
      return list;
    }
  }

  /// Load initial data from the database
  Future<void> loadInitialData() async {
    if (_isDisposed) return;

    _safeSetState(
      state.copyWith(
        isLoading: true,
        isLoadingActiveMemories: true,
        hasDbConnectionError: false,
      ),
    );

    try {
      // ----------------------------
      // 1) Prioritize above-the-fold
      // ----------------------------
      // Fetch active memories first so the primary CTA ("Create Memory"/"Create Story")
      // can render quickly even if the rest of the dashboard is still loading.
      final rawActiveMemoriesData = await _feedService.fetchUserActiveMemories();
      final activeMemoriesData =
          await _hydrateActiveMemoriesWithVisibility(rawActiveMemoriesData);

      if (_isDisposed) return;
      _safeSetState(
        state.copyWith(
          isLoadingActiveMemories: false,
          activeMemories: activeMemoriesData,
        ),
      );
      // Start warming Create Memory deps as soon as the CTA can appear.
      _maybeWarmCreateMemoryDependencies();

      // -----------------------------------
      // 2) Fetch remaining feeds in parallel
      // -----------------------------------
      final futures = await Future.wait([
        _feedService.fetchHappeningNowStories(offset: 0, limit: _pageSize),
        _feedService.fetchLatestStories(offset: 0, limit: _pageSize),
        _feedService.fetchPublicMemories(offset: 0, limit: _pageSize),
        _feedService.fetchTrendingStories(offset: 0, limit: _pageSize),
        _feedService.fetchLongestStreakStories(offset: 0, limit: _pageSize),
        _feedService.fetchPopularUserStories(offset: 0, limit: _pageSize),
        _feedService.fetchPopularNowStories(offset: 0, limit: _pageSize),
        _feedService.fetchFromFriendsStories(offset: 0, limit: _pageSize),
        _feedService.fetchForYouStories(offset: 0, limit: _pageSize),
        _feedService.fetchPopularMemories(offset: 0, limit: _pageSize),
        _feedService.fetchForYouMemories(offset: 0, limit: _pageSize),
      ]);

      final happeningNowData = (futures[0] as List).cast<Map<String, dynamic>>();
      final latestStoriesData = (futures[1] as List).cast<Map<String, dynamic>>();
      final publicMemoriesData = (futures[2] as List).cast<Map<String, dynamic>>();
      final trendingData = (futures[3] as List).cast<Map<String, dynamic>>();
      final longestStreakData = (futures[4] as List).cast<Map<String, dynamic>>();
      final popularUserData = (futures[5] as List).cast<Map<String, dynamic>>();
      final popularNowData = (futures[6] as List).cast<Map<String, dynamic>>();
      final fromFriendsData = (futures[7] as List).cast<Map<String, dynamic>>();
      final forYouStoriesData = (futures[8] as List).cast<Map<String, dynamic>>();
      final popularMemoriesData = (futures[9] as List).cast<Map<String, dynamic>>();
      final forYouMemoriesData = (futures[10] as List).cast<Map<String, dynamic>>();

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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      // Transform popular now
      final popularNowStories = popularNowData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      // ✅ Transform from friends
      final fromFriendsStories = fromFriendsData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      // ✅ Transform for you stories
      final forYouStories = forYouStoriesData.map((item) {
        final isRead = item['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      // ✅ Transform popular memories
      final popularMemories = popularMemoriesData
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

      // ✅ Transform for you memories
      final forYouMemories = forYouMemoriesData
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

      if (_isDisposed) return;

      // IMPORTANT: keep lists as lists (never null) to make UI deterministic
      final model = MemoryFeedDashboardModel(
        happeningNowStories: happeningNowStories.cast<HappeningNowStoryData>(),
        latestStories: latestStories.cast<HappeningNowStoryData>(),
        publicMemories: publicMemories,
        popularMemories: popularMemories,
        trendingStories: trendingStories.cast<HappeningNowStoryData>(),
        longestStreakStories: longestStreakStories.cast<HappeningNowStoryData>(),
        popularUserStories: popularUserStories.cast<HappeningNowStoryData>(),
        popularNowStories: popularNowStories.cast<HappeningNowStoryData>(),

        // ✅ NEW
        fromFriendsStories: fromFriendsStories.cast<HappeningNowStoryData>(),
        forYouStories: forYouStories.cast<HappeningNowStoryData>(),
        forYouMemories: forYouMemories,
      );

      _safeSetState(
        state.copyWith(
          memoryFeedDashboardModel: model,
          isLoading: false,
          hasDbConnectionError: false,
          // `activeMemories` and `isLoadingActiveMemories` are updated earlier for speed.
          hasMoreHappeningNow: happeningNowData.length == _pageSize,
          hasMoreLatestStories: latestStoriesData.length == _pageSize,
          hasMorePublicMemories: publicMemoriesData.length == _pageSize,
          hasMoreTrending: trendingData.length == _pageSize,
          hasMoreLongestStreak: longestStreakData.length == _pageSize,
          hasMorePopularUsers: popularUserData.length == _pageSize,
          hasMorePopularNow: popularNowData.length == _pageSize,

          // ✅ now actually driven by initial fetchPopularMemories
          hasMorePopularMemories: popularMemoriesData.length == _pageSize,
        ),
      );

      // Defer background work until after the first useful paint.
      _maybeLoadCategories();
      _startRealtimeIfNeeded();
      _maybeWarmCreateMemoryDependencies();
    } catch (e) {
      if (!_isDisposed) {
        _safeSetState(
          state.copyWith(
            isLoading: false,
            isLoadingActiveMemories: false,
            hasDbConnectionError: true,
          ),
        );
      }
    }
  }

  /// Subscribe to real-time story view updates
  void _subscribeToStoryViews() {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        return;
      }

      _storyViewsSubscription = _feedService.subscribeToStoryViews(
        onStoryViewed: (storyId, userId) {
          if (userId == currentUserId) {
            _updateStoryReadStatus(storyId);
          }
        },
      );
    } catch (e) {
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
    final updatedLongestStreak =
    updateListIfPresent(currentModel.longestStreakStories, 'Longest Streak');
    final updatedPopularUsers =
    updateListIfPresent(currentModel.popularUserStories, 'Popular Users');

    // ✅ NEW story lists
    final updatedFromFriends =
    updateListIfPresent(currentModel.fromFriendsStories, 'From Friends');
    final updatedForYouStories =
    updateListIfPresent(currentModel.forYouStories, 'For You Stories');

    if (!anyUpdated) return;

    final updatedModel = currentModel.copyWith(
      happeningNowStories: updatedHappeningNow ?? currentModel.happeningNowStories,
      latestStories: updatedLatest ?? currentModel.latestStories,
      trendingStories: updatedTrending ?? currentModel.trendingStories,
      longestStreakStories:
      updatedLongestStreak ?? currentModel.longestStreakStories,
      popularUserStories: updatedPopularUsers ?? currentModel.popularUserStories,

      // ✅ NEW
      fromFriendsStories: updatedFromFriends ?? currentModel.fromFriendsStories,
      forYouStories: updatedForYouStories ?? currentModel.forYouStories,
    );

    _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Story views subscription
    _feedService.unsubscribeFromStoryViews();
    try {
      _storyViewsSubscription?.unsubscribe();
    } catch (_) {
      // ignore
    }
    _storyViewsSubscription = null;

    // Stories + memories realtime subscriptions
    _cleanupSubscriptions();

    super.dispose();
  }

  /// Setup real-time subscriptions for stories and memories
  void _setupRealtimeSubscriptions() {
    final client = SupabaseService.instance.client;
    if (client == null) {
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
    }
  }

  void _cleanupSubscriptions() {
    try {
      _storiesChannel?.unsubscribe();
      _memoriesChannel?.unsubscribe();
    } catch (e) {
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
      Map<String, dynamic> memoryVisibilityCheck;
      try {
        final raw = await client
            .from('memories')
            .select('visibility, is_daily_capsule')
            .eq('id', memoryId)
            .single();
        memoryVisibilityCheck = (raw as Map).cast<String, dynamic>();
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        final code = (e.code ?? '').toString();
        final isMissing =
            code == '42703' || (msg.contains('is_daily_capsule') && msg.contains('does not exist'));
        if (!isMissing) rethrow;
        final raw = await client
            .from('memories')
            .select('visibility')
            .eq('id', memoryId)
            .single();
        memoryVisibilityCheck = (raw as Map).cast<String, dynamic>();
      }

      if (_isDisposed) return;

      final isDailyCapsule = memoryVisibilityCheck['is_daily_capsule'] == true;
      if (isDailyCapsule) return;

      final memoryVisibility = _normVisibility(memoryVisibilityCheck['visibility']);

      // ⛔ STOP: If memory is private, do NOT add story to "Happening Now" feed
      if (memoryVisibility != 'public') {
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
        categoryName:
        memoryResponse['memories']['memory_categories']['name'] as String? ??
            '',
        categoryIcon:
        memoryResponse['memories']['memory_categories']['icon_url'] as String? ??
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
      final currentMemories = currentModel.publicMemories ?? <CustomMemoryItem>[];
      final memoryIndex = currentMemories.indexWhere((m) => m.id == memoryId);

      List<CustomMemoryItem> updatedMemories = currentMemories;
      if (memoryIndex != -1) {
        final targetMemory = currentMemories[memoryIndex];
        final currentMediaItems = targetMemory.mediaItems ?? <CustomMediaItem>[];

        final newMediaItem = CustomMediaItem(
          imagePath: resolvedThumbnailUrl ?? '',
          hasPlayButton: videoUrl != null,
        );

        final updatedMediaItems =
        [newMediaItem, ...currentMediaItems].take(2).toList();

        final updatedMemory = targetMemory.copyWith(mediaItems: updatedMediaItems);

        updatedMemories = [...currentMemories];
        updatedMemories[memoryIndex] = updatedMemory;
      }

      final updatedModel = currentModel.copyWith(
        happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
        publicMemories: updatedMemories,
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (e) {
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

      // ✅ NEW story lists
      final updatedFromFriends = _updateStoryInList(
        currentModel.fromFriendsStories,
        storyId,
        payload.newRecord,
      );

      final updatedForYou = _updateStoryInList(
        currentModel.forYouStories,
        storyId,
        payload.newRecord,
      );

      final updatedModel = currentModel.copyWith(
        happeningNowStories: updatedHappeningNow ?? currentModel.happeningNowStories,
        latestStories: updatedLatest ?? currentModel.latestStories,
        trendingStories: updatedTrending ?? currentModel.trendingStories,

        // ✅ NEW
        fromFriendsStories: updatedFromFriends ?? currentModel.fromFriendsStories,
        forYouStories: updatedForYou ?? currentModel.forYouStories,
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (e) {
    }
  }

  /// Handle new memory inserted
  void _handleNewMemory(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    try {
      final memoryId = payload.newRecord['id'] as String;
      final visibility = _normVisibility(payload.newRecord['visibility']);

      final client = SupabaseService.instance.client;
      if (client == null) return;

      final currentUserId = client.auth.currentUser?.id;

      // Check if current user is a contributor OR creator of this memory
      bool isCurrentUserContributor = false;
      if (currentUserId != null) {
        final creatorId = (payload.newRecord['creator_id'] ?? '').toString();
        if (creatorId.isNotEmpty && creatorId == currentUserId) {
          isCurrentUserContributor = true;
        } else {
          try {
            final contributorCheck = await client
                .from('memory_contributors')
                .select('id')
                .eq('memory_id', memoryId)
                .eq('user_id', currentUserId)
                .maybeSingle();

            isCurrentUserContributor = contributorCheck != null;
          } catch (e) {
          }
        }
      }

      // If current user is a contributor, update activeMemories list
      if (isCurrentUserContributor) {
        Map<String, dynamic> memoryDetails;
        try {
          final raw = await client.from('memories').select('''
              id,
              title,
              state,
              visibility,
              is_daily_capsule,
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
          memoryDetails = (raw as Map).cast<String, dynamic>();
        } on PostgrestException catch (e) {
          final msg = e.message.toLowerCase();
          final code = (e.code ?? '').toString();
          final isMissing =
              code == '42703' || (msg.contains('is_daily_capsule') && msg.contains('does not exist'));
          if (!isMissing) rethrow;
          final raw = await client.from('memories').select('''
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
          memoryDetails = (raw as Map).cast<String, dynamic>();
        }

        if (_isDisposed) return;

        if (memoryDetails['is_daily_capsule'] == true) return;

        final category = memoryDetails['memory_categories'] as Map<String, dynamic>?;
        final creator = memoryDetails['user_profiles_public'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(memoryDetails['created_at']);
        final endTime = memoryDetails['end_time'] != null
            ? DateTime.parse(memoryDetails['end_time'])
            : null;

        final creatorName = (creator?['display_name'] as String?)?.trim();
        final safeCreatorName =
        (creatorName != null && creatorName.isNotEmpty) ? creatorName : null;

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
        final updatedActiveMemories = [newActiveMemory, ...currentActiveMemories];

        _safeSetState(state.copyWith(activeMemories: updatedActiveMemories));

      }

      // Continue with existing logic for public feed update
      if (visibility != 'public') return;

      Map<String, dynamic> response;
      try {
        final raw = await client.from('memories').select('''
            id,
            title,
            is_daily_capsule,
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
          ''')
            .eq('id', memoryId)
            .eq('visibility', 'public')
            .eq('is_daily_capsule', false)
            .single();
        response = (raw as Map).cast<String, dynamic>();
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        final code = (e.code ?? '').toString();
        final isMissing =
            code == '42703' || (msg.contains('is_daily_capsule') && msg.contains('does not exist'));
        if (!isMissing) rethrow;
        final raw = await client.from('memories').select('''
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
        response = (raw as Map).cast<String, dynamic>();
      }

      if (_isDisposed) return;

      if (response['is_daily_capsule'] == true) return;

      final contributors = response['memory_contributors'] as List;
      final stories = response['stories'] as List;

      // Normalize contributor avatar URLs so realtime-inserted cards render correctly.
      // If we pass raw storage paths (or nulls) here, the card will treat them as
      // "provided" and will NOT refetch, resulting in broken avatars until refresh.
      final List<String> contributorAvatars = [];
      for (final c in contributors) {
        if (c is! Map) continue;
        final dynamic profile =
            c['user_profiles'] ?? c['user_profiles_public'];
        String? raw;
        if (profile is Map) {
          raw = (profile['avatar_url'] as String?)?.trim();
        } else {
          raw = (c['avatar_url'] as String?)?.trim();
        }
        final resolved = StorageUtils.resolveAvatarUrl(raw) ?? '';
        if (resolved.isNotEmpty) contributorAvatars.add(resolved);
      }

      final newMemoryData = CustomMemoryItem(
        id: response['id'],
        title: response['title'],
        date: DateTime.parse(response['start_time']).toString(),
        iconPath: response['memory_categories']['icon_url'] ?? '',
        profileImages: contributorAvatars,
        mediaItems: stories
            .map(
              (s) => CustomMediaItem(
            imagePath: StorageUtils.resolveStoryMediaUrl(s['thumbnail_url']) ??
                (s['thumbnail_url'] ?? ''),
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

      final currentModel = state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel();
      final currentMemories = currentModel.publicMemories ?? <CustomMemoryItem>[];
      final updatedMemories = [newMemoryData, ...currentMemories];

      final updatedModel = currentModel.copyWith(publicMemories: updatedMemories);
      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (e) {
    }
  }

  /// Handle memory update
  void _handleMemoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    try {
      final memoryId = payload.newRecord['id'] as String;
      final currentModel = state.memoryFeedDashboardModel;
      if (currentModel == null) return;

      final currentMemories = currentModel.publicMemories ?? <CustomMemoryItem>[];
      if (currentMemories.isEmpty) return;

      final updatedMemories = currentMemories.map((memory) {
        if (memory.id == memoryId) {
          return memory.copyWith(
            title: payload.newRecord['title'] as String? ?? memory.title,
          );
        }
        return memory;
      }).toList();

      final updatedModel = currentModel.copyWith(publicMemories: updatedMemories);
      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));
    } catch (e) {
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
      if (e.toString().contains('dispose') || e.toString().contains('Bad state')) {
        _isDisposed = true;
      } else {
        rethrow;
      }
    }
  }

  // ----------------------------
  // PAGINATION (FIXED OFFSETS)
  // ----------------------------

  Future<void> loadMoreHappeningNow() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreHappeningNow) return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories =
          state.memoryFeedDashboardModel?.happeningNowStories ?? <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData =
      await _feedService.fetchHappeningNowStories(offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(state.copyWith(isLoadingMore: false, hasMoreHappeningNow: false));
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
      (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel()).copyWith(
        happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreHappeningNow: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> loadMoreLatestStories() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreLatestStories) return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories =
          state.memoryFeedDashboardModel?.latestStories ?? <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData =
      await _feedService.fetchLatestStories(offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(state.copyWith(isLoadingMore: false, hasMoreLatestStories: false));
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
      (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel()).copyWith(
        latestStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreLatestStories: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> loadMorePublicMemories() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMorePublicMemories) {
      return;
    }

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentModel = state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel();
      final currentMemories = currentModel.publicMemories ?? <CustomMemoryItem>[];
      final offset = currentMemories.length;

      final newData =
      await _feedService.fetchPublicMemories(offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(state.copyWith(isLoadingMore: false, hasMorePublicMemories: false));
        return;
      }

      final List<CustomMemoryItem> newMemories = newData.map<CustomMemoryItem>((item) {
        return CustomMemoryItem(
          id: item['id'] as String?,
          title: item['title'] as String?,
          date: item['date'] as String?,
          iconPath: (item['category_icon'] as String?) ?? '',
          profileImages: (item['contributor_avatars'] as List?)?.cast<String>() ?? <String>[],
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

      final updatedMemories = <CustomMemoryItem>[...currentMemories, ...newMemories];
      final updatedModel = currentModel.copyWith(publicMemories: updatedMemories);

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePublicMemories: newData.length == _pageSize,
        isLoadingMore: false,
      ));

    } catch (e) {
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> loadMoreTrending() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreTrending) return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories =
          state.memoryFeedDashboardModel?.trendingStories ?? <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData =
      await _feedService.fetchTrendingStories(offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(state.copyWith(isLoadingMore: false, hasMoreTrending: false));
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
      (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel()).copyWith(
        trendingStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreTrending: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> loadMoreLongestStreak() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMoreLongestStreak) return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories =
          state.memoryFeedDashboardModel?.longestStreakStories ?? <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData = await _feedService.fetchLongestStreakStories(
        offset: offset,
        limit: _pageSize,
      );

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(
          state.copyWith(isLoadingMore: false, hasMoreLongestStreak: false),
        );
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
      (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel()).copyWith(
        longestStreakStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMoreLongestStreak: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> loadMorePopularUsers() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMorePopularUsers) return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentStories =
          state.memoryFeedDashboardModel?.popularUserStories ?? <HappeningNowStoryData>[];
      final offset = currentStories.length;

      final newData =
      await _feedService.fetchPopularUserStories(offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(state.copyWith(isLoadingMore: false, hasMorePopularUsers: false));
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
          timestamp: _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead,
        );
      }).toList();

      final updatedStories = [...currentStories, ...newStories];

      final updatedModel =
      (state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel()).copyWith(
        popularUserStories: updatedStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePopularUsers: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  /// ✅ FIXED: popular memories must append to `popularMemories`, NOT `publicMemories`
  Future<void> loadMorePopularMemories() async {
    if (_isDisposed || state.isLoadingMore || !state.hasMorePopularMemories) return;

    _safeSetState(state.copyWith(isLoadingMore: true));

    try {
      final currentModel = state.memoryFeedDashboardModel ?? MemoryFeedDashboardModel();
      final currentPopular = currentModel.popularMemories ?? <CustomMemoryItem>[];
      final offset = currentPopular.length;

      final newData =
      await _feedService.fetchPopularMemories(offset: offset, limit: _pageSize);

      if (_isDisposed) return;

      if (newData.isEmpty) {
        _safeSetState(
          state.copyWith(isLoadingMore: false, hasMorePopularMemories: false),
        );
        return;
      }

      final newMemories = newData.map((item) {
        return CustomMemoryItem(
          id: item['id'],
          title: item['title'],
          date: item['date'],
          iconPath: item['category_icon'] ?? '',
          profileImages: (item['contributor_avatars'] as List?)?.cast<String>() ?? <String>[],
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

      final updatedPopular = [...currentPopular, ...newMemories];

      final updatedModel = currentModel.copyWith(
        popularMemories: updatedPopular,
      );

      _safeSetState(state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        hasMorePopularMemories: newData.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      _safeSetState(state.copyWith(isLoadingMore: false));
    }
  }

  // ----------------------------
  // OTHER ACTIONS
  // ----------------------------

  Future<void> refreshFeed() async {
    if (_isDisposed) return;
    _safeSetState(state.copyWith(isLoading: true, hasDbConnectionError: false));

    try {
      await loadInitialData();
      if (!_isDisposed) {
        _safeSetState(state.copyWith(isLoading: false, hasDbConnectionError: false));
      }
    } catch (e) {
      if (!_isDisposed) {
        _safeSetState(state.copyWith(isLoading: false, hasDbConnectionError: true));
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
      final currentMemories = currentModel?.publicMemories ?? <CustomMemoryItem>[];
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
        _safeSetState(state.copyWith(isLoadingCategories: false, categories: []));
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
      _safeSetState(state.copyWith(
        isLoadingCategories: false,
        categories: [],
      ));
    }
  }
}
