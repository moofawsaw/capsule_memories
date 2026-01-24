part of 'followers_management_notifier.dart';

class FollowersManagementState extends Equatable {
  final FollowersManagementModel? followersManagementModel;
  final bool? isLoading;
  final bool? didFollowBack;
  final bool? isSuccess;

  FollowersManagementState({
    this.followersManagementModel,
    this.isLoading = false,
    this.didFollowBack = false,
    this.isSuccess = false,
  });

  @override
  List<Object?> get props => [
        followersManagementModel,
        isLoading,
        didFollowBack,
        isSuccess,
      ];

  FollowersManagementState copyWith({
    FollowersManagementModel? followersManagementModel,
    bool? isLoading,
    bool? didFollowBack,
    bool? isSuccess,
  }) {
    return FollowersManagementState(
      followersManagementModel:
          followersManagementModel ?? this.followersManagementModel,
      isLoading: isLoading ?? this.isLoading,
      didFollowBack: didFollowBack ?? this.didFollowBack,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
