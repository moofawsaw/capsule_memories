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
    this.showOpenMemories = true, // ✅ Open ON by default
  });

  final MemoriesDashboardModel? memoriesDashboardModel;
  final bool? isLoading;
  final bool? isSuccess;
  final int? selectedTabIndex;

  /// Ownership tabs: 'all' | 'created' | 'joined'
  final String? selectedOwnership;

  /// Legacy (if used elsewhere)
  final String? selectedState;

  /// ✅ ONE toggle: true=open, false=sealed
  final bool showOpenMemories;

  MemoriesDashboardState copyWith({
    MemoriesDashboardModel? memoriesDashboardModel,
    bool? isLoading,
    bool? isSuccess,
    int? selectedTabIndex,
    String? selectedOwnership,
    String? selectedState,
    bool? showOpenMemories,
  }) {
    return MemoriesDashboardState(
      memoriesDashboardModel:
      memoriesDashboardModel ?? this.memoriesDashboardModel,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedOwnership: selectedOwnership ?? this.selectedOwnership,
      selectedState: selectedState ?? this.selectedState,
      showOpenMemories: showOpenMemories ?? this.showOpenMemories,
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
    showOpenMemories,
  ];
}
