import '../../../core/app_export.dart';
import '../../../utils/storage_utils.dart';

/// This class is used for the story item widget.

// ignore_for_file: must_be_immutable
class StoryItemModel extends Equatable {
  StoryItemModel({
    this.storyId,
    this.storyImage,
    this.timeAgo,
    this.mediaType,
    this.videoUrl,
    this.imageUrl,
    this.thumbnailUrl,
  }) {
    storyId = storyId ?? "";
    storyImage = storyImage ?? "";
    timeAgo = timeAgo ?? "";
    mediaType = mediaType ?? "image";
    videoUrl = videoUrl ?? "";
    imageUrl = imageUrl ?? "";
    thumbnailUrl = thumbnailUrl ?? "";
  }

  String? storyId;
  String? storyImage;
  String? timeAgo;
  String? mediaType;
  String? videoUrl;
  String? imageUrl;
  String? thumbnailUrl;

  /// Computed getter for resolved thumbnail URL
  /// Returns full Supabase Storage URL for thumbnails
  String? get resolvedThumbnailUrl =>
      StorageUtils.resolveStoryMediaUrl(thumbnailUrl);

  /// Computed getter for resolved media URL
  /// Returns resolved videoUrl if mediaType is 'video', otherwise returns resolved imageUrl or thumbnailUrl
  String? get resolvedMediaUrl => mediaType == 'video'
      ? StorageUtils.resolveStoryMediaUrl(videoUrl)
      : StorageUtils.resolveStoryMediaUrl(imageUrl ?? thumbnailUrl);

  StoryItemModel copyWith({
    String? storyId,
    String? storyImage,
    String? timeAgo,
    String? mediaType,
    String? videoUrl,
    String? imageUrl,
    String? thumbnailUrl,
  }) {
    return StoryItemModel(
      storyId: storyId ?? this.storyId,
      storyImage: storyImage ?? this.storyImage,
      timeAgo: timeAgo ?? this.timeAgo,
      mediaType: mediaType ?? this.mediaType,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  List<Object?> get props => [
        storyId,
        storyImage,
        timeAgo,
        mediaType,
        videoUrl,
        imageUrl,
        thumbnailUrl,
      ];
}
