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

  // NEW: Real-time subscription channels
  RealtimeChannel? _storiesChannel;
  RealtimeChannel? _memoriesChannel;
  bool _isDisposed = false;

  MemoriesDashboardNotifier()
      : super(MemoriesDashboardState(
          memoriesDashboardModel: MemoriesDashboardModel(),
        )) {
    // CRITICAL FIX: Enable real-time subscriptions for new stories and memories
    _setupRealtimeSubscriptions();
  }

  void initialize() async {
    // FIXED: Simplified initialization - always load if empty, don't block on existing data
    final hasData = state.memoriesDashboardModel?.memoryItems != null &&
        (state.memoriesDashboardModel?.memoryItems?.isNotEmpty ?? false);

    if (hasData && !(state.isLoading ?? false)) {
      print(
          '🔍 MEMORIES DEBUG: Dashboard already has data and not loading, skipping initialization');
      return;
    }

    // FIXED: Only set loading if we don't have data yet
    if (!hasData) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;

      print('🔍 MEMORIES DEBUG: Initializing memories dashboard');
      print('🔍 MEMORIES DEBUG: Current user ID: ${currentUser?.id}');

      if (currentUser == null) {
        print('❌ MEMORIES DEBUG: No authenticated user found');
        state = state.copyWith(isLoading: false);
        return;
      }

      // Use cache service for data loading
      await _loadFromCache(currentUser.id);

      state = state.copyWith(
        isLoading: false,
        selectedTabIndex: 0,
        selectedOwnership: 'created', // Default: "Created by Me"
        selectedState: 'all', // Default: "All"
      );

      print('✅ MEMORIES DEBUG: Initialization complete');
    } catch (e) {
      print('❌ MEMORIES DEBUG: Error initializing memories dashboard: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadFromCache(String userId) async {
    try {
      print('🔍 MEMORIES DEBUG: Loading data from cache service');

      // Load stories and memories from cache
      final stories = await _cacheService.getStories(userId);
      final memories = await _cacheService.getMemories(userId);

      print(
          '✅ MEMORIES DEBUG: Loaded ${stories.length} stories and ${memories.length} memories from cache');

      final liveMemories = memories.where((m) => m.state == 'open').toList();
      final sealedMemories =
          memories.where((m) => m.state == 'sealed').toList();

      state = state.copyWith(
        memoriesDashboardModel: state.memoriesDashboardModel?.copyWith(
          storyItems: stories,
          memoryItems: memories,
          liveMemoryItems: liveMemories,
          sealedMemoryItems: sealedMemories,
          allCount: memories.length,
          liveCount: liveMemories.length,
          sealedCount: sealedMemories.length,
        ),
      );

      print('✅ MEMORIES DEBUG: State updated with cached data');
    } catch (e) {
      print('❌ MEMORIES DEBUG: Error loading from cache: $e');
    }
  }

  void updateSelectedTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  /// Update ownership filter ("created" or "joined")
  void updateOwnershipFilter(String ownership) {
    print('🔍 MEMORIES DEBUG: Updating ownership filter to: $ownership');
    state = state.copyWith(selectedOwnership: ownership);
  }

  /// Update state filter ("all", "live", or "sealed")
  void updateStateFilter(String stateFilter) {
    print('🔍 MEMORIES DEBUG: Updating state filter to: $stateFilter');
    state = state.copyWith(selectedState: stateFilter);
  }

  /// Get filtered memories based on ownership and state filters
  List<MemoryItemModel> getFilteredMemories(String userId) {
    final allMemories = state.memoriesDashboardModel?.memoryItems ?? [];
    final ownership = state.selectedOwnership ?? 'created';
    final stateFilter = state.selectedState ?? 'all';

    print('🔍 MEMORIES DEBUG: Filtering memories');
    print('   - Ownership: $ownership');
    print('   - State: $stateFilter');
    print('   - Total memories: ${allMemories.length}');

    // Step 1: Filter by ownership
    List<MemoryItemModel> filteredByOwnership;
    if (ownership == 'created') {
      filteredByOwnership =
          allMemories.where((m) => m.creatorId == userId).toList();
      print(
          '   - Filtered by "Created by Me": ${filteredByOwnership.length} memories');
    } else {
      // "joined" - memories where user is NOT the creator
      filteredByOwnership =
          allMemories.where((m) => m.creatorId != userId).toList();
      print(
          '   - Filtered by "Joined": ${filteredByOwnership.length} memories');
    }

    // Step 2: Filter by state
    List<MemoryItemModel> finalFiltered;
    if (stateFilter == 'all') {
      finalFiltered = filteredByOwnership;
    } else if (stateFilter == 'live') {
      finalFiltered =
          filteredByOwnership.where((m) => m.state == 'open').toList();
    } else {
      // sealed
      finalFiltered =
          filteredByOwnership.where((m) => m.state == 'sealed').toList();
    }

    print('✅ MEMORIES DEBUG: Final filtered count: ${finalFiltered.length}');
    return finalFiltered;
  }

  /// NEW METHOD: Get count of memories for specific ownership filter
  int getOwnershipCount(String userId, String ownership) {
    final allMemories = state.memoriesDashboardModel?.memoryItems ?? [];

    if (ownership == 'created') {
      return allMemories.where((m) => m.creatorId == userId).length;
    } else {
      return allMemories.where((m) => m.creatorId != userId).length;
    }
  }

  void loadAllStories() async {
    state = state.copyWith(isLoading: true);

    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser != null) {
        final stories = await _cacheService.getStories(currentUser.id);
        state = state.copyWith(
          memoriesDashboardModel: state.memoriesDashboardModel?.copyWith(
            storyItems: stories,
          ),
        );
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      print('Error loading all stories: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshMemories() async {
    // FIXED: Don't set loading state during refresh - just update data silently
    print('🔄 MEMORIES DEBUG: Refreshing memories...');

    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser != null) {
        // Force refresh cache
        await _cacheService.refreshMemoryCache(currentUser.id);
        await _loadFromCache(currentUser.id);

        print('✅ MEMORIES DEBUG: Memories refreshed successfully');

        // Show success feedback
        state = state.copyWith(isSuccess: true);

        // Reset success flag after short delay
        Future.delayed(Duration(milliseconds: 500), () {
          if (!_isDisposed) {
            state = state.copyWith(isSuccess: false);
          }
        });
      }
    } catch (e) {
      print('❌ MEMORIES DEBUG: Error refreshing memories: $e');
    }
  }

  /// NEW METHOD: Setup real-time subscriptions for stories and memories
  void _setupRealtimeSubscriptions() {
    final client = SupabaseService.instance.client;
    if (client == null) {
      print('⚠️ REALTIME: Supabase client not available');
      return;
    }

    try {
      // Subscribe to new stories in user's memories
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

      // Subscribe to memory updates
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
          .subscribe();

      print('✅ REALTIME: Subscriptions setup complete for memories dashboard');
    } catch (e) {
      print('❌ REALTIME: Error setting up subscriptions: $e');
    }
  }

  /// NEW METHOD: Handle new story inserted
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

      // Check if this story belongs to user's memories
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Verify user has access to this memory
      final memoryResponse = await client
          .from('memories')
          .select('creator_id')
          .eq('id', memoryId)
          .single();

      if (_isDisposed) return;

      final isUserMemory = memoryResponse['creator_id'] == currentUserId;

      // Check if user is a contributor
      final contributorCheck = await client
          .from('memory_contributors')
          .select('id')
          .eq('memory_id', memoryId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (_isDisposed) return;

      final isContributor = contributorCheck != null;

      // Only process if user owns or is contributor to this memory
      if (!isUserMemory && !isContributor) return;

      // Resolve media URLs
      final resolvedThumbnailUrl =
          StorageUtils.resolveStoryMediaUrl(rawThumbnailUrl);

      // Fetch contributor profile
      final profileResponse = await client
          .from('user_profiles')
          .select('id, display_name, avatar_url')
          .eq('id', contributorId)
          .single();

      if (_isDisposed) return;

      final rawAvatarUrl = profileResponse['avatar_url'] as String?;
      final resolvedAvatarUrl = StorageUtils.resolveAvatarUrl(rawAvatarUrl);

      // Create new story item
      final newStoryItem = StoryItemModel(
        id: storyId,
        backgroundImage: resolvedThumbnailUrl ?? '',
        profileImage: resolvedAvatarUrl ?? '',
        timestamp: 'Just now',
        navigateTo: storyId,
        isRead: false,
      );

      // Add to beginning of stories list
      final currentStories = state.memoriesDashboardModel?.storyItems ?? [];
      final updatedStories = [newStoryItem, ...currentStories];

      final updatedModel = state.memoriesDashboardModel?.copyWith(
        storyItems: updatedStories.cast<StoryItemModel>(),
      );

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));

      print('✅ REALTIME: New story added to memories dashboard');
    } catch (e) {
      print('❌ REALTIME: Error handling new story: $e');
    }
  }

  /// NEW METHOD: Handle story update
  void _handleStoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    print('🔔 REALTIME: Story updated: ${payload.newRecord['id']}');

    try {
      final storyId = payload.newRecord['id'] as String;
      final currentModel = state.memoriesDashboardModel;

      if (currentModel == null) return;

      // Update story in list if it exists
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

      print('✅ REALTIME: Story updated in memories dashboard');
    } catch (e) {
      print('❌ REALTIME: Error handling story update: $e');
    }
  }

  /// NEW METHOD: Handle new memory inserted
  void _handleNewMemory(PostgresChangePayload payload) async {
    if (_isDisposed) return;

    print('🔔 REALTIME: New memory detected: ${payload.newRecord['id']}');

    try {
      final memoryId = payload.newRecord['id'] as String;
      final creatorId = payload.newRecord['creator_id'] as String;
      final client = SupabaseService.instance.client;

      if (client == null) return;

      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Only add if user created this memory
      if (creatorId != currentUserId) return;

      // Fetch full memory details
      final response = await client.from('memories').select('''
            id,
            title,
            start_time,
            end_time,
            location_name,
            state,
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

      final newMemoryItem = MemoryItemModel(
        id: response['id'],
        title: response['title'],
        date: DateTime.parse(response['start_time']).toString(),
        eventDate: response['start_time'],
        eventTime: response['start_time'],
        endDate: response['end_time'],
        endTime: response['end_time'],
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

      // Add to beginning of memories list
      final currentMemories = state.memoriesDashboardModel?.memoryItems ?? [];
      final updatedMemories = [newMemoryItem, ...currentMemories];

      final updatedModel = state.memoriesDashboardModel?.copyWith(
        memoryItems: updatedMemories.cast<MemoryItemModel>(),
      );

      _safeSetState(state.copyWith(memoriesDashboardModel: updatedModel));

      print('✅ REALTIME: New memory added to dashboard');
    } catch (e) {
      print('❌ REALTIME: Error handling new memory: $e');
    }
  }

  /// NEW METHOD: Handle memory update
  void _handleMemoryUpdate(PostgresChangePayload payload) {
    if (_isDisposed) return;

    print('🔔 REALTIME: Memory updated: ${payload.newRecord['id']}');

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

      print('✅ REALTIME: Memory updated in dashboard');
    } catch (e) {
      print('❌ REALTIME: Error handling memory update: $e');
    }
  }

  /// NEW METHOD: Cleanup real-time subscriptions
  void _cleanupSubscriptions() {
    try {
      _storiesChannel?.unsubscribe();
      _memoriesChannel?.unsubscribe();
      print('✅ REALTIME: Subscriptions cleaned up');
    } catch (e) {
      print('⚠️ REALTIME: Error cleaning up subscriptions: $e');
    }
  }

  /// NEW METHOD: Safely set state only if notifier is not disposed
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
