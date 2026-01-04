
/// This class is used for story items in the user profile screen.

// ignore_for_file: must_be_immutable
class StoryItemModel {
  String? backgroundImage;
  String? userAvatar;
  String? userName;
  String? categoryIcon;
  String? categoryText;
  String? timestamp;
  String? storyId;
  String? contributorId;

  StoryItemModel({
    this.backgroundImage,
    this.userAvatar,
    this.userName,
    this.categoryIcon,
    this.categoryText,
    this.timestamp,
    this.storyId,
    this.contributorId,
  });
}
