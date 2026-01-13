import '../../../core/app_export.dart';

/// Model used by UserProfileScreenTwo for profile story grid items.
class StoryItemModel extends Equatable {
  const StoryItemModel({
    this.storyId,
    this.contributorId,
    this.userName,
    this.userAvatar,
    this.backgroundImage,
    this.categoryText,
    this.categoryIcon,
    this.timestamp,
  });

  final String? storyId;
  final String? contributorId;
  final String? userName;
  final String? userAvatar;
  final String? backgroundImage;
  final String? categoryText;
  final String? categoryIcon;
  final String? timestamp;

  StoryItemModel copyWith({
    String? storyId,
    String? contributorId,
    String? userName,
    String? userAvatar,
    String? backgroundImage,
    String? categoryText,
    String? categoryIcon,
    String? timestamp,
  }) {
    return StoryItemModel(
      storyId: storyId ?? this.storyId,
      contributorId: contributorId ?? this.contributorId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      categoryText: categoryText ?? this.categoryText,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    storyId,
    contributorId,
    userName,
    userAvatar,
    backgroundImage,
    categoryText,
    categoryIcon,
    timestamp,
  ];
}
