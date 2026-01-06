import 'package:flutter_riverpod/flutter_riverpod.dart';

import './native_camera_recording_state.dart';

final nativeCameraRecordingProvider = StateNotifierProvider<
    NativeCameraRecordingNotifier, NativeCameraRecordingState>(
  (ref) => NativeCameraRecordingNotifier(),
);

class NativeCameraRecordingNotifier
    extends StateNotifier<NativeCameraRecordingState> {
  NativeCameraRecordingNotifier() : super(NativeCameraRecordingState.initial());

  void setRecording(bool isRecording) {
    state = state.copyWith(
      isRecording: isRecording,
    );
  }

  void setInitializing(bool isInitializing) {
    state = state.copyWith(
      isInitializing: isInitializing,
    );
  }

  void setRecordedVideoPath(String? path) {
    state = state.copyWith(
      recordedVideoPath: path,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      errorMessage: error,
    );
  }

  void updateRecordingDuration(int seconds) {
    state = state.copyWith(
      recordingDuration: seconds,
    );
  }

  void reset() {
    state = NativeCameraRecordingState.initial();
  }
}