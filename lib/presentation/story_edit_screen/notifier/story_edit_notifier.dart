import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

import '../../../services/supabase_service.dart';
import '../../../services/location_service.dart';
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

  /// Generate thumbnail from video using screenshot approach
  Future<File?> _generateVideoThumbnail(String videoPath) async {
    try {
      print('🎬 Starting thumbnail generation for: $videoPath');

      final videoController = VideoPlayerController.file(File(videoPath));
      await videoController.initialize();

      // Seek to 1 second position for thumbnail
      final duration = videoController.value.duration;
      final seekPosition = duration.inMilliseconds > 1000
          ? const Duration(seconds: 1)
          : Duration(milliseconds: duration.inMilliseconds ~/ 2);

      await videoController.seekTo(seekPosition);

      // Wait for frame to load
      await Future.delayed(const Duration(milliseconds: 500));

      // Note: Creating a simple placeholder thumbnail approach
      // For full implementation, consider backend processing or native platform channels
      // This is a simplified version that stores relative path reference

      videoController.dispose();
      return null; // Thumbnail generation deferred to backend/native processing
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

      print('📤 Starting story upload process...');
      print('Memory ID: $memoryId');
      print('Media Path: $mediaPath');
      print('Is Video: $isVideo');

      // Capture location data (non-blocking)
      print('📍 Attempting to capture location...');
      Map<String, dynamic>? locationData;
      try {
        locationData = await LocationService.getLocationData();
        if (locationData != null) {
          print('✅ Location captured: ${locationData['location_name']}');
        } else {
          print(
              '⚠️ Location capture skipped (permission denied or unavailable)');
        }
      } catch (e) {
        print('⚠️ Location capture failed: $e - continuing without location');
      }

      // Get video duration BEFORE inserting (if video)
      int durationSeconds = 5; // Default for images
      if (isVideo) {
        print('⏱️ Getting video duration...');
        try {
          final mediaFile = File(mediaPath);
          final videoController = VideoPlayerController.file(mediaFile);
          await videoController.initialize();
          durationSeconds = videoController.value.duration.inSeconds;
          videoController.dispose();
          print('✅ Video duration: $durationSeconds seconds');
        } catch (e) {
          print('⚠️ Failed to get video duration: $e - using default 10s');
          durationSeconds = 10;
        }
      }

      // Step 1: Insert story record with duration_seconds included
      final storyInsertData = {
        'memory_id': memoryId,
        'contributor_id': userId,
        'media_type': isVideo ? 'video' : 'image',
        'duration_seconds':
            durationSeconds, // ✅ Include duration in initial insert
        'capture_timestamp': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add location data if available
      if (locationData != null) {
        storyInsertData['location_lat'] = locationData['latitude'];
        storyInsertData['location_lng'] = locationData['longitude'];
        storyInsertData['location_name'] = locationData['location_name'];
      }

      print('📝 Inserting story record with duration...');

      final storyResponse = await _supabase
          .from('stories')
          .insert(storyInsertData)
          .select('id')
          .single();

      final storyId = storyResponse['id'] as String;
      print('✅ Story ID created: $storyId');

      // Step 2: Upload media files
      final mediaFile = File(mediaPath);
      final mediaBytes = await mediaFile.readAsBytes();

      String? videoRelativePath;
      String? imageRelativePath;
      String? thumbnailRelativePath;

      if (isVideo) {
        // Upload video file
        final videoFileName = '${storyId}.mp4';
        videoRelativePath = 'videos/$videoFileName';

        print('🎥 Uploading video to: $videoRelativePath');
        await _supabase.storage
            .from('story-media')
            .uploadBinary(videoRelativePath, mediaBytes);
        print('✅ Video uploaded successfully');

        // Generate and upload thumbnail
        print('🖼️ Generating video thumbnail...');
        thumbnailRelativePath = 'thumbnails/${storyId}.jpg';

        // For now, use a placeholder approach - in production this would:
        // 1. Extract frame from video using native processing
        // 2. Resize to 400px width with 75% quality
        // 3. Save as JPEG

        // Simplified: Create a small placeholder reference
        // Backend/Edge function would handle actual thumbnail generation
      } else {
        // Upload image file
        final imageFileName = '${storyId}.jpg';
        imageRelativePath = 'images/$imageFileName';

        print('🖼️ Uploading image to: $imageRelativePath');
        await _supabase.storage
            .from('story-media')
            .uploadBinary(imageRelativePath, mediaBytes);
        print('✅ Image uploaded successfully');

        // For images, use same path for thumbnail
        thumbnailRelativePath = imageRelativePath;
      }

      // Step 3: Update story record with media paths
      final updateData = <String, dynamic>{};

      if (videoRelativePath != null) {
        updateData['video_url'] = videoRelativePath;
      }

      if (imageRelativePath != null) {
        updateData['image_url'] = imageRelativePath;
      }

      updateData['thumbnail_url'] = thumbnailRelativePath;

      // Add caption as text overlay if provided
      if (caption.isNotEmpty) {
        updateData['text_overlays'] = [
          {'text': caption, 'position': 'bottom'}
        ];
      }

      print('📝 Updating story with media paths...');
      print('Update data: $updateData');

      await _supabase.from('stories').update(updateData).eq('id', storyId);

      print('✅ Story updated successfully with media paths');

      state = state.copyWith(isUploading: false);
      return true;
    } catch (e, stackTrace) {
      print('❌ Error uploading story: $e');
      print('Stack trace: $stackTrace');
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
