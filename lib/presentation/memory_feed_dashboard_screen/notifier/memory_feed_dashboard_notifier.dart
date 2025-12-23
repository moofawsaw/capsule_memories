import '../../../core/app_export.dart';
import '../../../services/feed_service.dart';
import '../model/memory_feed_dashboard_model.dart';

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
  }

  final _feedService = FeedService();

  /// Load all feed data from the database
  Future<void> loadFeedData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Fetch data from database
      final happeningNowData = await _feedService.fetchHappeningNowStories();
      final publicMemoriesData = await _feedService.fetchPublicMemories();
      final trendingData = await _feedService.fetchTrendingStories();

      // Debug: Log what we received from service
      print(
          '🔍 DEBUG: Notifier received ${happeningNowData.length} happening now stories');
      for (final item in happeningNowData) {
        print(
            '🔍 DEBUG: Notifier mapping story - category_icon: "${item['category_icon']}"');
      }

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

      final model = MemoryFeedDashboardModel(
        happeningNowStories: happeningNowStories.isNotEmpty
            ? happeningNowStories.cast<HappeningNowStoryData>()
            : null, // Will use defaults if empty
        publicMemories: publicMemories.isNotEmpty ? publicMemories : null,
        trendingStories: trendingStories.isNotEmpty
            ? trendingStories.cast<HappeningNowStoryData>()
            : null,
      );

      state = state.copyWith(
        memoryFeedDashboardModel: model,
        isLoading: false,
      );
    } catch (e) {
      print('Error loading feed data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshFeed() async {
    state = state.copyWith(isLoading: true);

    try {
      // Re-fetch all data
      await loadFeedData();

      state = state.copyWith(
        isLoading: false,
        isRefreshed: true,
      );
    } catch (e) {
      print('Error refreshing feed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void markStoryAsViewed(String storyId) {
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

      state = state.copyWith(memoryFeedDashboardModel: updatedModel);
    }
  }

  void toggleMemoryLike(String memoryId) {
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

      state = state.copyWith(memoryFeedDashboardModel: updatedModel);
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

      state = state.copyWith(
        memoryFeedDashboardModel: state.memoryFeedDashboardModel?.copyWith(
          happeningNowStories: transformedStories.cast<HappeningNowStoryData>(),
        ),
      );
    } catch (e) {
      print('Error loading happening now stories: $e');
    }
  }
}
