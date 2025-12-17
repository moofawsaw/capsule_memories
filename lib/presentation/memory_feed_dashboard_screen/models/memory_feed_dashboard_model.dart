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
    trendingStories = trendingStories ?? _getDefaultTrendingStories();
  }

  List<HappeningNowStoryData>? happeningNowStories;
  List<CustomMemoryItem>? publicMemories;
  List<HappeningNowStoryData>? trendingStories;

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
          'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=200&h=200',
          'https://images.pexels.com/photos/1516680/pexels-photo-1516680.jpeg?auto=compress&cs=tinysrgb&w=200&h=200',
          'https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=200&h=200',
        ],
        mediaItems: [
          CustomMediaItem(
            imagePath:
                'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=600&fit=crop',
            hasPlayButton: true,
          ),
          CustomMediaItem(
            imagePath:
                'https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=400&h=600&fit=crop',
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
      CustomMemoryItem(
        id: 'memory_2',
        title: 'Summer Beach Trip',
        date: 'Aug 15, 2025',
        iconPath: ImageConstant.imgVector,
        profileImages: [
          'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=200&h=200',
          'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=200&h=200',
          'https://images.pexels.com/photos/1193942/pexels-photo-1193942.jpeg?auto=compress&cs=tinysrgb&w=200&h=200',
        ],
        mediaItems: [
          CustomMediaItem(
            imagePath:
                'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=600&fit=crop',
            hasPlayButton: false,
          ),
          CustomMediaItem(
            imagePath:
                'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=400&h=600&fit=crop',
            hasPlayButton: false,
          ),
        ],
        startDate: 'Aug 15',
        startTime: '10:30am',
        endDate: 'Aug 15',
        endTime: '6:45pm',
        location: 'Santa Monica, CA',
        distance: '45km',
        isLiked: false,
      ),
    ];
  }

  static List<HappeningNowStoryData> _getDefaultTrendingStories() {
    return [
      HappeningNowStoryData(
        id: 'trending_1',
        backgroundImage: ImageConstant.imgImage8542x342,
        profileImage: ImageConstant.imgEllipse842x42,
        userName: 'Sarah Mitchell',
        categoryName: 'Birthday Party',
        categoryIcon: ImageConstant.imgFrame13,
        timestamp: '15 mins ago',
        isViewed: false,
      ),
      HappeningNowStoryData(
        id: 'trending_2',
        backgroundImage: ImageConstant.imgImage8120x90,
        profileImage: ImageConstant.imgEllipse8DeepOrange10001,
        userName: 'Mike Johnson',
        categoryName: 'Adventure',
        categoryIcon: ImageConstant.imgVector,
        timestamp: '1 hour ago',
        isViewed: false,
      ),
      HappeningNowStoryData(
        id: 'trending_3',
        backgroundImage: ImageConstant.imgImage81,
        profileImage: ImageConstant.imgEllipse826x26,
        userName: 'Emma Davis',
        categoryName: 'Celebration',
        categoryIcon: ImageConstant.imgEmojiMemorycategory,
        timestamp: '2 hours ago',
        isViewed: false,
      ),
      HappeningNowStoryData(
        id: 'trending_4',
        backgroundImage: ImageConstant.imgImage9,
        profileImage: ImageConstant.imgEllipse852x52,
        userName: 'David Chen',
        categoryName: 'Concert',
        categoryIcon: ImageConstant.imgFrame13,
        timestamp: '3 hours ago',
        isViewed: false,
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
