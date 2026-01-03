part of 'memories_dashboard_notifier.dart';

class MemoriesDashboardState extends Equatable {
  final bool? isLoading;
  final bool? isSuccess;
  final bool? isError;
  final String? errorMessage;
  final int? selectedTabIndex;
  final String? selectedOwnership; // NEW: "created" or "joined"
  final String? selectedState; // NEW: "all", "live", or "sealed"
  final MemoriesDashboardModel? memoriesDashboardModel;

  MemoriesDashboardState({
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.errorMessage,
    this.selectedTabIndex = 0,
    this.selectedOwnership = 'created', // Default: "Created by Me"
    this.selectedState = 'all', // Default: "All"
    this.memoriesDashboardModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        isSuccess,
        isError,
        errorMessage,
        selectedTabIndex,
        selectedOwnership,
        selectedState,
        memoriesDashboardModel,
      ];

  MemoriesDashboardState copyWith({
    bool? isLoading,
    bool? isSuccess,
    bool? isError,
    String? errorMessage,
    int? selectedTabIndex,
    String? selectedOwnership,
    String? selectedState,
    MemoriesDashboardModel? memoriesDashboardModel,
  }) {
    return MemoriesDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedOwnership: selectedOwnership ?? this.selectedOwnership,
      selectedState: selectedState ?? this.selectedState,
      memoriesDashboardModel:
          memoriesDashboardModel ?? this.memoriesDashboardModel,
    );
  }
}
