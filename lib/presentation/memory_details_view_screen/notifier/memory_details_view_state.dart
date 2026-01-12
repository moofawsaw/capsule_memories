part of 'memory_details_view_notifier.dart';

class MemoryDetailsViewState extends Equatable {
  final bool? isLoading;
  final String? errorMessage;
  final MemoryDetailsViewModel? memoryDetailsViewModel;
  final bool? showEventOptions;
  final bool? isReplayingAll;
  final int? selectedStoryIndex;

  /// ✅ NEW: needed because notifier is calling copyWith(isOwner/memoryState/memoryVisibility)
  final bool? isOwner;
  final String? memoryState; // "open" / "sealed"
  final String? memoryVisibility; // "public" / "private"

  MemoryDetailsViewState({
    this.isLoading,
    this.errorMessage,
    this.memoryDetailsViewModel,
    this.showEventOptions,
    this.isReplayingAll,
    this.selectedStoryIndex,
    this.isOwner,
    this.memoryState,
    this.memoryVisibility,
  });

  MemoryDetailsViewState copyWith({
    bool? isLoading,
    String? errorMessage,
    MemoryDetailsViewModel? memoryDetailsViewModel,
    bool? showEventOptions,
    bool? isReplayingAll,
    int? selectedStoryIndex,

    /// ✅ NEW
    bool? isOwner,
    String? memoryState,
    String? memoryVisibility,
  }) {
    return MemoryDetailsViewState(
      isLoading: isLoading ?? this.isLoading,

      // keep your existing behavior: passing null clears the error
      errorMessage: errorMessage,

      memoryDetailsViewModel: memoryDetailsViewModel ?? this.memoryDetailsViewModel,
      showEventOptions: showEventOptions ?? this.showEventOptions,
      isReplayingAll: isReplayingAll ?? this.isReplayingAll,
      selectedStoryIndex: selectedStoryIndex ?? this.selectedStoryIndex,

      /// ✅ NEW
      isOwner: isOwner ?? this.isOwner,
      memoryState: memoryState ?? this.memoryState,
      memoryVisibility: memoryVisibility ?? this.memoryVisibility,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    memoryDetailsViewModel,
    showEventOptions,
    isReplayingAll,
    selectedStoryIndex,

    /// ✅ NEW
    isOwner,
    memoryState,
    memoryVisibility,
  ];
}
