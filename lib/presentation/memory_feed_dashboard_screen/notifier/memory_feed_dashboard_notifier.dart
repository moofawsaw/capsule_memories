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

  // NEW: Real-time subscription channel
  RealtimeChannel? _storyViewsSubscription;

  // Add this line - Define missing fields
  bool _isDisposed = false;
  static const int _pageSize = 20;
  RealtimeChannel? _storiesChannel;
  RealtimeChannel? _memoriesChannel;

  MemoryFeedDashboardNotifier()
      : super(MemoryFeedDashboardState(
          memoryFeedDashboardModel: MemoryFeedDashboardModel(),
        )) {
    loadInitialData();
    // NEW: Subscribe to real-time story view updates
    _subscribeToStoryViews();
    // CRITICAL FIX: Enable real-time subscriptions for new stories
    _setupRealtimeSubscriptions();
  }

  /// Load initial data from the database
  Future<void> loadInitialData() async {
    if (_isDisposed) return;
    _safeSetState(
        state.copyWith(isLoading: true, isLoadingActiveMemories: true));

    try {
      // Fetch active memories for the current user
      final activeMemoriesData = await _feedService.fetchUserActiveMemories();

      // 📊 DEBUG: Log fetch start
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔧 NOTIFIER: Starting data fetch from FeedService');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Fetch initial page (offset 0) for all feeds
      final happeningNowData = await _feedService.fetchHappeningNowStories();
      final latestStoriesData = await _feedService.fetchLatestStories();
      final publicMemoriesData = await _feedService.fetchPublicMemories();
      final trendingData = await _feedService.fetchTrendingStories();
      final longestStreakData = await _feedService.fetchLongestStreakStories();
      final popularUserData = await _feedService.fetchPopularUserStories();

      // 📊 DEBUG: Log service response
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 SERVICE RESPONSE RECEIVED');
      print('   Happening Now Stories: ${happeningNowData.length}');
      print('   Latest Stories: ${latestStoriesData.length}');
      print('   Public Memories: ${publicMemoriesData.length}');
      print('   Trending Stories: ${trendingData.length}');
      print('   Longest Streak Stories: ${longestStreakData.length}');
      print('   Popular User Stories: ${popularUserData.length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // CRITICAL FIX: Use isRead from service response instead of hardcoding false
      final happeningNowStories = happeningNowData.map((item) {
        final categoryIcon = item['category_icon'] as String? ?? '';
        final isRead = item['is_read'] as bool? ?? false; // Use from service

        // 🔍 DEBUG: Log transformation for each story
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔄 TRANSFORMING STORY TO MODEL');
        print('   Story ID: "${item['id']}"');
        print('   Service Response is_read: $isRead');
        print('   Category Icon: "$categoryIcon"');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: categoryIcon,
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead, // Use actual read status from database
        );
      }).toList();

      // 📊 DEBUG: Verify transformed stories
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ STORIES TRANSFORMED TO MODEL OBJECTS');
      print('   Total Stories: ${happeningNowStories.length}');
      print(
          '   Stories with isRead=true: ${happeningNowStories.where((s) => s.isRead).length}');
      print(
          '   Stories with isRead=false: ${happeningNowStories.where((s) => !s.isRead).length}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // 🔍 DEBUG: Log each story's isRead status
      for (final story in happeningNowStories) {
        print(
            '   Story "${story.storyId}": isRead=${story.isRead}, categoryIcon="${story.categoryIcon}"');
      }

      // Transform latest stories
      final latestStories = latestStoriesData.map((item) {
        final isRead =
            item['is_read'] as bool? ?? false; // FIXED: Read from service

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead, // FIXED: Use actual read status from database
        );
      }).toList();

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
      final trendingStories = trendingData.map((item) {
        final isRead =
            item['is_read'] as bool? ?? false; // FIXED: Read from service

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead, // FIXED: Use actual read status from database
        );
      }).toList();

      // Transform longest streak stories
      final longestStreakStories = longestStreakData.map((item) {
        final isRead =
            item['is_read'] as bool? ?? false; // FIXED: Read from service

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead, // FIXED: Use actual read status from database
        );
      }).toList();

      // Transform popular user stories
      final popularUserStories = popularUserData.map((item) {
        final isRead =
            item['is_read'] as bool? ?? false; // FIXED: Read from service

        return HappeningNowStoryData(
          storyId: item['id'] as String,
          backgroundImage: item['thumbnail_url'] as String,
          profileImage: item['contributor_avatar'] as String,
          userName: item['contributor_name'] as String,
          categoryName: item['category_name'] as String,
          categoryIcon: item['category_icon'] as String? ?? '',
          timestamp:
              _getRelativeTime(DateTime.parse(item['created_at'] as String)),
          isRead: isRead, // FIXED: Use actual read status from database
        );
      }).toList();

      if (_isDisposed) return;

      // CRITICAL FIX: Always store lists (even if empty) instead of null
      // This allows UI to properly show loading states vs empty states
      final model = MemoryFeedDashboardModel(
        happeningNowStories: happeningNowStories.cast<HappeningNowStoryData>(),
        latestStories: latestStories.cast<HappeningNowStoryData>(),
        publicMemories: publicMemories.isNotEmpty ? publicMemories : null,
        trendingStories: trendingStories.cast<HappeningNowStoryData>(),
        longestStreakStories:
            longestStreakStories.cast<HappeningNowStoryData>(),
        popularUserStories: popularUserStories.cast<HappeningNowStoryData>(),
      );

      _safeSetState(state.copyWith(
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
      ));
    } catch (e) {
      print('Error loading feed data: $e');
      if (!_isDisposed) {
        _safeSetState(
            state.copyWith(isLoading: false, isLoadingActiveMemories: false));
      }
    }
  }

  /// NEW METHOD: Subscribe to real-time story view updates
  void _subscribeToStoryViews() {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        // ✅ SILENT SKIP: Real-time subscriptions are optional - feed works without them
        // Latest Stories feed is fully public and doesn't require authentication
        print(
            'ℹ️ INFO: Real-time subscription skipped (optional feature - requires authentication)');
        return;
      }

      print(
          '🔧 DEBUG: Setting up real-time subscription for user: $currentUserId');

      _storyViewsSubscription = _feedService.subscribeToStoryViews(
        onStoryViewed: (storyId, userId) {
          // 📋 DEBUG: Log FULL payload details
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('🔄 REALTIME CALLBACK TRIGGERED');
          print('📦 Full Payload Data:');
          print('   Story ID: "$storyId" (Type: ${storyId.runtimeType})');
          print('   User ID: "$userId" (Type: ${userId.runtimeType})');
          print(
              '   Current User ID: "$currentUserId" (Type: ${currentUserId.runtimeType})');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          // 🔍 DEBUG: Check if this is the current user (same device or different device)
          if (userId == currentUserId) {
            print('✅ MATCH: View is for current user - updating UI');
            _updateStoryReadStatus(storyId);
          } else {
            print('⏭️ SKIP: View is for different user ($userId) - ignoring');
          }
        },
      );

      // ✅ DEBUG: Log subscription status AFTER .subscribe()
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📡 SUBSCRIPTION STATUS CHECK');
      print('   Channel created: ${_storyViewsSubscription != null}');
      print('   Subscription object: $_storyViewsSubscription');

      // Wait a moment for subscription to establish, then check status
      Future.delayed(Duration(milliseconds: 500), () {
        final isJoined = _storyViewsSubscription?.isJoined ?? false;
        print('   Status after 500ms: ${isJoined ? 'joined' : 'not joined'}');
        if (isJoined) {
          print('✅ SUCCESS: Subscription is ACTIVE and listening');
        } else {
          print('⚠️ WARNING: Subscription status is NOT subscribed');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      });

      print('✅ SUCCESS: Subscribed to real-time story views in feed');
    } catch (e, stackTrace) {
      print('❌ ERROR subscribing to real-time story views: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// NEW METHOD: Update read status for a specific story in ALL lists (not just happening now)
  void _updateStoryReadStatus(String storyId) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 _updateStoryReadStatus() CALLED');
    print('   Looking for story ID: "$storyId" (Type: ${storyId.runtimeType})');

    final currentModel = state.memoryFeedDashboardModel;

    if (currentModel == null) {
      print('⚠️ WARNING: No memoryFeedDashboardModel available in state');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    bool anyUpdated = false;

    // CRITICAL FIX: Update story in ALL lists where it appears
    // Helper function to update story in a list
    List<HappeningNowStoryData>? updateListIfPresent(
      List<HappeningNowStoryData>? stories,
      String listName,
    ) {
      if (stories == null || stories.isEmpty) return null;

      bool foundInList = false;
      final updated = stories.map((story) {
        if (story.storyId == storyId) {
          foundInList = true;
          print('✅ MATCH FOUND in $listName: "${story.storyId}"');
          print('   Updating isRead: ${story.isRead} → true');
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

    // Update Happening Now stories
    final updatedHappeningNow = updateListIfPresent(
      currentModel.happeningNowStories,
      'Happening Now',
    );

    // Update Latest Stories
    final updatedLatest = updateListIfPresent(
      currentModel.latestStories,
      'Latest Stories',
    );

    // Update Trending stories
    final updatedTrending = updateListIfPresent(
      currentModel.trendingStories,
      'Trending',
    );

    // Update Longest Streak stories
    final updatedLongestStreak = updateListIfPresent(
      currentModel.longestStreakStories,
      'Longest Streak',
    );

    // Update Popular User stories
    final updatedPopularUsers = updateListIfPresent(
      currentModel.popularUserStories,
      'Popular Users',
    );

    if (!anyUpdated) {
      print('❌ NO MATCH: Story ID "$storyId" not found in any story list');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    // Emit updated state with refreshed story lists
    final updatedModel = currentModel.copyWith(
      happeningNowStories: updatedHappeningNow?.cast<HappeningNowStoryData>() ??
          currentModel.happeningNowStories,
      latestStories: updatedLatest?.cast<HappeningNowStoryData>() ??
          currentModel.latestStories,
      trendingStories: updatedTrending?.cast<HappeningNowStoryData>() ??
          currentModel.trendingStories,
      longestStreakStories:
          updatedLongestStreak?.cast<HappeningNowStoryData>() ??
              currentModel.longestStreakStories,
      popularUserStories: updatedPopularUsers?.cast<HappeningNowStoryData>() ??
          currentModel.popularUserStories,
    );

    _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));

    print('✅ SUCCESS: State updated with new isRead status across all feeds');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  @override
  void dispose() {
    // NEW: Unsubscribe from real-time updates when notifier is disposed
    _feedService.unsubscribeFromStoryViews();
    _storyViewsSubscription?.unsubscribe();
    // CRITICAL FIX: Cleanup story and memory subscriptions
    _cleanupSubscriptions();
    print('✅ SUCCESS: Cleaned up real-time subscriptions in feed notifier');
    _isDisposed = true;
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
      final storyId = payload.newRecord['id'] as String;
      final contributorId = payload.newRecord['contributor_id'] as String;
      final memoryId =
          payload.newRecord['memory_id'] as String; // CRITICAL: Get memory ID
      final rawThumbnailUrl = payload.newRecord['thumbnail_url'] as String?;
      final videoUrl = payload.newRecord['video_url'] as String?;
      final client = SupabaseService.instance.client;

      if (client == null) return;

      // CRITICAL FIX: Resolve media URLs BEFORE creating story object
      final resolvedThumbnailUrl =
          StorageUtils.resolveStoryMediaUrl(rawThumbnailUrl);

      print('🔍 REALTIME: Raw thumbnail URL: $rawThumbnailUrl');
      print('🔍 REALTIME: Resolved thumbnail URL: $resolvedThumbnailUrl');

      // CRITICAL FIX: Fetch contributor profile separately to get avatar data
      final profileResponse = await client
          .from('user_profiles')
          .select('id, display_name, avatar_url')
          .eq('id', contributorId)
          .single();

      if (_isDisposed) return;

      // CRITICAL FIX: Resolve avatar URL from profile
      final rawAvatarUrl = profileResponse['avatar_url'] as String?;
      final resolvedAvatarUrl = StorageUtils.resolveAvatarUrl(rawAvatarUrl);

      print('🔍 REALTIME: Raw avatar URL: $rawAvatarUrl');
      print('🔍 REALTIME: Resolved avatar URL: $resolvedAvatarUrl');

      // Fetch memory and category data
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

      // Create story data with RESOLVED URLs
      final newStoryData = HappeningNowStoryData(
        storyId: storyId,
        backgroundImage: resolvedThumbnailUrl ?? '', // ✅ RESOLVED URL
        profileImage: resolvedAvatarUrl ?? '', // ✅ RESOLVED URL
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

      print('✅ REALTIME: Story object created with resolved URLs');
      print('   Thumbnail: ${newStoryData.backgroundImage}');
      print('   Avatar: ${newStoryData.profileImage}');

      // Add to happening now at the beginning
      final currentStories =
          state.memoryFeedDashboardModel?.happeningNowStories ?? [];
      final updatedStories = [newStoryData, ...currentStories];

      // 🚀 NEW: Update memory card in Public Memories timeline
      final currentMemories =
          state.memoryFeedDashboardModel?.publicMemories ?? [];
      List<CustomMemoryItem>? updatedMemories;

      print('🔍 REALTIME: Looking for memory "$memoryId" in public memories');

      // Find the memory that this story belongs to
      final memoryIndex = currentMemories.indexWhere((m) => m.id == memoryId);

      if (memoryIndex != -1) {
        print(
            '✅ REALTIME: Found memory at index $memoryIndex - updating media items');

        final targetMemory = currentMemories[memoryIndex];
        final currentMediaItems = targetMemory.mediaItems ?? [];

        // Create new media item for this story
        final newMediaItem = CustomMediaItem(
          imagePath: resolvedThumbnailUrl ?? '',
          hasPlayButton: videoUrl != null,
        );

        // Add new media item at the beginning (most recent first)
        final updatedMediaItems =
            [newMediaItem, ...currentMediaItems].take(2).toList();

        // Create updated memory with new media items
        final updatedMemory = targetMemory.copyWith(
          mediaItems: updatedMediaItems,
        );

        // Replace the memory in the list
        updatedMemories = [...currentMemories];
        updatedMemories[memoryIndex] = updatedMemory;

        print('✅ REALTIME: Memory card updated with new story media');
        print('   Media items count: ${updatedMediaItems.length}');
      } else {
        print(
            '⚠️ REALTIME: Memory "$memoryId" not found in public memories - may not be public');
        // Memory not in public feed (could be private or not yet loaded)
        updatedMemories = null;
      }

      final updatedModel = state.memoryFeedDashboardModel?.copyWith(
        happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
        publicMemories: updatedMemories, // Update memory cards if found
      );

      _safeSetState(state.copyWith(memoryFeedDashboardModel: updatedModel));

      print(
          '✅ REALTIME: New story added to feed ${updatedMemories != null ? "and memory card updated" : "(memory card not updated)"}');
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
      if (story.storyId == storyId) {
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
        // CRITICAL FIX: Read is_read from service response instead of hardcoding false
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
          isRead: isRead, // FIXED: Use actual read status from database
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
        // CRITICAL FIX: Read is_read from service response instead of hardcoding false
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
          isRead: isRead, // FIXED: Use actual read status from database
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
        // CRITICAL FIX: Read is_read from service response instead of hardcoding false
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
          isRead: isRead, // FIXED: Use actual read status from database
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
        // CRITICAL FIX: Read is_read from service response instead of hardcoding false
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
          isRead: isRead, // FIXED: Use actual read status from database
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
        // CRITICAL FIX: Read is_read from service response instead of hardcoding false
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
          isRead: isRead, // FIXED: Use actual read status from database
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
      await loadInitialData();

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
          if (story.storyId == storyId) {
            return story.copyWith(isRead: true);
          }
          return story;
        }).toList();

        final updatedModel = currentModel.copyWith(
          happeningNowStories: updatedStories.cast<HappeningNowStoryData>(),
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
        // CRITICAL FIX: Read is_read from service response instead of hardcoding false
        final isRead = story['is_read'] as bool? ?? false;

        return HappeningNowStoryData(
          storyId: story['id'] as String? ?? '',
          backgroundImage: story['thumbnail_url'] as String? ?? '',
          profileImage: story['contributor_avatar'] as String? ?? '',
          userName: story['contributor_name'] as String? ?? '',
          categoryName: story['category_name'] as String? ?? '',
          categoryIcon: story['category_icon'] as String? ?? '',
          timestamp: _getRelativeTime(
              DateTime.parse(story['created_at'] as String? ?? '')),
          isRead: isRead, // FIXED: Use actual read status from database
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
