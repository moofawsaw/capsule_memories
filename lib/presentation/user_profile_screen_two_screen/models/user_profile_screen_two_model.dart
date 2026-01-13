import '../../../core/app_export.dart';
import './story_item_model.dart';

/// Used in [UserProfileScreenTwo]
/// Email is OPTIONAL and must only be set for the current user

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
    avatarImagePath ??= ImageConstant.imgEllipse896x96;
    userName ??= 'User';
    followersCount ??= '0';
    followingCount ??= '0';
    storyItems ??= [];
    id ??= '';
    // 🚫 DO NOT default email
  }

  String? avatarImagePath;
  String? userName;

  /// ⚠️ PRIVATE FIELD — ONLY for current user
  String? email;

  String? followersCount;
  String? followingCount;
  List<StoryItemModel>? storyItems;
  String? id;

  UserProfileScreenTwoModel copyWith({
    String? avatarImagePath,
    String? userName,
    String? email,
    bool clearEmail = false, // 🔒 explicit control
    String? followersCount,
    String? followingCount,
    List<StoryItemModel>? storyItems,
    String? id,
  }) {
    return UserProfileScreenTwoModel(
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      userName: userName ?? this.userName,
      email: clearEmail ? null : (email ?? this.email),
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
