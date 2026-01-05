import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

/// This class is used for story items in the [memories_dashboard_screen] screen.

// ignore_for_file: must_be_immutable
class StoryItemModel extends Equatable {
  StoryItemModel({
    this.id,
    this.backgroundImage,
    this.profileImage,
    this.timestamp,
    this.navigateTo,
    this.memoryId,
    this.contributorId,
    this.mediaType,
    this.videoUrl,
    this.imageUrl,
    this.contributorName,
    this.thumbnailUrl,
    this.isRead,
  }) {
    id = id ?? "";
    backgroundImage = backgroundImage ?? "";
    profileImage = profileImage ?? "";
    timestamp = timestamp ?? "2 mins ago";
    navigateTo = navigateTo ?? "";
    memoryId = memoryId ?? "";
    contributorId = contributorId ?? "";
    mediaType = mediaType ?? "video";
    videoUrl = videoUrl ?? "";
    imageUrl = imageUrl ?? "";
    contributorName = contributorName ?? "";
    thumbnailUrl = thumbnailUrl ?? "";
    isRead = isRead ?? false;
  }

  String? id;
  String? backgroundImage;
  String? profileImage;
  String? timestamp;
  String? navigateTo;
  String? memoryId;
  String? contributorId;
  String? mediaType;
  String? videoUrl;
  String? imageUrl;
  String? contributorName;
  String? thumbnailUrl;
  bool? isRead;

  /// Computed getter for resolved thumbnail URL
  /// Returns full Supabase Storage URL for thumbnails
  String get resolvedThumbnailUrl {
    final supabaseService = SupabaseService.instance;

    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      // Check if already a full URL
      if (thumbnailUrl!.startsWith('http://') ||
          thumbnailUrl!.startsWith('https://')) {
        return thumbnailUrl!;
      }

      // Resolve relative path to full Supabase Storage URL
      return supabaseService.getStorageUrl(thumbnailUrl!) ?? thumbnailUrl!;
    }

    return '';
  }

  /// Computed getter for resolved media URL
  /// Returns resolved videoUrl if mediaType is 'video', otherwise returns resolved imageUrl or thumbnailUrl
  String get resolvedMediaUrl {
    final supabaseService = SupabaseService.instance;

    if (mediaType == 'video' && videoUrl != null && videoUrl!.isNotEmpty) {
      // Check if already a full URL
      if (videoUrl!.startsWith('http://') || videoUrl!.startsWith('https://')) {
        return videoUrl!;
      }

      // Resolve relative path to full Supabase Storage URL
      return supabaseService.getStorageUrl(videoUrl!) ?? videoUrl!;
    } else {
      // For images, prioritize imageUrl, fallback to thumbnailUrl
      final path = imageUrl ?? thumbnailUrl;

      if (path != null && path.isNotEmpty) {
        // Check if already a full URL
        if (path.startsWith('http://') || path.startsWith('https://')) {
          return path;
        }

        // Resolve relative path to full Supabase Storage URL
        return supabaseService.getStorageUrl(path) ?? path;
      }
    }

    return '';
  }

  StoryItemModel copyWith({
    String? id,
    String? backgroundImage,
    String? profileImage,
    String? timestamp,
    String? navigateTo,
    String? memoryId,
    String? contributorId,
    String? mediaType,
    String? videoUrl,
    String? imageUrl,
    String? contributorName,
    String? thumbnailUrl,
    bool? isRead,
  }) {
    return StoryItemModel(
      id: id ?? this.id,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      profileImage: profileImage ?? this.profileImage,
      timestamp: timestamp ?? this.timestamp,
      navigateTo: navigateTo ?? this.navigateTo,
      memoryId: memoryId ?? this.memoryId,
      contributorId: contributorId ?? this.contributorId,
      mediaType: mediaType ?? this.mediaType,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      contributorName: contributorName ?? this.contributorName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
        id,
        backgroundImage,
        profileImage,
        timestamp,
        navigateTo,
        memoryId,
        contributorId,
        mediaType,
        videoUrl,
        imageUrl,
        contributorName,
        thumbnailUrl,
        isRead,
      ];
}
