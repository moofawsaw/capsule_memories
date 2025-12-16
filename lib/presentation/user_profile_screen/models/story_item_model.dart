import '../../../core/app_export.dart';

/// This class is used for story items in the user profile screen.

// ignore_for_file: must_be_immutable
class StoryItemModel extends Equatable {
  StoryItemModel({
    this.userName,
    this.userAvatar,
    this.backgroundImage,
    this.categoryText,
    this.categoryIcon,
    this.timestamp,
  }) {
    userName = userName ?? "";
    userAvatar = userAvatar ?? "";
    backgroundImage = backgroundImage ?? "";
    categoryText = categoryText ?? "";
    categoryIcon = categoryIcon ?? "";
    timestamp = timestamp ?? "";
  }

  String? userName;
  String? userAvatar;
  String? backgroundImage;
  String? categoryText;
  String? categoryIcon;
  String? timestamp;

  StoryItemModel copyWith({
    String? userName,
    String? userAvatar,
    String? backgroundImage,
    String? categoryText,
    String? categoryIcon,
    String? timestamp,
  }) {
    return StoryItemModel(
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
        userName,
        userAvatar,
        backgroundImage,
        categoryText,
        categoryIcon,
        timestamp,
      ];
}
