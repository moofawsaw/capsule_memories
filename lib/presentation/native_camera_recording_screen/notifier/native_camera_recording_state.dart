class NativeCameraRecordingState {
  final dynamic nativeCameraRecordingModel;
  final bool isRecording;
  final bool isInitializing;
  final String? recordedVideoPath;
  final String? errorMessage;
  final int? recordingDuration;

  const NativeCameraRecordingState({
    this.nativeCameraRecordingModel,
    this.isRecording = false,
    this.isInitializing = false,
    this.recordedVideoPath,
    this.errorMessage,
    this.recordingDuration,
  });

  factory NativeCameraRecordingState.initial() =>
      const NativeCameraRecordingState();
}