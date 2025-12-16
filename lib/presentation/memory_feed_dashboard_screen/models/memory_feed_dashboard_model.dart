import '../../../core/app_export.dart';

/// This class is used in the [MemoryFeedDashboardScreen] screen.

// ignore_for_file: must_be_immutable
class MemoryFeedDashboardModel extends Equatable {
  MemoryFeedDashboardModel({
    this.happeningNowStories,
    this.publicMemories,
    this.trendingStories,
  }) {
    happeningNowStories =
        happeningNowStories ?? _getDefaultHappeningNowStories();
    publicMemories = publicMemories ?? _getDefaultPublicMemories();
    trendingStories = trendingStories ?? [];
  }

  List<HappeningNowStoryData>? happeningNowStories;
  List<CustomMemoryItem>? publicMemories;
  List<String>? trendingStories;

  MemoryFeedDashboardModel copyWith({
    List<HappeningNowStoryData>? happeningNowStories,
    List<CustomMemoryItem>? publicMemories,
    List<String>? trendingStories,
  }) {
    return MemoryFeedDashboardModel(
      happeningNowStories: happeningNowStories ?? this.happeningNowStories,
      publicMemories: publicMemories ?? this.publicMemories,
      trendingStories: trendingStories ?? this.trendingStories,
    );
  }

  @override
  List<Object?> get props => [
        happeningNowStories,
        publicMemories,
        trendingStories,
      ];

  static List<HappeningNowStoryData> _getDefaultHappeningNowStories() {
    return [
      HappeningNowStoryData(
        id: 'story_1',
        backgroundImage: ImageConstant.imgImage81,
        profileImage: ImageConstant.imgFrame48x48,
        userName: 'Kelly Jones',
        categoryName: 'Hangout',
        categoryIcon: ImageConstant.imgEmojiMemorycategory,
        timestamp: '2 mins ago',
        isViewed: false,
      ),
      HappeningNowStoryData(
        id: 'story_2',
        backgroundImage: ImageConstant.imgImage9,
        profileImage: ImageConstant.imgEllipse842x42,
        userName: 'Lauren Foo',
        categoryName: 'Vacation',
        categoryIcon: ImageConstant.imgVector,
        timestamp: '2 mins ago',
        isViewed: false,
      ),
      HappeningNowStoryData(
        id: 'story_3',
        backgroundImage: ImageConstant.imgImage8202x116,
        profileImage: ImageConstant.imgEllipse842x1,
        userName: 'Kelly Jones',
        categoryName: 'Hangout',
        categoryIcon: ImageConstant.imgEmojiMemorycategory,
        timestamp: '2 mins ago',
        isViewed: false,
      ),
    ];
  }

  static List<CustomMemoryItem> _getDefaultPublicMemories() {
    return [
      CustomMemoryItem(
        id: 'memory_1',
        title: 'Nixon Wedding 2025',
        date: 'Dec 4, 2025',
        iconPath: ImageConstant.imgFrame13Red600,
        profileImages: [
          ImageConstant.imgFrame2,
          ImageConstant.imgFrame1,
          ImageConstant.imgEllipse81,
        ],
        mediaItems: [
          CustomMediaItem(
            imagePath: ImageConstant.imgImage9,
            hasPlayButton: true,
          ),
          CustomMediaItem(
            imagePath: ImageConstant.imgImage8,
            hasPlayButton: true,
          ),
        ],
        startDate: 'Dec 4',
        startTime: '3:18pm',
        endDate: 'Dec 4',
        endTime: '3:18am',
        location: 'Tillsonburg, ON',
        distance: '21km',
        isLiked: false,
      ),
    ];
  }
}

class HappeningNowStoryData extends Equatable {
  final String? id;
  final String? backgroundImage;
  final String? profileImage;
  final String? userName;
  final String? categoryName;
  final String? categoryIcon;
  final String? timestamp;
  final bool? isViewed;

  HappeningNowStoryData({
    this.id,
    this.backgroundImage,
    this.profileImage,
    this.userName,
    this.categoryName,
    this.categoryIcon,
    this.timestamp,
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
        isViewed,
      ];
}

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
    this.isLiked = false,
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

class CustomMediaItem extends Equatable {
  final String? imagePath;
  final bool? hasPlayButton;

  CustomMediaItem({
    this.imagePath,
    this.hasPlayButton = false,
  });

  @override
  List<Object?> get props => [imagePath, hasPlayButton];
}
