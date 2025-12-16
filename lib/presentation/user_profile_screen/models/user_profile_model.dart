import '../../../core/app_export.dart';
import 'story_item_model.dart';

/// This class is used in the [user_profile_screen] screen.

// ignore_for_file: must_be_immutable
class UserProfileModel extends Equatable {
  UserProfileModel({
    this.profileImage,
    this.userName,
    this.followersCount,
    this.followingCount,
    this.storyItems,
  }) {
    profileImage = profileImage ?? ImageConstant.imgEllipse864x64;
    userName = userName ?? "Lucy Ball";
    followersCount = followersCount ?? "29";
    followingCount = followingCount ?? "6";
    storyItems = storyItems ?? [];
  }

  String? profileImage;
  String? userName;
  String? followersCount;
  String? followingCount;
  List<StoryItemModel>? storyItems;

  UserProfileModel copyWith({
    String? profileImage,
    String? userName,
    String? followersCount,
    String? followingCount,
    List<StoryItemModel>? storyItems,
  }) {
    return UserProfileModel(
      profileImage: profileImage ?? this.profileImage,
      userName: userName ?? this.userName,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      storyItems: storyItems ?? this.storyItems,
    );
  }

  @override
  List<Object?> get props => [
        profileImage,
        userName,
        followersCount,
        followingCount,
        storyItems,
      ];
}
