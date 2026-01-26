part of 'memory_feed_dashboard_notifier.dart';

/// Represents the state of MemoryFeedDashboard screen
class MemoryFeedDashboardState extends Equatable {
  final MemoryFeedDashboardModel? memoryFeedDashboardModel;
  final bool? isLoading;
  final bool hasDbConnectionError;
  final bool isLoadingMore;
  final bool hasMoreHappeningNow;
  final bool hasMorePublicMemories;
  final bool hasMoreTrending;
  final bool hasMoreLongestStreak;
  final bool hasMorePopularUsers;
  final bool hasMorePopularNow;
  final bool hasMorePopularMemories;
  final bool hasMoreLatestStories;
  final List<Map<String, dynamic>> activeMemories;
  final List<Map<String, dynamic>>? categories;
  final bool isLoadingCategories;
  final bool isLoadingActiveMemories;

  MemoryFeedDashboardState({
    this.memoryFeedDashboardModel,
    this.isLoading = false,
    this.hasDbConnectionError = false,
    this.isLoadingMore = false,
    this.hasMoreHappeningNow = true,
    this.hasMorePublicMemories = true,
    this.hasMoreTrending = true,
    this.hasMoreLongestStreak = true,
    this.hasMorePopularUsers = true,
    this.hasMorePopularNow = true,
    this.hasMorePopularMemories = true,
    this.hasMoreLatestStories = true,
    this.activeMemories = const [],
    this.categories,
    this.isLoadingCategories = false,
    this.isLoadingActiveMemories = true,
  });

  MemoryFeedDashboardState copyWith({
    MemoryFeedDashboardModel? memoryFeedDashboardModel,
    bool? isLoading,
    bool? hasDbConnectionError,
    bool? isLoadingMore,
    bool? hasMoreHappeningNow,
    bool? hasMorePublicMemories,
    bool? hasMoreTrending,
    bool? hasMoreLongestStreak,
    bool? hasMorePopularUsers,
    bool? hasMorePopularNow,
    bool? hasMorePopularMemories,
    bool? hasMoreLatestStories,
    List<Map<String, dynamic>>? activeMemories,
    List<Map<String, dynamic>>? categories,
    bool? isLoadingCategories,
    bool? isLoadingActiveMemories,
  }) {
    return MemoryFeedDashboardState(
      memoryFeedDashboardModel:
          memoryFeedDashboardModel ?? this.memoryFeedDashboardModel,
      isLoading: isLoading ?? this.isLoading,
      hasDbConnectionError: hasDbConnectionError ?? this.hasDbConnectionError,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreHappeningNow: hasMoreHappeningNow ?? this.hasMoreHappeningNow,
      hasMorePublicMemories:
          hasMorePublicMemories ?? this.hasMorePublicMemories,
      hasMoreTrending: hasMoreTrending ?? this.hasMoreTrending,
      hasMoreLongestStreak: hasMoreLongestStreak ?? this.hasMoreLongestStreak,
      hasMorePopularUsers: hasMorePopularUsers ?? this.hasMorePopularUsers,
      hasMorePopularNow: hasMorePopularNow ?? this.hasMorePopularNow,
      hasMorePopularMemories:
          hasMorePopularMemories ?? this.hasMorePopularMemories,
      hasMoreLatestStories: hasMoreLatestStories ?? this.hasMoreLatestStories,
      activeMemories: activeMemories ?? this.activeMemories,
      categories: categories ?? this.categories,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingActiveMemories:
          isLoadingActiveMemories ?? this.isLoadingActiveMemories,
    );
  }

  @override
  List<Object?> get props => [
        memoryFeedDashboardModel,
        isLoading,
        hasDbConnectionError,
        isLoadingMore,
        hasMoreHappeningNow,
        hasMorePublicMemories,
        hasMoreTrending,
        hasMoreLongestStreak,
        hasMorePopularUsers,
        hasMorePopularNow,
        hasMorePopularMemories,
        hasMoreLatestStories,
        activeMemories,
        categories,
        isLoadingCategories,
        isLoadingActiveMemories,
      ];
}
