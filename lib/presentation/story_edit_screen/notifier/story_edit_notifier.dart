import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../services/supabase_service.dart';
import '../../../services/story_service.dart';
import '../models/story_edit_model.dart';

final storyEditProvider =
    StateNotifierProvider.autoDispose<StoryEditNotifier, StoryEditState>(
  (ref) => StoryEditNotifier(),
);

class StoryEditNotifier extends StateNotifier<StoryEditState> {
  StoryEditNotifier() : super(const StoryEditState());

  final _supabase = SupabaseService.instance.client!;
  final _uuid = const Uuid();
  final _storyService = StoryService();

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

  /// Generate thumbnail from video using video_thumbnail package
  Future<File?> _generateVideoThumbnail(String videoPath) async {
    try {
      print('🎬 Generating thumbnail for video: $videoPath');

      // Get temporary directory for storing thumbnail
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath =
          '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Generate thumbnail at 1 second mark (or first frame if video is shorter)
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400, // Reasonable size for thumbnails
        quality: 75, // Good balance of quality vs size
        timeMs: 1000, // 1 second into video
      );

      if (thumbnail != null) {
        print('✅ Thumbnail generated successfully: $thumbnail');
        return File(thumbnail);
      } else {
        print('⚠️ Thumbnail generation returned null');
        return null;
      }
    } catch (e) {
      print('⚠️ Failed to generate thumbnail: $e');
      return null;
    }
  }

  /// Get video duration in seconds
  Future<int> _getVideoDuration(String videoPath) async {
    try {
      final videoController = VideoPlayerController.file(File(videoPath));
      await videoController.initialize();
      final duration = videoController.value.duration.inSeconds;
      videoController.dispose();
      return duration > 0 ? duration : 10;
    } catch (e) {
      print('⚠️ Failed to get video duration: $e');
      return 10; // Default duration
    }
  }

  /// Upload media file to Supabase Storage
  Future<String> _uploadMedia({
    required String storyId,
    required Uint8List mediaBytes,
    required bool isVideo,
  }) async {
    final extension = isVideo ? 'mp4' : 'jpg';
    final folder = isVideo ? 'videos' : 'images';
    final relativePath = '$folder/$storyId.$extension';

    print('📤 Uploading ${isVideo ? 'video' : 'image'} to: $relativePath');

    await _supabase.storage
        .from('story-media')
        .uploadBinary(relativePath, mediaBytes);

    print('✅ ${isVideo ? 'Video' : 'Image'} uploaded successfully');
    return relativePath;
  }

  /// Upload thumbnail to Supabase Storage
  Future<String?> _uploadThumbnail({
    required String storyId,
    required File thumbnailFile,
  }) async {
    try {
      final thumbnailBytes = await thumbnailFile.readAsBytes();
      final relativePath = 'thumbnails/$storyId.jpg';

      print('📤 Uploading thumbnail to: $relativePath');

      await _supabase.storage
          .from('story-media')
          .uploadBinary(relativePath, thumbnailBytes);

      print('✅ Thumbnail uploaded successfully');
      return relativePath;
    } catch (e) {
      print('⚠️ Failed to upload thumbnail: $e');
      return null;
    }
  }

  /// Cleanup uploaded files on failure
  Future<void> _cleanupUploadedFiles(List<String> paths) async {
    for (final path in paths) {
      try {
        await _supabase.storage.from('story-media').remove([path]);
        print('🧹 Cleaned up: $path');
      } catch (e) {
        print('⚠️ Failed to cleanup $path: $e');
      }
    }
  }

  /// CRITICAL FIX: Refactored to use StoryService.createStory() for proper location handling
  /// This ensures coordinates and location_name are fetched and stored like memory creation
  Future<bool> uploadAndShareStory({
    required String memoryId,
    required String mediaPath,
    required bool isVideo,
    required String caption,
  }) async {
    final uploadedPaths = <String>[];

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

      // Generate story ID upfront
      final storyId = _uuid.v4();
      print('🆔 Generated Story ID: $storyId');

      // Read media file
      final mediaFile = File(mediaPath);
      final mediaBytes = await mediaFile.readAsBytes();

      // Variables for media paths
      String? videoRelativePath;
      String? imageRelativePath;
      String? thumbnailRelativePath;
      int durationSeconds = 5; // Default for images

      if (isVideo) {
        // Step 1: Get video duration
        print('⏱️ Getting video duration...');
        durationSeconds = await _getVideoDuration(mediaPath);
        print('✅ Video duration: $durationSeconds seconds');

        // Step 2: Generate thumbnail BEFORE uploading
        print('🖼️ Generating video thumbnail...');
        final thumbnailFile = await _generateVideoThumbnail(mediaPath);

        // Step 3: Upload video
        videoRelativePath = await _uploadMedia(
          storyId: storyId,
          mediaBytes: mediaBytes,
          isVideo: true,
        );
        uploadedPaths.add(videoRelativePath);

        // Step 4: Upload thumbnail if generated successfully
        if (thumbnailFile != null && await thumbnailFile.exists()) {
          thumbnailRelativePath = await _uploadThumbnail(
            storyId: storyId,
            thumbnailFile: thumbnailFile,
          );
          if (thumbnailRelativePath != null) {
            uploadedPaths.add(thumbnailRelativePath);
          }

          // Clean up local thumbnail file
          try {
            await thumbnailFile.delete();
          } catch (_) {}
        } else {
          print('⚠️ No thumbnail generated - story will have no preview image');
        }
      } else {
        // For images: upload image file
        imageRelativePath = await _uploadMedia(
          storyId: storyId,
          mediaBytes: mediaBytes,
          isVideo: false,
        );
        uploadedPaths.add(imageRelativePath);

        // For images, use same path for thumbnail
        thumbnailRelativePath = imageRelativePath;
      }

      // CRITICAL FIX: Use StoryService.createStory() instead of direct database insertion
      // This ensures proper location fetching and geocoding matching memory creation pattern
      print(
          '📍 Creating story with StoryService (includes location fetching)...');

      final mediaUrl = isVideo ? videoRelativePath! : imageRelativePath!;
      final storyData = await _storyService.createStory(
        memoryId: memoryId,
        contributorId: userId,
        mediaUrl: mediaUrl,
        mediaType: isVideo ? 'video' : 'image',
        thumbnailUrl: thumbnailRelativePath,
        caption: caption.isNotEmpty ? caption : null,
        durationSeconds: durationSeconds,
      );

      if (storyData == null) {
        throw Exception('Failed to create story via StoryService');
      }

      final locationName = storyData['location_name'] as String?;
      print('✅ Story created successfully via StoryService');
      print('   - Story ID: ${storyData['id']}');
      print('   - Location: ${locationName ?? "Location unavailable"}');
      print('   - Coordinates fetched: ${locationName != null ? "YES" : "NO"}');

      state = state.copyWith(isUploading: false);
      return true;
    } catch (e, stackTrace) {
      print('❌ Error uploading story: $e');
      print('Stack trace: $stackTrace');

      // Cleanup any uploaded files on failure
      if (uploadedPaths.isNotEmpty) {
        print('🧹 Cleaning up uploaded files...');
        await _cleanupUploadedFiles(uploadedPaths);
      }

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
