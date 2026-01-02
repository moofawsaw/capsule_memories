import 'package:freezed_annotation/freezed_annotation.dart';

part 'native_camera_recording_state.freezed.dart';

@freezed
class NativeCameraRecordingState with _$NativeCameraRecordingState {
  const factory NativeCameraRecordingState({
    NativeCameraRecordingModel? nativeCameraRecordingModel,
    @Default(false) bool isRecording,
    @Default(false) bool isInitializing,
    String? recordedVideoPath,
    String? errorMessage,
    int? recordingDuration,
  }) = _NativeCameraRecordingState;

  factory NativeCameraRecordingState.initial() =>
      const NativeCameraRecordingState();
}