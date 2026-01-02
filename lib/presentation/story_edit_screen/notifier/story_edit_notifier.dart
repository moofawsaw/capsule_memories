import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../models/story_edit_model.dart';

final storyEditProvider =
    StateNotifierProvider.autoDispose<StoryEditNotifier, StoryEditState>(
  (ref) => StoryEditNotifier(),
);

class StoryEditNotifier extends StateNotifier<StoryEditState> {
  StoryEditNotifier() : super(const StoryEditState());

  final _supabase = SupabaseService.instance.client;

  /// Initialize screen with video path
  void initializeScreen(String videoPath) {
    state = state.copyWith(isLoading: false);
  }

  /// Update caption text
  void updateCaption(String caption) {
    state = state.copyWith(caption: caption);
  }

  /// Add text overlay
  void addTextOverlay(TextOverlay overlay) {
    final updatedOverlays = [...state.textOverlays, overlay];
    state = state.copyWith(textOverlays: updatedOverlays);
  }

  /// Add sticker
  void addSticker(String stickerUrl) {
    final updatedStickers = [...state.stickers, stickerUrl];
    state = state.copyWith(stickers: updatedStickers);
  }

  /// Add drawing
  void addDrawing(Drawing drawing) {
    final updatedDrawings = [...state.drawings, drawing];
    state = state.copyWith(drawings: updatedDrawings);
  }

  /// Set background music
  void setBackgroundMusic(String musicUrl) {
    state = state.copyWith(backgroundMusic: musicUrl);
  }

  /// Upload story and share to memory
  Future<bool> uploadAndShareStory({
    required String memoryId,
    required String videoPath,
    required String caption,
  }) async {
    try {
      state = state.copyWith(isUploading: true, errorMessage: null);

      final userId = _supabase?.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // TODO: Upload video/image file to Supabase storage
      // For now, using placeholder video_url
      final videoUrl = 'https://example.com/video.mp4';
      final thumbnailUrl = 'https://example.com/thumbnail.jpg';

      // Prepare story data
      final storyData = {
        'memory_id': memoryId,
        'contributor_id': userId,
        'media_type': 'video',
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'capture_timestamp': DateTime.now().toIso8601String(),
        'duration_seconds': 30, // TODO: Calculate actual video duration
        'is_from_camera_roll': false,
        'text_overlays': state.textOverlays.map((t) => t.toJson()).toList(),
        'stickers': state.stickers,
        'drawings': state.drawings.map((d) => d.toJson()).toList(),
        if (state.backgroundMusic != null)
          'background_music': {
            'url': state.backgroundMusic,
            'title': 'Selected Music',
          },
      };

      // Insert story into database
      final response =
          await _supabase?.from('stories').insert(storyData).select();

      if (response == null || response.isEmpty) {
        throw Exception('Failed to create story');
      }

      print('✅ Story uploaded successfully: ${response.first['id']}');
      state = state.copyWith(isUploading: false);
      return true;
    } catch (e) {
      print('❌ Error uploading story: $e');
      state = state.copyWith(
        isUploading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

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
  });

  final bool isLoading;
  final bool isUploading;
  final String caption;
  final List<TextOverlay> textOverlays;
  final List<String> stickers;
  final List<Drawing> drawings;
  final String? backgroundMusic;
  final String? errorMessage;

  StoryEditState copyWith({
    bool? isLoading,
    bool? isUploading,
    String? caption,
    List<TextOverlay>? textOverlays,
    List<String>? stickers,
    List<Drawing>? drawings,
    String? backgroundMusic,
    String? errorMessage,
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
    );
  }
}
