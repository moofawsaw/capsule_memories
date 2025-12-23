part of 'user_profile_screen_two_notifier.dart';

class UserProfileScreenTwoState extends Equatable {
  UserProfileScreenTwoState({
    this.userProfileScreenTwoModel,
    this.isUploading = false,
    this.isLoading = false,
    this.isFollowing = false,
    this.isFriend = false,
    this.hasPendingFriendRequest = false,
    this.isBlocked = false,
    this.targetUserId,
  });

  UserProfileScreenTwoModel? userProfileScreenTwoModel;
  bool isUploading;
  bool isLoading;
  bool isFollowing;
  bool isFriend;
  bool hasPendingFriendRequest;
  bool isBlocked;
  String? targetUserId;

  @override
  List<Object?> get props => [
        userProfileScreenTwoModel,
        isUploading,
        isLoading,
        isFollowing,
        isFriend,
        hasPendingFriendRequest,
        isBlocked,
        targetUserId,
      ];

  UserProfileScreenTwoState copyWith({
    UserProfileScreenTwoModel? userProfileScreenTwoModel,
    bool? isUploading,
    bool? isLoading,
    bool? isFollowing,
    bool? isFriend,
    bool? hasPendingFriendRequest,
    bool? isBlocked,
    String? targetUserId,
  }) {
    return UserProfileScreenTwoState(
      userProfileScreenTwoModel:
          userProfileScreenTwoModel ?? this.userProfileScreenTwoModel,
      isUploading: isUploading ?? this.isUploading,
      isLoading: isLoading ?? this.isLoading,
      isFollowing: isFollowing ?? this.isFollowing,
      isFriend: isFriend ?? this.isFriend,
      hasPendingFriendRequest:
          hasPendingFriendRequest ?? this.hasPendingFriendRequest,
      isBlocked: isBlocked ?? this.isBlocked,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }
}
