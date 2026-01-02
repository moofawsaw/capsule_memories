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
    state = NativeCameraRecordingState(
      isRecording: isRecording,
      isInitializing: state.isInitializing,
      recordedVideoPath: state.recordedVideoPath,
      errorMessage: state.errorMessage,
      recordingDuration: state.recordingDuration,
    );
  }

  void setInitializing(bool isInitializing) {
    state = NativeCameraRecordingState(
      isRecording: state.isRecording,
      isInitializing: isInitializing,
      recordedVideoPath: state.recordedVideoPath,
      errorMessage: state.errorMessage,
      recordingDuration: state.recordingDuration,
    );
  }

  void setRecordedVideoPath(String? path) {
    state = NativeCameraRecordingState(
      isRecording: state.isRecording,
      isInitializing: state.isInitializing,
      recordedVideoPath: path,
      errorMessage: state.errorMessage,
      recordingDuration: state.recordingDuration,
    );
  }

  void setError(String error) {
    state = NativeCameraRecordingState(
      isRecording: state.isRecording,
      isInitializing: state.isInitializing,
      recordedVideoPath: state.recordedVideoPath,
      errorMessage: error,
      recordingDuration: state.recordingDuration,
    );
  }

  void updateRecordingDuration(int seconds) {
    state = NativeCameraRecordingState(
      isRecording: state.isRecording,
      isInitializing: state.isInitializing,
      recordedVideoPath: state.recordedVideoPath,
      errorMessage: state.errorMessage,
      recordingDuration: seconds,
    );
  }

  void reset() {
    state = NativeCameraRecordingState.initial();
  }
}