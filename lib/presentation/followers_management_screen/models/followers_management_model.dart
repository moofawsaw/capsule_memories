import '../../../core/app_export.dart';

/// This class is used in the [FollowersManagementScreen] screen.

// ignore_for_file: must_be_immutable
class FollowersManagementModel extends Equatable {
  FollowersManagementModel({
    this.followersList,
  }) {
    followersList = followersList ?? [];
  }

  List<FollowerItemModel>? followersList;

  FollowersManagementModel copyWith({
    List<FollowerItemModel>? followersList,
  }) {
    return FollowersManagementModel(
      followersList: followersList ?? this.followersList,
    );
  }

  @override
  List<Object?> get props => [followersList];
}

class FollowerItemModel extends Equatable {
  FollowerItemModel({
    this.name,
    this.followersCount,
    this.profileImage,
    this.id,
    this.isFollowingBack,
  }) {
    name = name ?? '';
    followersCount = followersCount ?? '';
    profileImage = profileImage ?? '';
    id = id ?? '';
    isFollowingBack = isFollowingBack ?? false;
  }

  String? name;
  String? followersCount;
  String? profileImage;
  String? id;
  bool? isFollowingBack;

  FollowerItemModel copyWith({
    String? name,
    String? followersCount,
    String? profileImage,
    String? id,
    bool? isFollowingBack,
  }) {
    return FollowerItemModel(
      name: name ?? this.name,
      followersCount: followersCount ?? this.followersCount,
      profileImage: profileImage ?? this.profileImage,
      id: id ?? this.id,
      isFollowingBack: isFollowingBack ?? this.isFollowingBack,
    );
  }

  @override
  List<Object?> get props =>
      [name, followersCount, profileImage, id, isFollowingBack];
}
