import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/story_edit_model.dart';

part 'story_edit_state.freezed.dart';

@freezed
class StoryEditState with _$StoryEditState {
  const factory StoryEditState({
    @Default(false) bool isLoading,
    @Default(false) bool isUploading,
    @Default('') String caption,
    @Default([]) List<TextOverlay> textOverlays,
    @Default([]) List<String> stickers,
    @Default([]) List<Drawing> drawings,
    String? backgroundMusic,
    String? errorMessage,
  }) = _StoryEditState;
}
