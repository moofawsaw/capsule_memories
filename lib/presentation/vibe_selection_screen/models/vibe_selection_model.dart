import '../../../core/app_export.dart';
import '../../../widgets/custom_music_list.dart';

/// This class is used in the [VibeSelectionScreen] screen.

// ignore_for_file: must_be_immutable
class VibeSelectionModel extends Equatable {
  VibeSelectionModel({
    this.selectedVibe,
    this.selectedMusicIndex,
    this.musicItems,
    this.isPlaying,
    this.id,
  }) {
    selectedVibe = selectedVibe ?? "Fun";
    selectedMusicIndex = selectedMusicIndex;
    musicItems = musicItems ?? [];
    isPlaying = isPlaying ?? false;
    id = id ?? "";
  }

  String? selectedVibe;
  int? selectedMusicIndex;
  List<MusicListItem>? musicItems;
  bool? isPlaying;
  String? id;

  VibeSelectionModel copyWith({
    String? selectedVibe,
    int? selectedMusicIndex,
    List<MusicListItem>? musicItems,
    bool? isPlaying,
    String? id,
  }) {
    return VibeSelectionModel(
      selectedVibe: selectedVibe ?? this.selectedVibe,
      selectedMusicIndex: selectedMusicIndex ?? this.selectedMusicIndex,
      musicItems: musicItems ?? this.musicItems,
      isPlaying: isPlaying ?? this.isPlaying,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        selectedVibe,
        selectedMusicIndex,
        musicItems,
        isPlaying,
        id,
      ];
}
