import 'package:equatable/equatable.dart';

class StoryItemModel extends Equatable {
  final String? storyId;
  final String? contributorId;
  final String? backgroundImage; // thumbnail or preview
  final String? userAvatar;
  final String? userName;
  final String? categoryIcon;
  final String? categoryText;
  final String? timestamp;

  const StoryItemModel({
    this.storyId,
    this.contributorId,
    this.backgroundImage,
    this.userAvatar,
    this.userName,
    this.categoryIcon,
    this.categoryText,
    this.timestamp,
  });

  StoryItemModel copyWith({
    String? storyId,
    String? contributorId,
    String? backgroundImage,
    String? userAvatar,
    String? userName,
    String? categoryIcon,
    String? categoryText,
    String? timestamp,
  }) {
    return StoryItemModel(
      storyId: storyId ?? this.storyId,
      contributorId: contributorId ?? this.contributorId,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      userAvatar: userAvatar ?? this.userAvatar,
      userName: userName ?? this.userName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryText: categoryText ?? this.categoryText,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        storyId,
        contributorId,
        backgroundImage,
        userAvatar,
        userName,
        categoryIcon,
        categoryText,
        timestamp,
      ];
}
