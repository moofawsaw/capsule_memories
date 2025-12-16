part of 'user_profile_notifier.dart';

class UserProfileState extends Equatable {
  final UserProfileModel? userProfileModel;
  final bool? isLoading;
  final bool? isFollowing;
  final bool? isFriend;
  final bool? isBlocked;

  UserProfileState({
    this.userProfileModel,
    this.isLoading = false,
    this.isFollowing = false,
    this.isFriend = false,
    this.isBlocked = false,
  });

  @override
  List<Object?> get props => [
        userProfileModel,
        isLoading,
        isFollowing,
        isFriend,
        isBlocked,
      ];

  UserProfileState copyWith({
    UserProfileModel? userProfileModel,
    bool? isLoading,
    bool? isFollowing,
    bool? isFriend,
    bool? isBlocked,
  }) {
    return UserProfileState(
      userProfileModel: userProfileModel ?? this.userProfileModel,
      isLoading: isLoading ?? this.isLoading,
      isFollowing: isFollowing ?? this.isFollowing,
      isFriend: isFriend ?? this.isFriend,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
