import '../../../core/app_export.dart';

/// This class is used in the [FollowingListScreen] screen.

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

/// ✅ Search results model for the Following screen search panel
/// Uses RPC search_users_smart output (we only need a subset for UI).
// ignore_for_file: must_be_immutable
class FollowingSearchUserModel extends Equatable {
  FollowingSearchUserModel({
    this.id,
    this.userName,
    this.displayName,
    this.profileImagePath,
    this.isFollowing,
    this.mutualFriendCount,
    this.distanceKm,
  }) {
    id = id ?? '';
    userName = userName ?? '';
    displayName = displayName ?? '';
    profileImagePath = profileImagePath ?? '';
    isFollowing = isFollowing ?? false;
    mutualFriendCount = mutualFriendCount ?? 0;
    distanceKm = distanceKm;
  }

  String? id;
  String? userName;
  String? displayName;
  String? profileImagePath;
  bool? isFollowing;

  // Optional extras from search_users_smart (safe to keep for later UI)
  int? mutualFriendCount;
  double? distanceKm;

  FollowingSearchUserModel copyWith({
    String? id,
    String? userName,
    String? displayName,
    String? profileImagePath,
    bool? isFollowing,
    int? mutualFriendCount,
    double? distanceKm,
  }) {
    return FollowingSearchUserModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      displayName: displayName ?? this.displayName,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isFollowing: isFollowing ?? this.isFollowing,
      mutualFriendCount: mutualFriendCount ?? this.mutualFriendCount,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userName,
    displayName,
    profileImagePath,
    isFollowing,
    mutualFriendCount,
    distanceKm,
  ];
}
