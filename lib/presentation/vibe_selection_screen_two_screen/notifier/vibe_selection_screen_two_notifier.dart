import '../../../core/app_export.dart';
import '../models/vibe_selection_screen_two_model.dart';

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

  onTapArrowleft(BuildContext context) {
    NavigatorService.goBack();
  }

  void selectCategory(String categoryName) {
    state = state.copyWith(selectedCategory: categoryName);
  }

  void onContinuePressed() {
    // Navigate to next screen or handle category selection
    // You can add navigation logic here
  }
}
