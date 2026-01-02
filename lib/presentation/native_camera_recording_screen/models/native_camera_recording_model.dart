import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
class NativeCameraRecordingModel with _$NativeCameraRecordingModel {
  const factory NativeCameraRecordingModel({
    @Default(false) bool isRecording,
    @Default(false) bool isInitializing,
    String? recordedVideoPath,
    String? errorMessage,
    int? recordingDuration,
  }) = _NativeCameraRecordingModel;
}