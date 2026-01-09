import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/storage_utils.dart';
import '../models/memories_dashboard_model.dart';
import '../models/memory_item_model.dart';
import '../models/story_item_model.dart';

part 'memories_dashboard_state.dart';

final memoriesDashboardNotifier = StateNotifierProvider.autoDispose<
    MemoriesDashboardNotifier, MemoriesDashboardState>(
  (ref) => MemoriesDashboardNotifier(),
);

class MemoriesDashboardNotifier extends StateNotifier<MemoriesDashboardState> {
  final _cacheService = MemoryCacheService();

  RealtimeChannel? _storiesChannel;
  RealtimeChannel? _memoriesChannel;
  RealtimeChannel? _contributorsChannel;

  bool _isDisposed = false;

  MemoriesDashboardNotifier()
      : super(MemoriesDashboardState(
          memoriesDashboardModel: MemoriesDashboardModel(),
        )) {
    _setupRealtimeSubscriptions();
  }

  /// Call this from screen initState (once).
  Future<void> initialize() async {
    print('🔍 MEMORIES DEBUG: Initializing memories dashboard');

    // Always set loading true at start
    _safeSetState(state.copyWith(isLoading: true));

    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      print('🔍 MEMORIES DEBUG: Current user ID: ${currentUser?.id}');

      if (currentUser == null) {
        print('❌ MEMORIES DEBUG: No authenticated user found');
        _safeSetState(state.copyWith(isLoading: false));
        return;
      }

      // Force refresh on first entry to avoid stale / stuck states
      await _loadFromCache(currentUser.id, forceRefresh: true);

      _safeSetState(
        state.copyWith(
          isLoading: false,
          selectedTabIndex: 0,
          selectedOwnership: 'all',
          selectedState: 'all',
        ),
      );

      print('✅ MEMORIES DEBUG: Initialization complete');
    } catch (e) {
      print('❌ MEMORIES DEBUG: Error initializing memories dashboard: $e');
      _safeSetState(state.copyWith(isLoading: false));
    }
  }

  /// Centralized cache load -> updates dashboard model + counts
  Future<void> _loadFromCache(
    String userId, {
    bool forceRefresh = false,
  }) async {
    print(
        '🔍 MEMORIES DEBUG: Loading from cache (forceRefresh: $forceRefresh)');

    try {
      // IMPORTANT: fetch stories+memories in parallel
      final results = await Future.wait([
        _cacheService.getStories(userId, forceRefresh: forceRefresh),
        _cacheService.getMemories(userId, forceRefresh: forceRefresh),
      ]);

      final stories = results[0] as List<StoryItemModel>;
      final memories = results[1] as List<MemoryItemModel>;

      print(
          '✅ MEMORIES DEBUG: Loaded ${stories.length} stories and ${memories.length} memories');

      final liveMemories = memories.where((m) => m.state == 'open').toList();
      final sealedMemories =
          memories.where((m) => m.state == 'sealed').toList();

      final updatedModel =
          (state.memoriesDashboardModel ?? MemoriesDashboardModel()).copyWith(
        storyItems: stories,
        memoryItems: memories,
        liveMemoryItems: liveMemories,
        sealedMemoryItems: sealedMemories,
        allCount: memories.length,
        liveCount: liveMemories.length,
        sealedCount: sealedMemories.length,
      );

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));
    } catch (e) {
      print('❌ MEMORIES DEBUG: Error loading from cache: $e');
      // Do not throw; just leave previous data and stop loading
    }
  }

  void updateSelectedTabIndex(int index) {
    _safeSetState(state.copyWith(selectedTabIndex: index));
  }

  void updateOwnershipFilter(String ownership) {
    print('🔍 MEMORIES DEBUG: Updating ownership filter to: $ownership');
    _safeSetState(state.copyWith(selectedOwnership: ownership));
  }

  void updateStateFilter(String stateFilter) {
    print('🔍 MEMORIES DEBUG: Updating state filter to: $stateFilter');
    _safeSetState(state.copyWith(selectedState: stateFilter));
  }

  List<MemoryItemModel> getFilteredMemories(String userId) {
    final allMemories = state.memoriesDashboardModel?.memoryItems ?? [];
    final ownership = state.selectedOwnership ?? 'all';

    // Handle "All" tab - show all memories regardless of ownership
    if (ownership == 'all') {
      return allMemories;
    }

    // Filter by ownership (created or joined)
    List<MemoryItemModel> filteredByOwnership;
    if (ownership == 'created') {
      filteredByOwnership =
          allMemories.where((m) => m.creatorId == userId).toList();
    } else {
      filteredByOwnership =
          allMemories.where((m) => m.creatorId != userId).toList();
    }

    return filteredByOwnership;
  }

  int getOwnershipCount(String userId, String ownership) {
    final allMemories = state.memoriesDashboardModel?.memoryItems ?? [];

    // Handle "All" tab count
    if (ownership == 'all') {
      return allMemories.length;
    }

    if (ownership == 'created') {
      return allMemories.where((m) => m.creatorId == userId).length;
    }
    return allMemories.where((m) => m.creatorId != userId).length;
  }

  Future<void> loadAllStories() async {
    _safeSetState(state.copyWith(isLoading: true));

    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser != null) {
        final stories =
            await _cacheService.getStories(currentUser.id, forceRefresh: true);
        final updatedModel =
            (state.memoriesDashboardModel ?? MemoriesDashboardModel())
                .copyWith(storyItems: stories);
        _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));
      }

      _safeSetState(state.copyWith(isLoading: false, isSuccess: true));

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed) _safeSetState(state.copyWith(isSuccess: false));
      });
    } catch (e) {
      print('Error loading all stories: $e');
      _safeSetState(state.copyWith(isLoading: false));
    }
  }

  /// Call this from RefreshIndicator
  /// FIX: forceRefresh true + always stop loading
  Future<void> refreshMemories() async {
    print('🔄 MEMORIES DEBUG: Pull-to-refresh triggered');

    _safeSetState(state.copyWith(isLoading: true));

    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) {
        _safeSetState(state.copyWith(isLoading: false));
        return;
      }

      // Force refresh immediately
      await _loadFromCache(currentUser.id, forceRefresh: true);

      // Optional: debounced background refresh to catch any concurrent realtime updates
      _cacheService.refreshMemoryCache(currentUser.id);

      _safeSetState(state.copyWith(isLoading: false, isSuccess: true));

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed) _safeSetState(state.copyWith(isSuccess: false));
      });

      print('✅ MEMORIES DEBUG: Refresh complete');
    } catch (e) {
      print('❌ MEMORIES DEBUG: Error refreshing memories: $e');
      _safeSetState(state.copyWith(isLoading: false));
    }
  }

  // ========================= REALTIME =========================

  void _setupRealtimeSubscriptions() {
    final client = SupabaseService.instance.client;
    if (client == null) {
      print('⚠️ REALTIME: Supabase client not available');
      return;
    }

    try {
      _storiesChannel = client
          .channel('memories_dashboard:stories')
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
          .channel('memories_dashboard:memories')
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
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'memories',
            callback: _handleMemoryDelete,
          )
          .subscribe();

      _contributorsChannel = client
          .channel('memories_dashboard:contributors')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'memory_contributors',
            callback: _handleContributorJoin,
          )
          .subscribe();

      print('✅ REALTIME: Subscriptions setup complete for memories dashboard');
    } catch (e) {
      print('❌ REALTIME: Error setting up subscriptions: $e');
    }
  }

  void _handleNewStory(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    print('🔔 REALTIME: New story detected: ${payload.newRecord['id']}');

    try {
      final storyId = payload.newRecord['id'] as String;
      final contributorId = payload.newRecord['contributor_id'] as String;
      final memoryId = payload.newRecord['memory_id'] as String;
      final rawThumbnailUrl = payload.newRecord['thumbnail_url'] as String?;
      final client = SupabaseService.instance.client;

      if (client == null) return;

      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final memoryResponse = await client
          .from('memories')
          .select('creator_id')
          .eq('id', memoryId)
          .single();

      if (_isDisposed) return;

      final isUserMemory = memoryResponse['creator_id'] == currentUserId;

      final contributorCheck = await client
          .from('memory_contributors')
          .select('id')
          .eq('memory_id', memoryId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (_isDisposed) return;

      final isContributor = contributorCheck != null;

      if (!isUserMemory && !isContributor) return;

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

      final newStoryItem = StoryItemModel(
        id: storyId,
        backgroundImage: resolvedThumbnailUrl ?? '',
        profileImage: resolvedAvatarUrl ?? '',
        timestamp: 'Just now',
        navigateTo: storyId,
        isRead: false,
      );

      final currentStories = state.memoriesDashboardModel?.storyItems ?? [];
      final updatedStories = [newStoryItem, ...currentStories];

      final updatedModel =
          (state.memoriesDashboardModel ?? MemoriesDashboardModel())
              .copyWith(storyItems: updatedStories.cast<StoryItemModel>());

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));
    } catch (e) {
      print('❌ REALTIME: Error handling new story: $e');
    }
  }

  void _handleStoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    try {
      final storyId = payload.newRecord['id'] as String;
      final currentModel = state.memoriesDashboardModel;
      if (currentModel == null) return;

      final storyItems = currentModel.storyItems;
      if (storyItems == null || storyItems.isEmpty) return;

      bool found = false;
      final updatedStories = storyItems.map((story) {
        if (story.id == storyId) {
          found = true;
          return story.copyWith(
            backgroundImage: payload.newRecord['thumbnail_url'] as String? ??
                story.backgroundImage,
          );
        }
        return story;
      }).toList();

      if (!found) return;

      final updatedModel = currentModel.copyWith(
        storyItems: updatedStories.cast<StoryItemModel>(),
      );

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));
    } catch (e) {
      print('❌ REALTIME: Error handling story update: $e');
    }
  }

  void _handleContributorJoin(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    try {
      final contributorUserId = payload.newRecord['user_id'] as String;
      final memoryId = payload.newRecord['memory_id'] as String;
      final client = SupabaseService.instance.client;

      if (client == null) return;

      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      if (contributorUserId != currentUserId) return;

      final response = await client.from('memories').select('''
            id,
            title,
            start_time,
            end_time,
            location_name,
            state,
            creator_id,
            memory_categories(
              id,
              name,
              icon_url
            ),
            memory_contributors(
              user_profiles(
                avatar_url
              )
            )
          ''').eq('id', memoryId).single();

      if (_isDisposed) return;

      final contributors = response['memory_contributors'] as List? ?? [];
      final category = response['memory_categories'] as Map<String, dynamic>?;
      final creatorId = response['creator_id'] as String;

      final startTimeStr = response['start_time'] as String?;
      final endTimeStr = response['end_time'] as String?;

      if (startTimeStr == null || startTimeStr.trim().isEmpty) return;
      if (endTimeStr == null || endTimeStr.trim().isEmpty) return;

      DateTime startTime;
      try {
        startTime = DateTime.parse(startTimeStr.trim());
      } catch (_) {
        return;
      }

      final newMemoryItem = MemoryItemModel(
        id: response['id'],
        title: response['title'],
        date: startTime.toString(),
        eventDate: startTimeStr,
        eventTime: startTimeStr,
        endDate: endTimeStr,
        endTime: endTimeStr,
        location: response['location_name'] ?? '',
        distance: '',
        categoryIconUrl: category?['icon_url'] ?? '',
        categoryName: category?['name'] ?? '',
        participantAvatars: contributors
            .map((c) => c['user_profiles']?['avatar_url'] as String? ?? '')
            .where((url) => url.isNotEmpty)
            .toList(),
        state: response['state'] ?? 'open',
        creatorId: creatorId,
      );

      final currentMemories = state.memoriesDashboardModel?.memoryItems ?? [];
      final memoryExists = currentMemories.any((m) => m.id == memoryId);
      if (memoryExists) return;

      final updatedMemories = [newMemoryItem, ...currentMemories];

      final liveMemories =
          updatedMemories.where((m) => m.state == 'open').toList();
      final sealedMemories =
          updatedMemories.where((m) => m.state == 'sealed').toList();

      final updatedModel =
          (state.memoriesDashboardModel ?? MemoriesDashboardModel()).copyWith(
        memoryItems: updatedMemories.cast<MemoryItemModel>(),
        liveMemoryItems: liveMemories.cast<MemoryItemModel>(),
        sealedMemoryItems: sealedMemories.cast<MemoryItemModel>(),
        allCount: updatedMemories.length,
        liveCount: liveMemories.length,
        sealedCount: sealedMemories.length,
      );

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));
    } catch (e) {
      print('❌ REALTIME: Error handling contributor join: $e');
    }
  }

  void _handleNewMemory(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    try {
      final memoryId = payload.newRecord['id'] as String;
      final creatorId = payload.newRecord['creator_id'] as String;
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      if (creatorId != currentUserId) return;

      final response = await client.from('memories').select('''
            id,
            title,
            start_time,
            end_time,
            location_name,
            location_lat,
            location_lng,
            state,
            creator_id,
            memory_categories(
              id,
              name,
              icon_url
            ),
            memory_contributors(
              user_profiles(
                avatar_url
              )
            )
          ''').eq('id', memoryId).single();

      if (_isDisposed) return;

      final contributors = response['memory_contributors'] as List? ?? [];
      final category = response['memory_categories'] as Map<String, dynamic>?;

      final startTimeStr = response['start_time'] as String?;
      final endTimeStr = response['end_time'] as String?;

      if (startTimeStr == null || startTimeStr.trim().isEmpty) return;
      if (endTimeStr == null || endTimeStr.trim().isEmpty) return;

      DateTime startTime;
      DateTime endTime;

      try {
        startTime = DateTime.parse(startTimeStr.trim());
        endTime = DateTime.parse(endTimeStr.trim());
      } catch (_) {
        return;
      }

      final locationName = response['location_name'] as String?;

      final newMemoryItem = MemoryItemModel(
        id: response['id'],
        title: response['title'],
        date: startTime.toString(),
        eventDate: startTimeStr,
        eventTime: startTimeStr,
        endDate: endTimeStr,
        endTime: endTimeStr,
        location: locationName ?? '',
        distance: '',
        categoryIconUrl: category?['icon_url'] ?? '',
        categoryName: category?['name'] ?? '',
        participantAvatars: contributors
            .map((c) => c['user_profiles']?['avatar_url'] as String? ?? '')
            .where((url) => url.isNotEmpty)
            .toList(),
        state: response['state'] ?? 'open',
        creatorId: creatorId,
      );

      final currentMemories = state.memoriesDashboardModel?.memoryItems ?? [];
      final updatedMemories = [newMemoryItem, ...currentMemories];

      final liveMemories =
          updatedMemories.where((m) => m.state == 'open').toList();
      final sealedMemories =
          updatedMemories.where((m) => m.state == 'sealed').toList();

      final updatedModel =
          (state.memoriesDashboardModel ?? MemoriesDashboardModel()).copyWith(
        memoryItems: updatedMemories.cast<MemoryItemModel>(),
        liveMemoryItems: liveMemories.cast<MemoryItemModel>(),
        sealedMemoryItems: sealedMemories.cast<MemoryItemModel>(),
        allCount: updatedMemories.length,
        liveCount: liveMemories.length,
        sealedCount: sealedMemories.length,
      );

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));
    } catch (e) {
      print('❌ REALTIME: Error handling new memory: $e');
    }
  }

  void _handleMemoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    try {
      final memoryId = payload.newRecord['id'] as String;
      final currentModel = state.memoriesDashboardModel;
      if (currentModel == null) return;

      final memoryItems = currentModel.memoryItems;
      if (memoryItems == null || memoryItems.isEmpty) return;

      bool found = false;
      final updatedMemories = memoryItems.map((memory) {
        if (memory.id == memoryId) {
          found = true;
          return memory.copyWith(
            title: payload.newRecord['title'] as String? ?? memory.title,
            state: payload.newRecord['state'] as String? ?? memory.state,
          );
        }
        return memory;
      }).toList();

      if (!found) return;

      final updatedModel = currentModel.copyWith(
        memoryItems: updatedMemories.cast<MemoryItemModel>(),
      );

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));
    } catch (e) {
      print('❌ REALTIME: Error handling memory update: $e');
    }
  }

  void _handleMemoryDelete(PostgresChangePayload payload) {
    if (_isDisposed) return;

    try {
      final memoryId = payload.oldRecord['id'] as String;
      final currentModel = state.memoriesDashboardModel;
      if (currentModel == null) return;

      final memoryItems = currentModel.memoryItems;
      if (memoryItems == null || memoryItems.isEmpty) return;

      final updatedMemories =
          memoryItems.where((memory) => memory.id != memoryId).toList();

      final liveMemories =
          updatedMemories.where((m) => m.state == 'open').toList();
      final sealedMemories =
          updatedMemories.where((m) => m.state == 'sealed').toList();

      final updatedModel = currentModel.copyWith(
        memoryItems: updatedMemories.cast<MemoryItemModel>(),
        liveMemoryItems: liveMemories.cast<MemoryItemModel>(),
        sealedMemoryItems: sealedMemories.cast<MemoryItemModel>(),
        allCount: updatedMemories.length,
        liveCount: liveMemories.length,
        sealedCount: sealedMemories.length,
      );

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));
    } catch (e) {
      print('❌ REALTIME: Error handling memory deletion: $e');
    }
  }

  void _cleanupSubscriptions() {
    try {
      _storiesChannel?.unsubscribe();
      _memoriesChannel?.unsubscribe();
      _contributorsChannel?.unsubscribe();
      print('✅ REALTIME: Subscriptions cleaned up');
    } catch (e) {
      print('⚠️ REALTIME: Error cleaning up subscriptions: $e');
    }
  }

  void _safeSetState(MemoriesDashboardState newState) {
    if (_isDisposed) return;
    try {
      state = newState;
    } catch (e) {
      if (e.toString().contains('dispose') ||
          e.toString().contains('Bad state')) {
        _isDisposed = true;
        print('⚠️ MEMORIES NOTIFIER: Attempted to set state after dispose');
      } else {
        rethrow;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupSubscriptions();
    print('✅ SUCCESS: Cleaned up real-time subscriptions in memories notifier');
    super.dispose();
  }
}
