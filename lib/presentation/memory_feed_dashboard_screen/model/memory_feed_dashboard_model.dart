// lib/presentation/memory_feed_dashboard_screen/model/memory_feed_dashboard_model.dart

import '../../../core/app_export.dart';
import '../../../utils/storage_utils.dart';

/// This class defines the model for the MemoryFeedDashboard screen.
class MemoryFeedDashboardModel extends Equatable {
  final List<HappeningNowStoryData>? happeningNowStories;
  final List<HappeningNowStoryData>? latestStories;
  final List<HappeningNowStoryData>? trendingStories;
  final List<HappeningNowStoryData>? longestStreakStories;
  final List<HappeningNowStoryData>? popularUserStories;

  // ✅ NEW STORY FEEDS
  final List<HappeningNowStoryData>? fromFriendsStories;
  final List<HappeningNowStoryData>? forYouStories;

  final List<CustomMemoryItem>? publicMemories;

  // ✅ Existing
  final List<CustomMemoryItem>? popularMemories;

  // ✅ NEW MEMORY FEED
  final List<CustomMemoryItem>? forYouMemories;

  MemoryFeedDashboardModel({
    this.happeningNowStories = const [],
    this.latestStories = const [],
    this.trendingStories = const [],
    this.longestStreakStories = const [],
    this.popularUserStories = const [],

    // ✅ NEW STORY FEEDS
    this.fromFriendsStories = const [],
    this.forYouStories = const [],

    this.publicMemories = const [],

    // ✅ Existing
    this.popularMemories = const [],

    // ✅ NEW MEMORY FEED
    this.forYouMemories = const [],
  });

  MemoryFeedDashboardModel copyWith({
    List<HappeningNowStoryData>? happeningNowStories,
    List<HappeningNowStoryData>? latestStories,
    List<HappeningNowStoryData>? trendingStories,
    List<HappeningNowStoryData>? longestStreakStories,
    List<HappeningNowStoryData>? popularUserStories,

    // ✅ NEW STORY FEEDS
    List<HappeningNowStoryData>? fromFriendsStories,
    List<HappeningNowStoryData>? forYouStories,

    List<CustomMemoryItem>? publicMemories,

    // ✅ Existing
    List<CustomMemoryItem>? popularMemories,

    // ✅ NEW MEMORY FEED
    List<CustomMemoryItem>? forYouMemories,
  }) {
    return MemoryFeedDashboardModel(
      happeningNowStories: happeningNowStories ?? this.happeningNowStories,
      latestStories: latestStories ?? this.latestStories,
      trendingStories: trendingStories ?? this.trendingStories,
      longestStreakStories: longestStreakStories ?? this.longestStreakStories,
      popularUserStories: popularUserStories ?? this.popularUserStories,

      // ✅ NEW STORY FEEDS
      fromFriendsStories: fromFriendsStories ?? this.fromFriendsStories,
      forYouStories: forYouStories ?? this.forYouStories,

      publicMemories: publicMemories ?? this.publicMemories,

      // ✅ Existing
      popularMemories: popularMemories ?? this.popularMemories,

      // ✅ NEW MEMORY FEED
      forYouMemories: forYouMemories ?? this.forYouMemories,
    );
  }

  @override
  List<Object?> get props => [
    happeningNowStories,
    latestStories,
    trendingStories,
    longestStreakStories,
    popularUserStories,

    // ✅ NEW STORY FEEDS
    fromFriendsStories,
    forYouStories,

    publicMemories,

    // ✅ Existing
    popularMemories,

    // ✅ NEW MEMORY FEED
    forYouMemories,
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
  final bool isRead;

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

  /// Call sites may pass:
  /// - stable iconName ("life", "road-trip")
  /// - stable path ("life.svg")
  /// - full url (sometimes stale uploaded icon_url like ".../1768...-abcd.svg")
  final String? iconName;

  /// Keep the raw value passed in from existing code.
  final String? _iconPathRaw;

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
    String? iconPath,
    this.iconName,
    this.profileImages,
    this.mediaItems,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.location,
    this.distance,
    this.isLiked,
  }) : _iconPathRaw = iconPath;

  /// ✅ Normalized icon path used by UI.
  /// Rule:
  /// - If iconName exists, ALWAYS build bucket URL from it => category-icons/<iconName>.svg
  /// - Else if raw looks like a plain name, build bucket URL
  /// - Else return raw (legacy full URL)
  String? get iconPath {
    final String name = (iconName ?? '').trim();
    final String raw = (_iconPathRaw ?? '').trim();

    // 1) iconName wins: stable, non-stale
    if (name.isNotEmpty) {
      final String file = name.toLowerCase().endsWith('.svg') ? name : '$name.svg';
      return StorageUtils.resolveMemoryCategoryIconUrl(file);
    }

    if (raw.isEmpty) return null;

    // 2) If raw is NOT a URL, treat it as name/path and resolve
    final bool isUrl = raw.startsWith('http://') || raw.startsWith('https://');
    if (!isUrl) {
      final String file = raw.toLowerCase().endsWith('.svg') ? raw : '$raw.svg';
      return StorageUtils.resolveMemoryCategoryIconUrl(file);
    }

    // 3) raw is URL (could be stale icon_url). We can’t safely infer iconName here.
    return raw;
  }

  CustomMemoryItem copyWith({
    String? id,
    String? title,
    String? date,
    String? iconPath,
    String? iconName,
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
      iconPath: iconPath ?? _iconPathRaw,
      iconName: iconName ?? this.iconName,
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
    iconName,
    _iconPathRaw,
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
