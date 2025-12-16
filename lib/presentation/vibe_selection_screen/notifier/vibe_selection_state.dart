part of 'vibe_selection_notifier.dart';

class VibeSelectionState extends Equatable {
  final int? selectedVibeIndex;
  final int? selectedMusicIndex;
  final bool? isPlayingMusic;
  final bool? isSelectionComplete;
  final VibeSelectionModel? vibeSelectionModel;

  VibeSelectionState({
    this.selectedVibeIndex,
    this.selectedMusicIndex,
    this.isPlayingMusic = false,
    this.isSelectionComplete = false,
    this.vibeSelectionModel,
  });

  @override
  List<Object?> get props => [
        selectedVibeIndex,
        selectedMusicIndex,
        isPlayingMusic,
        isSelectionComplete,
        vibeSelectionModel,
      ];

  VibeSelectionState copyWith({
    int? selectedVibeIndex,
    int? selectedMusicIndex,
    bool? isPlayingMusic,
    bool? isSelectionComplete,
    VibeSelectionModel? vibeSelectionModel,
  }) {
    return VibeSelectionState(
      selectedVibeIndex: selectedVibeIndex ?? this.selectedVibeIndex,
      selectedMusicIndex: selectedMusicIndex ?? this.selectedMusicIndex,
      isPlayingMusic: isPlayingMusic ?? this.isPlayingMusic,
      isSelectionComplete: isSelectionComplete ?? this.isSelectionComplete,
      vibeSelectionModel: vibeSelectionModel ?? this.vibeSelectionModel,
    );
  }
}
