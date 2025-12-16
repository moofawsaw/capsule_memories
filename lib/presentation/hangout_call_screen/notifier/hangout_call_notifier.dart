import '../models/hangout_call_model.dart';
import '../../../core/app_export.dart';

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
        participants: [
          ImageConstant.imgEllipse81,
          ImageConstant.imgFrame3,
          ImageConstant.imgFrame2,
        ],
        additionalParticipants: 3,
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
