import '../../../core/app_export.dart';

/// This class is used in the [following_list_screen] screen.

// ignore_for_file: must_be_immutable
class FollowingListModel extends Equatable {
  FollowingListModel({
    this.followingUsers,
  }) {
    followingUsers = followingUsers ?? [];
  }

  List<FollowingUserModel>? followingUsers;

  FollowingListModel copyWith({
    List<FollowingUserModel>? followingUsers,
  }) {
    return FollowingListModel(
      followingUsers: followingUsers ?? this.followingUsers,
    );
  }

  @override
  List<Object?> get props => [followingUsers];
}

// ignore_for_file: must_be_immutable
class FollowingUserModel extends Equatable {
  FollowingUserModel({
    this.id,
    this.name,
    this.followersText,
    this.profileImagePath,
  }) {
    id = id ?? '';
    name = name ?? '';
    followersText = followersText ?? '';
    profileImagePath = profileImagePath ?? '';
  }

  String? id;
  String? name;
  String? followersText;
  String? profileImagePath;

  FollowingUserModel copyWith({
    String? id,
    String? name,
    String? followersText,
    String? profileImagePath,
  }) {
    return FollowingUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      followersText: followersText ?? this.followersText,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }

  @override
  List<Object?> get props => [id, name, followersText, profileImagePath];
}
