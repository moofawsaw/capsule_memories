import '../../../core/app_export.dart';

/// This class defines the model for the MemoryFeedDashboard screen.
class MemoryFeedDashboardModel extends Equatable {
  final List<HappeningNowStoryData>? happeningNowStories;
  final List<CustomMemoryItem>? publicMemories;
  final List<HappeningNowStoryData>? trendingStories;
  final List<HappeningNowStoryData>? longestStreakStories;
  final List<HappeningNowStoryData>? popularUserStories;
  final List<HappeningNowStoryData>? latestStories;

  MemoryFeedDashboardModel({
    this.happeningNowStories = const [],
    this.publicMemories = const [],
    this.trendingStories = const [],
    this.longestStreakStories = const [],
    this.popularUserStories = const [],
    this.latestStories = const [],
  });

  MemoryFeedDashboardModel copyWith({
    List<HappeningNowStoryData>? happeningNowStories,
    List<CustomMemoryItem>? publicMemories,
    List<HappeningNowStoryData>? trendingStories,
    List<HappeningNowStoryData>? longestStreakStories,
    List<HappeningNowStoryData>? popularUserStories,
    List<HappeningNowStoryData>? latestStories,
  }) {
    return MemoryFeedDashboardModel(
      happeningNowStories: happeningNowStories ?? this.happeningNowStories,
      publicMemories: publicMemories ?? this.publicMemories,
      trendingStories: trendingStories ?? this.trendingStories,
      longestStreakStories: longestStreakStories ?? this.longestStreakStories,
      popularUserStories: popularUserStories ?? this.popularUserStories,
      latestStories: latestStories ?? this.latestStories,
    );
  }

  @override
  List<Object?> get props => [
        happeningNowStories,
        publicMemories,
        trendingStories,
        longestStreakStories,
        popularUserStories,
        latestStories,
      ];
}

/// Data model for happening now stories and trending stories
class HappeningNowStoryData extends Equatable {
  final String storyId;
  final String backgroundImage;
  final String profileImage;
  final String userName;
  final String categoryIcon;
  final String categoryName;
  final String timestamp;
  final bool isRead; // Existing field for read/unread status

  const HappeningNowStoryData({
    required this.storyId,
    required this.backgroundImage,
    required this.profileImage,
    required this.userName,
    required this.categoryIcon,
    required this.categoryName,
    required this.timestamp,
    required this.isRead,
  });

  // NEW: Add copyWith method for updating individual fields
  HappeningNowStoryData copyWith({
    String? storyId,
    String? backgroundImage,
    String? profileImage,
    String? userName,
    String? categoryIcon,
    String? categoryName,
    String? timestamp,
    bool? isRead,
  }) {
    return HappeningNowStoryData(
      storyId: storyId ?? this.storyId,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      profileImage: profileImage ?? this.profileImage,
      userName: userName ?? this.userName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryName: categoryName ?? this.categoryName,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
        storyId,
        backgroundImage,
        profileImage,
        userName,
        categoryIcon,
        categoryName,
        timestamp,
        isRead,
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
