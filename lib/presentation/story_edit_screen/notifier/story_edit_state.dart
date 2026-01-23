import '../models/story_edit_model.dart';
import 'preupload_state.dart';

class StoryEditState {
  const StoryEditState({
    this.isLoading = false,
    this.isUploading = false,
    this.caption = '',
    this.textOverlays = const [],
    this.stickers = const [],
    this.drawings = const [],
    this.backgroundMusic,
    this.errorMessage,

    // upload UI
    this.uploadStage,
    this.mediaProgress = 0.0,
    this.thumbProgress = 0.0,

    // preupload
    this.preuploadState = PreuploadState.idle,
    this.preuploadError,
    this.preuploadedMediaObjectName,
    this.preuploadedThumbObjectName,
    this.preuploadIsVideo = false,
  });

  final bool isLoading;
  final bool isUploading;
  final String caption;
  final List<TextOverlay> textOverlays;
  final List<String> stickers;
  final List<Drawing> drawings;
  final String? backgroundMusic;
  final String? errorMessage;

  final String? uploadStage;
  final double mediaProgress; // 0..1
  final double thumbProgress; // 0..1

  // Preupload
  final PreuploadState preuploadState;
  final String? preuploadError;
  final String? preuploadedMediaObjectName; // e.g. videos/<id>.mp4
  final String? preuploadedThumbObjectName; // e.g. thumbnails/<id>.jpg
  final bool preuploadIsVideo;

  StoryEditState copyWith({
    bool? isLoading,
    bool? isUploading,
    String? caption,
    List<TextOverlay>? textOverlays,
    List<String>? stickers,
    List<Drawing>? drawings,
    String? backgroundMusic,
    String? errorMessage,
    String? uploadStage,
    double? mediaProgress,
    double? thumbProgress,

    PreuploadState? preuploadState,
    String? preuploadError,
    String? preuploadedMediaObjectName,
    String? preuploadedThumbObjectName,
    bool? preuploadIsVideo,
  }) {
    return StoryEditState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      caption: caption ?? this.caption,
      textOverlays: textOverlays ?? this.textOverlays,
      stickers: stickers ?? this.stickers,
      drawings: drawings ?? this.drawings,
      backgroundMusic: backgroundMusic ?? this.backgroundMusic,
      errorMessage: errorMessage ?? this.errorMessage,

      uploadStage: uploadStage,
      mediaProgress: mediaProgress ?? this.mediaProgress,
      thumbProgress: thumbProgress ?? this.thumbProgress,

      preuploadState: preuploadState ?? this.preuploadState,
      preuploadError: preuploadError ?? this.preuploadError,
      preuploadedMediaObjectName:
      preuploadedMediaObjectName ?? this.preuploadedMediaObjectName,
      preuploadedThumbObjectName:
      preuploadedThumbObjectName ?? this.preuploadedThumbObjectName,
      preuploadIsVideo: preuploadIsVideo ?? this.preuploadIsVideo,
    );
  }
}