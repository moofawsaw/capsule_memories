part of 'following_list_notifier.dart';

class FollowingListState extends Equatable {
  final FollowingListModel? followingListModel;
  final FollowingUserModel? selectedUser;
  final bool? isLoading;

  FollowingListState({
    this.followingListModel,
    this.selectedUser,
    this.isLoading = false,
  });

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
