part of 'followers_management_notifier.dart';

class FollowersManagementState extends Equatable {
  final FollowersManagementModel? followersManagementModel;
  final bool? isLoading;
  final bool? isBlocked;
  final bool? isSuccess;

  FollowersManagementState({
    this.followersManagementModel,
    this.isLoading = false,
    this.isBlocked = false,
    this.isSuccess = false,
  });

  @override
  List<Object?> get props => [
        followersManagementModel,
        isLoading,
        isBlocked,
        isSuccess,
      ];

  FollowersManagementState copyWith({
    FollowersManagementModel? followersManagementModel,
    bool? isLoading,
    bool? isBlocked,
    bool? isSuccess,
  }) {
    return FollowersManagementState(
      followersManagementModel:
          followersManagementModel ?? this.followersManagementModel,
      isLoading: isLoading ?? this.isLoading,
      isBlocked: isBlocked ?? this.isBlocked,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
