part of 'memory_details_view_notifier.dart';

class MemoryDetailsViewState extends Equatable {
  final bool? isLoading;
  final String? errorMessage;
  final MemoryDetailsViewModel? memoryDetailsViewModel;
  final bool? showEventOptions;
  final bool? isReplayingAll;
  final int? selectedStoryIndex;

  MemoryDetailsViewState({
    this.isLoading,
    this.errorMessage,
    this.memoryDetailsViewModel,
    this.showEventOptions,
    this.isReplayingAll,
    this.selectedStoryIndex,
  });

  MemoryDetailsViewState copyWith({
    bool? isLoading,
    String? errorMessage,
    MemoryDetailsViewModel? memoryDetailsViewModel,
    bool? showEventOptions,
    bool? isReplayingAll,
    int? selectedStoryIndex,
  }) {
    return MemoryDetailsViewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      memoryDetailsViewModel:
          memoryDetailsViewModel ?? this.memoryDetailsViewModel,
      showEventOptions: showEventOptions ?? this.showEventOptions,
      isReplayingAll: isReplayingAll ?? this.isReplayingAll,
      selectedStoryIndex: selectedStoryIndex ?? this.selectedStoryIndex,
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
      ];
}
