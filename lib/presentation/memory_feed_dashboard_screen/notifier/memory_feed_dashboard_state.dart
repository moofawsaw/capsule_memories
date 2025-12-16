part of 'memory_feed_dashboard_notifier.dart';

class MemoryFeedDashboardState extends Equatable {
  final MemoryFeedDashboardModel? memoryFeedDashboardModel;
  final bool? isLoading;
  final bool? isRefreshed;
  final String? errorMessage;

  MemoryFeedDashboardState({
    this.memoryFeedDashboardModel,
    this.isLoading = false,
    this.isRefreshed = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        memoryFeedDashboardModel,
        isLoading,
        isRefreshed,
        errorMessage,
      ];

  MemoryFeedDashboardState copyWith({
    MemoryFeedDashboardModel? memoryFeedDashboardModel,
    bool? isLoading,
    bool? isRefreshed,
    String? errorMessage,
  }) {
    return MemoryFeedDashboardState(
      memoryFeedDashboardModel:
          memoryFeedDashboardModel ?? this.memoryFeedDashboardModel,
      isLoading: isLoading ?? this.isLoading,
      isRefreshed: isRefreshed ?? this.isRefreshed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
