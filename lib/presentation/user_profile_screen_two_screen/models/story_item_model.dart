import '../../../core/app_export.dart';

/// This class is used in the [user_profile_screen_two_screen] screen.

// ignore_for_file: must_be_immutable
class StoryItemModel extends Equatable {
  StoryItemModel({
    this.storyId,
    this.userName,
    this.userAvatar,
    this.backgroundImage,
    this.categoryText,
    this.categoryIcon,
    this.timestamp,
  }) {
    storyId = storyId ?? '';
    userName = userName ?? "Kelly Jones";
    userAvatar = userAvatar ?? ImageConstant.imgFrame2;
    backgroundImage = backgroundImage ?? ImageConstant.imgImg;
    categoryText = categoryText ?? "Vacation";
    categoryIcon = categoryIcon ?? ImageConstant.imgVector;
    timestamp = timestamp ?? "2 mins ago";
  }

  String? storyId;
  String? userName;
  String? userAvatar;
  String? backgroundImage;
  String? categoryText;
  String? categoryIcon;
  String? timestamp;

  StoryItemModel copyWith({
    String? storyId,
    String? userName,
    String? userAvatar,
    String? backgroundImage,
    String? categoryText,
    String? categoryIcon,
    String? timestamp,
  }) {
    return StoryItemModel(
      storyId: storyId ?? this.storyId,
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
        userName,
        userAvatar,
        backgroundImage,
        categoryText,
        categoryIcon,
        timestamp,
      ];
}
