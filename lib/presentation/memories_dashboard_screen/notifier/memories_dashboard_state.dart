// lib/presentation/memories_dashboard_screen/notifier/memories_dashboard_state.dart

part of 'memories_dashboard_notifier.dart';

class MemoriesDashboardState extends Equatable {
  const MemoriesDashboardState({
    this.memoriesDashboardModel,
    this.isLoading,
    this.isSuccess,
    this.selectedTabIndex,
    this.selectedOwnership,
    this.selectedState,
    this.showOnlyOpen = false, // ✅ default: show ALL memories
  });

  final MemoriesDashboardModel? memoriesDashboardModel;
  final bool? isLoading;
  final bool? isSuccess;
  final int? selectedTabIndex;

  /// Ownership tabs: 'all' | 'created' | 'joined'
  final String? selectedOwnership;

  /// Legacy (if used elsewhere)
  final String? selectedState;

  /// ✅ Quick filter: true = only OPEN, false = show ALL (open + sealed)
  final bool showOnlyOpen;

  MemoriesDashboardState copyWith({
    MemoriesDashboardModel? memoriesDashboardModel,
    bool? isLoading,
    bool? isSuccess,
    int? selectedTabIndex,
    String? selectedOwnership,
    String? selectedState,
    bool? showOnlyOpen,
  }) {
    return MemoriesDashboardState(
      memoriesDashboardModel:
      memoriesDashboardModel ?? this.memoriesDashboardModel,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedOwnership: selectedOwnership ?? this.selectedOwnership,
      selectedState: selectedState ?? this.selectedState,
      showOnlyOpen: showOnlyOpen ?? this.showOnlyOpen,
    );
  }

  @override
  List<Object?> get props => [
    memoriesDashboardModel,
    isLoading,
    isSuccess,
    selectedTabIndex,
    selectedOwnership,
    selectedState,
    showOnlyOpen,
  ];
}
