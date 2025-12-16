part of 'memory_details_view_notifier.dart';

class MemoryDetailsViewState extends Equatable {
  final bool? isLoading;
  final bool? showEventOptions;
  final bool? isReplayingAll;
  final int? selectedStoryIndex;
  final MemoryDetailsViewModel? memoryDetailsViewModel;

  MemoryDetailsViewState({
    this.isLoading = false,
    this.showEventOptions = false,
    this.isReplayingAll = false,
    this.selectedStoryIndex,
    this.memoryDetailsViewModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        showEventOptions,
        isReplayingAll,
        selectedStoryIndex,
        memoryDetailsViewModel,
      ];

  MemoryDetailsViewState copyWith({
    bool? isLoading,
    bool? showEventOptions,
    bool? isReplayingAll,
    int? selectedStoryIndex,
    MemoryDetailsViewModel? memoryDetailsViewModel,
  }) {
    return MemoryDetailsViewState(
      isLoading: isLoading ?? this.isLoading,
      showEventOptions: showEventOptions ?? this.showEventOptions,
      isReplayingAll: isReplayingAll ?? this.isReplayingAll,
      selectedStoryIndex: selectedStoryIndex ?? this.selectedStoryIndex,
      memoryDetailsViewModel:
          memoryDetailsViewModel ?? this.memoryDetailsViewModel,
    );
  }
}
