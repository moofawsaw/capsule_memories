import '../../../core/app_export.dart';
import 'story_item_model.dart';

/// This class is used in the [UserProfileScreenTwo] screen.

// ignore_for_file: must_be_immutable
class UserProfileScreenTwoModel extends Equatable {
  UserProfileScreenTwoModel({
    this.avatarImagePath,
    this.userName,
    this.email,
    this.followersCount,
    this.followingCount,
    this.storyItems,
    this.id,
  }) {
    avatarImagePath = avatarImagePath ?? ImageConstant.imgEllipse896x96;
    userName = userName ?? 'Joe Kool';
    email = email ?? 'karl_martin67@hotmail.com';
    followersCount = followersCount ?? '29';
    followingCount = followingCount ?? '6';
    storyItems = storyItems ?? [];
    id = id ?? '';
  }

  String? avatarImagePath;
  String? userName;
  String? email;
  String? followersCount;
  String? followingCount;
  List<StoryItemModel>? storyItems;
  String? id;

  UserProfileScreenTwoModel copyWith({
    String? avatarImagePath,
    String? userName,
    String? email,
    String? followersCount,
    String? followingCount,
    List<StoryItemModel>? storyItems,
    String? id,
  }) {
    return UserProfileScreenTwoModel(
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      storyItems: storyItems ?? this.storyItems,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        avatarImagePath,
        userName,
        email,
        followersCount,
        followingCount,
        storyItems,
        id,
      ];
}
