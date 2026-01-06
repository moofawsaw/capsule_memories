import '../../../core/app_export.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/supabase_service.dart';
import '../models/memories_dashboard_model.dart';
import '../models/memory_item_model.dart';

part 'memories_dashboard_state.dart';

final memoriesDashboardNotifier = StateNotifierProvider.autoDispose<
    MemoriesDashboardNotifier, MemoriesDashboardState>(
  (ref) => MemoriesDashboardNotifier(
    MemoriesDashboardState(
      memoriesDashboardModel: MemoriesDashboardModel(),
    ),
  ),
);

class MemoriesDashboardNotifier extends StateNotifier<MemoriesDashboardState> {
  final _cacheService = MemoryCacheService();

  MemoriesDashboardNotifier(MemoriesDashboardState state) : super(state);

  void initialize() async {
    state = state.copyWith(isLoading: true);

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
    state = state.copyWith(isLoading: true);

    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser != null) {
        // Force refresh cache
        await _cacheService.refreshMemoryCache(currentUser.id);
        await _loadFromCache(currentUser.id);
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      print('Error refreshing memories: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}
