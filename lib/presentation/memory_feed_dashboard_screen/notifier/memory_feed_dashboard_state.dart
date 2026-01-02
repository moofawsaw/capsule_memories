part of 'memory_feed_dashboard_notifier.dart';

/// Represents the state of MemoryFeedDashboard screen
class MemoryFeedDashboardState extends Equatable {
  final MemoryFeedDashboardModel? memoryFeedDashboardModel;
  final bool? isLoading;
  final bool isLoadingMore;
  final bool hasMoreHappeningNow;
  final bool hasMorePublicMemories;
  final bool hasMoreTrending;
  final bool hasMoreLongestStreak;
  final bool hasMorePopularUsers;
  final bool hasMorePopularMemories;
  final bool hasMoreLatestStories;
  final List<Map<String, dynamic>> activeMemories;
  final List<Map<String, dynamic>>? categories;
  final bool isLoadingCategories;

  MemoryFeedDashboardState({
    this.memoryFeedDashboardModel,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreHappeningNow = true,
    this.hasMorePublicMemories = true,
    this.hasMoreTrending = true,
    this.hasMoreLongestStreak = true,
    this.hasMorePopularUsers = true,
    this.hasMorePopularMemories = true,
    this.hasMoreLatestStories = true,
    this.activeMemories = const [],
    this.categories,
    this.isLoadingCategories = false,
  });

  MemoryFeedDashboardState copyWith({
    MemoryFeedDashboardModel? memoryFeedDashboardModel,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreHappeningNow,
    bool? hasMorePublicMemories,
    bool? hasMoreTrending,
    bool? hasMoreLongestStreak,
    bool? hasMorePopularUsers,
    bool? hasMorePopularMemories,
    bool? hasMoreLatestStories,
    List<Map<String, dynamic>>? activeMemories,
    List<Map<String, dynamic>>? categories,
    bool? isLoadingCategories,
  }) {
    return MemoryFeedDashboardState(
      memoryFeedDashboardModel:
          memoryFeedDashboardModel ?? this.memoryFeedDashboardModel,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreHappeningNow: hasMoreHappeningNow ?? this.hasMoreHappeningNow,
      hasMorePublicMemories:
          hasMorePublicMemories ?? this.hasMorePublicMemories,
      hasMoreTrending: hasMoreTrending ?? this.hasMoreTrending,
      hasMoreLongestStreak: hasMoreLongestStreak ?? this.hasMoreLongestStreak,
      hasMorePopularUsers: hasMorePopularUsers ?? this.hasMorePopularUsers,
      hasMorePopularMemories:
          hasMorePopularMemories ?? this.hasMorePopularMemories,
      hasMoreLatestStories: hasMoreLatestStories ?? this.hasMoreLatestStories,
      activeMemories: activeMemories ?? this.activeMemories,
      categories: categories ?? this.categories,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
    );
  }

  @override
  List<Object?> get props => [
        memoryFeedDashboardModel,
        isLoading,
        isLoadingMore,
        hasMoreHappeningNow,
        hasMorePublicMemories,
        hasMoreTrending,
        hasMoreLongestStreak,
        hasMorePopularUsers,
        hasMorePopularMemories,
        hasMoreLatestStories,
        activeMemories,
        categories,
        isLoadingCategories,
      ];
}
