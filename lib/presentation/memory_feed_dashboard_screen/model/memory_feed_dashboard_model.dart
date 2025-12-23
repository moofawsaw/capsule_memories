import 'package:equatable/equatable.dart';

/// Model for Memory Feed Dashboard screen data
class MemoryFeedDashboardModel extends Equatable {
  final List<HappeningNowStoryData>? happeningNowStories;
  final List<CustomMemoryItem>? publicMemories;
  final List<HappeningNowStoryData>? trendingStories;

  MemoryFeedDashboardModel({
    this.happeningNowStories,
    this.publicMemories,
    this.trendingStories,
  });

  MemoryFeedDashboardModel copyWith({
    List<HappeningNowStoryData>? happeningNowStories,
    List<CustomMemoryItem>? publicMemories,
    List<HappeningNowStoryData>? trendingStories,
  }) {
    return MemoryFeedDashboardModel(
      happeningNowStories: happeningNowStories ?? this.happeningNowStories,
      publicMemories: publicMemories ?? this.publicMemories,
      trendingStories: trendingStories ?? this.trendingStories,
    );
  }

  @override
  List<Object?> get props =>
      [happeningNowStories, publicMemories, trendingStories];
}

/// Data model for happening now stories and trending stories
class HappeningNowStoryData extends Equatable {
  final String id;
  final String backgroundImage;
  final String profileImage;
  final String userName;
  final String categoryName;
  final String categoryIcon;
  final String timestamp;
  final bool isViewed;

  HappeningNowStoryData({
    required this.id,
    required this.backgroundImage,
    required this.profileImage,
    required this.userName,
    required this.categoryName,
    required this.categoryIcon,
    required this.timestamp,
    this.isViewed = false,
  });

  HappeningNowStoryData copyWith({
    String? id,
    String? backgroundImage,
    String? profileImage,
    String? userName,
    String? categoryName,
    String? categoryIcon,
    String? timestamp,
    bool? isViewed,
  }) {
    return HappeningNowStoryData(
      id: id ?? this.id,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      profileImage: profileImage ?? this.profileImage,
      userName: userName ?? this.userName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      timestamp: timestamp ?? this.timestamp,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  @override
  List<Object?> get props => [
        id,
        backgroundImage,
        profileImage,
        userName,
        categoryName,
        categoryIcon,
        timestamp,
        isViewed
      ];
}

/// Data model for public memory items
class CustomMemoryItem extends Equatable {
  final String? id;
  final String? title;
  final String? date;
  final String? iconPath;
  final List<String>? profileImages;
  final List<CustomMediaItem>? mediaItems;
  final String? startDate;
  final String? startTime;
  final String? endDate;
  final String? endTime;
  final String? location;
  final String? distance;
  final bool? isLiked;

  CustomMemoryItem({
    this.id,
    this.title,
    this.date,
    this.iconPath,
    this.profileImages,
    this.mediaItems,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.location,
    this.distance,
    this.isLiked,
  });

  CustomMemoryItem copyWith({
    String? id,
    String? title,
    String? date,
    String? iconPath,
    List<String>? profileImages,
    List<CustomMediaItem>? mediaItems,
    String? startDate,
    String? startTime,
    String? endDate,
    String? endTime,
    String? location,
    String? distance,
    bool? isLiked,
  }) {
    return CustomMemoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      iconPath: iconPath ?? this.iconPath,
      profileImages: profileImages ?? this.profileImages,
      mediaItems: mediaItems ?? this.mediaItems,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        date,
        iconPath,
        profileImages,
        mediaItems,
        startDate,
        startTime,
        endDate,
        endTime,
        location,
        distance,
        isLiked,
      ];
}

/// Data model for media items in memory timeline
class CustomMediaItem extends Equatable {
  final String? imagePath;
  final bool? hasPlayButton;

  CustomMediaItem({
    this.imagePath,
    this.hasPlayButton = false,
  });

  CustomMediaItem copyWith({
    String? imagePath,
    bool? hasPlayButton,
  }) {
    return CustomMediaItem(
      imagePath: imagePath ?? this.imagePath,
      hasPlayButton: hasPlayButton ?? this.hasPlayButton,
    );
  }

  @override
  List<Object?> get props => [imagePath, hasPlayButton];
}
