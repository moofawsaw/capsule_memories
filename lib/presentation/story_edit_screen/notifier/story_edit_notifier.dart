import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';

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
  final _uuid = const Uuid();

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

  /// Get video duration in seconds
  Future<int> _getVideoDuration(String videoPath) async {
    try {
      print('⏱️ Getting video duration...');
      final mediaFile = File(videoPath);
      final videoController = VideoPlayerController.file(mediaFile);
      await videoController.initialize();
      final durationSeconds = videoController.value.duration.inSeconds;
      videoController.dispose();
      print('✅ Video duration: $durationSeconds seconds');
      return durationSeconds > 0 ? durationSeconds : 10;
    } catch (e) {
      print('⚠️ Failed to get video duration: $e - using default 10s');
      return 10;
    }
  }

  /// Upload media file to Supabase Storage
  Future<String> _uploadMedia({
    required String storyId,
    required String mediaPath,
    required bool isVideo,
  }) async {
    final mediaFile = File(mediaPath);
    final mediaBytes = await mediaFile.readAsBytes();

    if (isVideo) {
      final videoFileName = '$storyId.mp4';
      final videoRelativePath = 'videos/$videoFileName';

      print('🎥 Uploading video to: $videoRelativePath');
      await _supabase.storage
          .from('story-media')
          .uploadBinary(videoRelativePath, mediaBytes);
      print('✅ Video uploaded successfully');

      return videoRelativePath;
    } else {
      final imageFileName = '$storyId.jpg';
      final imageRelativePath = 'images/$imageFileName';

      print('🖼️ Uploading image to: $imageRelativePath');
      await _supabase.storage
          .from('story-media')
          .uploadBinary(imageRelativePath, mediaBytes);
      print('✅ Image uploaded successfully');

      return imageRelativePath;
    }
  }

  /// Upload thumbnail (for videos, create placeholder; for images, reuse image path)
  Future<String> _uploadThumbnail({
    required String storyId,
    required String mediaPath,
    required bool isVideo,
  }) async {
    if (isVideo) {
      // For videos, we create a thumbnail path
      // In production, you'd extract a frame and upload it
      // For now, return the expected path - backend/edge function can handle generation
      final thumbnailRelativePath = 'thumbnails/$storyId.jpg';
      print('🖼️ Thumbnail path reserved: $thumbnailRelativePath');
      return thumbnailRelativePath;
    } else {
      // For images, thumbnail is the same as the image
      final imageRelativePath = 'images/$storyId.jpg';
      return imageRelativePath;
    }
  }

  /// Cleanup uploaded files on failure
  Future<void> _cleanupUploadedFiles({
    String? videoPath,
    String? imagePath,
    String? thumbnailPath,
  }) async {
    try {
      final pathsToDelete = <String>[];
      if (videoPath != null) pathsToDelete.add(videoPath);
      if (imagePath != null) pathsToDelete.add(imagePath);
      if (thumbnailPath != null && thumbnailPath != imagePath) {
        pathsToDelete.add(thumbnailPath);
      }

      if (pathsToDelete.isNotEmpty) {
        print('🧹 Cleaning up ${pathsToDelete.length} uploaded files...');
        await _supabase.storage.from('story-media').remove(pathsToDelete);
        print('✅ Cleanup completed');
      }
    } catch (e) {
      print('⚠️ Cleanup failed: $e');
    }
  }

  Future<bool> uploadAndShareStory({
    required String memoryId,
    required String mediaPath,
    required bool isVideo,
    required String caption,
  }) async {
    String? uploadedVideoPath;
    String? uploadedImagePath;
    String? uploadedThumbnailPath;

    try {
      state = state.copyWith(isUploading: true, errorMessage: null);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('📤 Starting story upload process...');
      print('Memory ID: $memoryId');
      print('Media Path: $mediaPath');
      print('Is Video: $isVideo');

      // Step 1: Generate story ID upfront
      final storyId = _uuid.v4();
      print('🆔 Generated Story ID: $storyId');

      // Step 2: Get video duration (if video)
      int durationSeconds = 5; // Default for images
      if (isVideo) {
        durationSeconds = await _getVideoDuration(mediaPath);
      }

      // Step 3: Capture location data (non-blocking)
      print('📍 Attempting to capture location...');
      Map<String, dynamic>? locationData;
      try {
        locationData = await LocationService.getLocationData();
        if (locationData != null) {
          print('✅ Location captured: ${locationData['location_name']}');
        } else {
          print('⚠️ Location capture skipped (permission denied or unavailable)');
        }
      } catch (e) {
        print('⚠️ Location capture failed: $e - continuing without location');
      }

      // Step 4: Upload media files FIRST (before database insert)
      print('📤 Uploading media files...');

      String? videoUrl;
      String? imageUrl;
      String thumbnailUrl;

      if (isVideo) {
        uploadedVideoPath = await _uploadMedia(
          storyId: storyId,
          mediaPath: mediaPath,
          isVideo: true,
        );
        videoUrl = uploadedVideoPath;

        uploadedThumbnailPath = await _uploadThumbnail(
          storyId: storyId,
          mediaPath: mediaPath,
          isVideo: true,
        );
        thumbnailUrl = uploadedThumbnailPath;
      } else {
        uploadedImagePath = await _uploadMedia(
          storyId: storyId,
          mediaPath: mediaPath,
          isVideo: false,
        );
        imageUrl = uploadedImagePath;

        // For images, thumbnail is the same path
        thumbnailUrl = uploadedImagePath;
        uploadedThumbnailPath = thumbnailUrl;
      }

      print('✅ All media files uploaded successfully');

      // Step 5: Build story data with ALL required fields
      final storyData = <String, dynamic>{
        'id': storyId,
        'memory_id': memoryId,
        'contributor_id': userId,
        'media_type': isVideo ? 'video' : 'image',
        'duration_seconds': durationSeconds,
        'capture_timestamp': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'thumbnail_url': thumbnailUrl,
      };

      // Add media URL based on type
      if (isVideo) {
        storyData['video_url'] = videoUrl;
      } else {
        storyData['image_url'] = imageUrl;
      }

      // Add location data if available
      if (locationData != null) {
        storyData['location_lat'] = locationData['latitude'];
        storyData['location_lng'] = locationData['longitude'];
        storyData['location_name'] = locationData['location_name'];
      }

      // Add caption as text overlay if provided
      if (caption.isNotEmpty) {
        storyData['text_overlays'] = [
          {'text': caption, 'position': 'bottom'}
        ];
      }

      // Step 6: Insert story record (single operation with all data)
      print('📝 Inserting story record with all data...');
      print('Story data: $storyData');

      await _supabase.from('stories').insert(storyData);

      print('✅ Story created and shared successfully!');

      state = state.copyWith(isUploading: false);
      return true;
    } catch (e, stackTrace) {
      print('❌ Error uploading story: $e');
      print('Stack trace: $stackTrace');

      // Cleanup any uploaded files on failure
      await _cleanupUploadedFiles(
        videoPath: uploadedVideoPath,
        imagePath: uploadedImagePath,
        thumbnailPath: uploadedThumbnailPath,
      );

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
