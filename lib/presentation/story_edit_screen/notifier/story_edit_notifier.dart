import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

import '../../../services/supabase_service.dart';
import '../models/story_edit_model.dart';

final storyEditProvider =
    StateNotifierProvider.autoDispose<StoryEditNotifier, StoryEditState>(
  (ref) => StoryEditNotifier(),
);

class StoryEditNotifier extends StateNotifier<StoryEditState> {
  StoryEditNotifier() : super(const StoryEditState());

  final _supabase = SupabaseService.instance.client!;

  /// Initialize screen with media path
  void initializeScreen(String mediaPath) {
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

  /// Generate thumbnail from video file
  Future<File?> _generateVideoThumbnail(String videoPath) async {
    try {
      final videoController = VideoPlayerController.file(File(videoPath));
      await videoController.initialize();

      // Seek to 1 second or middle of video
      final duration = videoController.value.duration;
      final seekPosition = duration.inMilliseconds > 1000
          ? const Duration(seconds: 1)
          : Duration(milliseconds: duration.inMilliseconds ~/ 2);

      await videoController.seekTo(seekPosition);

      // Note: VideoPlayerController doesn't have direct screenshot capability
      // For production, consider using packages like video_thumbnail or ffmpeg
      // For now, we'll create a simple placeholder approach

      videoController.dispose();
      return null; // Return null to skip thumbnail for now
    } catch (e) {
      print('⚠️ Failed to generate thumbnail: $e');
      return null;
    }
  }

  Future<bool> uploadAndShareStory({
    required String memoryId,
    required String mediaPath,
    required bool isVideo,
    required String caption,
  }) async {
    try {
      state = state.copyWith(isUploading: true);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Determine file extension and MIME type
      final fileExtension = isVideo ? '.mp4' : '.jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Read media file
      final mediaFile = File(mediaPath);
      final mediaBytes = await mediaFile.readAsBytes();

      // Upload media to Supabase Storage
      final mediaFileName = 'story_${userId}_${timestamp}$fileExtension';
      final mediaUploadPath = 'stories/$memoryId/$mediaFileName';

      await _supabase.storage
          .from('story-media')
          .uploadBinary(mediaUploadPath, mediaBytes);

      // Get public URL for media
      final mediaUrl =
          _supabase.storage.from('story-media').getPublicUrl(mediaUploadPath);

      // Generate and upload thumbnail for videos
      String? thumbnailUrl;
      int? durationSeconds;

      if (isVideo) {
        // Get video duration
        final videoController = VideoPlayerController.file(mediaFile);
        await videoController.initialize();
        durationSeconds = videoController.value.duration.inSeconds;
        videoController.dispose();

        // For thumbnail, we'll use a simple approach
        // In production, consider using video_thumbnail or ffmpeg package
        // For now, we'll set thumbnail as null and let UI handle default thumbnail
      }

      // Prepare story data
      final storyData = {
        'memory_id': memoryId,
        'contributor_id': userId,
        'media_type': isVideo ? 'video' : 'image',
        'capture_timestamp': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'duration_seconds': isVideo ? (durationSeconds ?? 10) : 5,
      };

      // Add media URLs based on type
      if (isVideo) {
        storyData['video_url'] = mediaUrl;
      } else {
        storyData['image_url'] = mediaUrl;
      }

      // Add optional fields
      if (caption.isNotEmpty) {
        storyData['text_overlays'] = [
          {'text': caption, 'position': 'bottom'}
        ];
      }

      // Add thumbnail_url only if not null
      if (isVideo && thumbnailUrl != null) {
        storyData['thumbnail_url'] = thumbnailUrl;
      }

      // Insert story into database
      await _supabase.from('stories').insert(storyData);

      state = state.copyWith(isUploading: false);
      return true;
    } catch (e) {
      print('❌ Error uploading story: $e');
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Failed to upload story: ${e.toString()}',
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