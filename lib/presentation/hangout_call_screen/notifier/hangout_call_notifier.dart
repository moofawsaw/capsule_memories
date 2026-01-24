import '../../../core/app_export.dart';
import '../models/hangout_call_model.dart';

part 'hangout_call_state.dart';

final hangoutCallNotifier =
    StateNotifierProvider.autoDispose<HangoutCallNotifier, HangoutCallState>(
  (ref) => HangoutCallNotifier(
    HangoutCallState(
      hangoutCallModel: HangoutCallModel(),
    ),
  ),
);

class HangoutCallNotifier extends StateNotifier<HangoutCallState> {
  HangoutCallNotifier(HangoutCallState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      hangoutCallModel: HangoutCallModel(
        participants: const <String>[],
        additionalParticipants: 0,
        isSpeakerOn: true,
        isCallActive: true,
      ),
      isLoading: false,
    );
  }

  void exitCall() {
    state = state.copyWith(
      shouldExitCall: true,
      hangoutCallModel: state.hangoutCallModel?.copyWith(
        isCallActive: false,
      ),
    );
  }

  void toggleSpeaker() {
    final currentModel = state.hangoutCallModel;
    if (currentModel != null) {
      state = state.copyWith(
        hangoutCallModel: currentModel.copyWith(
          isSpeakerOn: !(currentModel.isSpeakerOn ?? true),
        ),
      );
    }
  }

  void openMenu() {
    // Handle menu options - could show bottom sheet with call options
    state = state.copyWith(
      showMenu: true,
    );
  }
}
