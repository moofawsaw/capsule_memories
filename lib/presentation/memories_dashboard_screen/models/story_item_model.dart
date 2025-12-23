import '../../../core/app_export.dart';

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
      ];
}
