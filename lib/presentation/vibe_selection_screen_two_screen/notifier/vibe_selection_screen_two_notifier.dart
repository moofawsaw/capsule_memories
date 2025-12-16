import '../models/vibe_selection_screen_two_model.dart';
import '../../../core/app_export.dart';

part 'vibe_selection_screen_two_state.dart';

final vibeSelectionScreenTwoNotifier = StateNotifierProvider.autoDispose<
    VibeSelectionScreenTwoNotifier, VibeSelectionScreenTwoState>(
  (ref) => VibeSelectionScreenTwoNotifier(
    VibeSelectionScreenTwoState(),
  ),
);

class VibeSelectionScreenTwoNotifier
    extends StateNotifier<VibeSelectionScreenTwoState> {
  VibeSelectionScreenTwoNotifier(VibeSelectionScreenTwoState state)
      : super(state);

  void initializeVibes() {
    final vibes = [
      // Top row
      VibeItem(
        id: 'fun',
        label: 'Fun',
        image: '😎',
        isEmoji: true,
        backgroundColor: appTheme.deep_purple_A100,
        textColor: appTheme.white_A700,
      ),
      VibeItem(
        id: 'crazy',
        label: 'Crazy',
        image: '🤪',
        isEmoji: true,
        backgroundColor: appTheme.colorFF2A2A,
        textColor: appTheme.white_A700,
      ),
      VibeItem(
        id: 'sexy',
        label: 'Sexy',
        image: '😍',
        isEmoji: true,
        backgroundColor: appTheme.colorFF2A2A,
        textColor: appTheme.white_A700,
      ),
      // Middle row
      VibeItem(
        id: 'cute',
        label: 'Cute',
        image: '😘',
        isEmoji: true,
        backgroundColor: appTheme.colorFF2A2A,
        textColor: appTheme.white_A700,
      ),
      VibeItem(
        id: 'pug',
        label: '',
        image: ImageConstant.imgPugDog,
        isEmoji: false,
        backgroundColor: appTheme.colorFF2A2A,
        textColor: appTheme.white_A700,
      ),
      VibeItem(
        id: 'doge',
        label: '',
        image: ImageConstant.imgDogeMeme,
        isEmoji: false,
        backgroundColor: appTheme.colorFF2A2A,
        textColor: appTheme.white_A700,
      ),
      // Bottom row
      VibeItem(
        id: 'cat',
        label: '',
        image: ImageConstant.imgWhiteCat,
        isEmoji: false,
        backgroundColor: appTheme.colorFF2A2A,
        textColor: appTheme.white_A700,
      ),
      VibeItem(
        id: 'lol_bird',
        label: 'LOL',
        image: ImageConstant.imgBirdLol,
        isEmoji: false,
        backgroundColor: appTheme.colorFF2A2A,
        textColor: appTheme.white_A700,
      ),
      VibeItem(
        id: 'lol_emoji',
        label: '😂',
        image: '😂',
        isEmoji: true,
        backgroundColor: appTheme.colorFF2A2A,
        textColor: appTheme.white_A700,
      ),
    ];

    state = state.copyWith(vibes: vibes);
  }

  void selectVibe(int index) {
    if (index >= 0 && index < state.vibes.length) {
      state = state.copyWith(
        selectedVibeIndex: index,
        selectedVibe: state.vibes[index],
      );
    }
  }
}
