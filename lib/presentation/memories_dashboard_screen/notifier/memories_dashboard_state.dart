part of 'memories_dashboard_notifier.dart';

class MemoriesDashboardState extends Equatable {
  final bool? isLoading;
  final bool? isSuccess;
  final bool? isError;
  final String? errorMessage;
  final int? selectedTabIndex;
  final MemoriesDashboardModel? memoriesDashboardModel;

  MemoriesDashboardState({
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.errorMessage,
    this.selectedTabIndex = 0,
    this.memoriesDashboardModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        isSuccess,
        isError,
        errorMessage,
        selectedTabIndex,
        memoriesDashboardModel,
      ];

  MemoriesDashboardState copyWith({
    bool? isLoading,
    bool? isSuccess,
    bool? isError,
    String? errorMessage,
    int? selectedTabIndex,
    MemoriesDashboardModel? memoriesDashboardModel,
  }) {
    return MemoriesDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      memoriesDashboardModel:
          memoriesDashboardModel ?? this.memoriesDashboardModel,
    );
  }
}
