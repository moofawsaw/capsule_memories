part of 'following_list_notifier.dart';

/// Represents the state for the following list screen.
// ignore: must_be_immutable
class FollowingListState extends Equatable {
  FollowingListState({
    this.followingListModel,
    this.selectedUser,
    this.isLoading,
  });

  FollowingListModel? followingListModel;
  FollowingUserModel? selectedUser;
  bool? isLoading;

  @override
  List<Object?> get props => [
        followingListModel,
        selectedUser,
        isLoading,
      ];

  FollowingListState copyWith({
    FollowingListModel? followingListModel,
    FollowingUserModel? selectedUser,
    bool? isLoading,
  }) {
    return FollowingListState(
      followingListModel: followingListModel ?? this.followingListModel,
      selectedUser: selectedUser ?? this.selectedUser,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
