import '../../../widgets/custom_music_list.dart';
import '../models/vibe_selection_model.dart';
import '../../../core/app_export.dart';

part 'vibe_selection_state.dart';

final vibeSelectionNotifier = StateNotifierProvider.autoDispose<
    VibeSelectionNotifier, VibeSelectionState>(
  (ref) => VibeSelectionNotifier(
    VibeSelectionState(
      vibeSelectionModel: VibeSelectionModel(),
    ),
  ),
);

class VibeSelectionNotifier extends StateNotifier<VibeSelectionState> {
  VibeSelectionNotifier(VibeSelectionState state) : super(state) {
    initialize();
  }

  void initialize() {
    final musicItems = [
      MusicListItem(
        title: 'Swag Song',
        subtitle: '121 stories',
        leadingImagePath: ImageConstant.imgDollar,
        subtitleIconPath: ImageConstant.imgIconsBlueGray300,
        playButtonIconPath: ImageConstant.imgPlayCircleGray50,
      ),
      MusicListItem(
        title: 'Swag Song',
        subtitle: '121 stories',
        leadingImagePath: ImageConstant.imgDollar,
        subtitleIconPath: ImageConstant.imgIconsBlueGray300,
        playButtonIconPath: ImageConstant.imgPlayCircleGray50,
      ),
      MusicListItem(
        title: 'Swag Song',
        subtitle: '121 stories',
        leadingImagePath: ImageConstant.imgDollar,
        subtitleIconPath: ImageConstant.imgIconsBlueGray300,
        playButtonIconPath: ImageConstant.imgPlayCircleGray50,
      ),
      MusicListItem(
        title: 'Swag Song',
        subtitle: '121 stories',
        leadingImagePath: ImageConstant.imgDollar,
        subtitleIconPath: ImageConstant.imgIconsBlueGray300,
        playButtonIconPath: ImageConstant.imgPlayCircleGray50,
      ),
    ];

    state = state.copyWith(
      selectedVibeIndex: 0,
      selectedMusicIndex: null,
      isPlayingMusic: false,
      vibeSelectionModel: state.vibeSelectionModel?.copyWith(
        musicItems: musicItems,
        selectedVibe: 'Fun',
      ),
    );
  }

  void selectVibe(int index) {
    final vibeNames = ['Fun', 'Crazy', 'Sexy', 'Cute'];
    state = state.copyWith(
      selectedVibeIndex: index,
      vibeSelectionModel: state.vibeSelectionModel?.copyWith(
        selectedVibe: vibeNames[index],
      ),
    );
  }

  void selectMusic(int index) {
    state = state.copyWith(
      selectedMusicIndex: index,
      vibeSelectionModel: state.vibeSelectionModel?.copyWith(
        selectedMusicIndex: index,
      ),
    );
  }

  void togglePlayMusic(int index) {
    final isCurrentlyPlaying =
        state.selectedMusicIndex == index && (state.isPlayingMusic ?? false);

    state = state.copyWith(
      selectedMusicIndex: index,
      isPlayingMusic: !isCurrentlyPlaying,
      vibeSelectionModel: state.vibeSelectionModel?.copyWith(
        selectedMusicIndex: index,
        isPlaying: !isCurrentlyPlaying,
      ),
    );
  }

  void completeVibeSelection() {
    // Logic for completing vibe selection
    // This could involve saving the selection or triggering navigation
    state = state.copyWith(
      isSelectionComplete: true,
    );
  }
}
