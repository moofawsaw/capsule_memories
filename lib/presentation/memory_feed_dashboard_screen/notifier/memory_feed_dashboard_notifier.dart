import '../models/memory_feed_dashboard_model.dart';
import '../../../core/app_export.dart';

part 'memory_feed_dashboard_state.dart';

final memoryFeedDashboardNotifier = StateNotifierProvider.autoDispose<
    MemoryFeedDashboardNotifier, MemoryFeedDashboardState>(
  (ref) => MemoryFeedDashboardNotifier(
    MemoryFeedDashboardState(
      memoryFeedDashboardModel: MemoryFeedDashboardModel(),
    ),
  ),
);

class MemoryFeedDashboardNotifier
    extends StateNotifier<MemoryFeedDashboardState> {
  MemoryFeedDashboardNotifier(MemoryFeedDashboardState state) : super(state) {
    initialize();
  }

  void initialize() {
    final model = MemoryFeedDashboardModel();

    state = state.copyWith(
      memoryFeedDashboardModel: model,
      isLoading: false,
    );
  }

  void refreshFeed() {
    state = state.copyWith(isLoading: true);

    // Simulate refreshing feed data
    Future.delayed(Duration(seconds: 1), () {
      final updatedModel = MemoryFeedDashboardModel();

      state = state.copyWith(
        memoryFeedDashboardModel: updatedModel,
        isLoading: false,
        isRefreshed: true,
      );
    });
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
}
