import '../models/following_list_model.dart';
import '../../../core/app_export.dart';

part 'following_list_state.dart';

final followingListNotifier = StateNotifierProvider.autoDispose<
    FollowingListNotifier, FollowingListState>(
  (ref) => FollowingListNotifier(
    FollowingListState(
      followingListModel: FollowingListModel(),
    ),
  ),
);

class FollowingListNotifier extends StateNotifier<FollowingListState> {
  FollowingListNotifier(FollowingListState state) : super(state) {
    initialize();
  }

  void initialize() {
    final followingUsers = [
      FollowingUserModel(
        id: '1',
        name: 'Tyler James',
        followersText: '25 followers',
        profileImagePath: ImageConstant.imgEllipse8DeepOrange100,
      ),
      FollowingUserModel(
        id: '2',
        name: 'Jackson Hill',
        followersText: '25 followers',
        profileImagePath: ImageConstant.imgEllipse8Orange100,
      ),
      FollowingUserModel(
        id: '3',
        name: 'Billy Volek',
        followersText: '25 followers',
        profileImagePath: ImageConstant.imgEllipse8Orange100,
      ),
    ];

    state = state.copyWith(
      followingListModel: state.followingListModel?.copyWith(
        followingUsers: followingUsers,
      ),
    );
  }

  void onUserAction(FollowingUserModel? user) {
    if (user != null) {
      // Handle user action (show options, unfollow, etc.)
      state = state.copyWith(
        selectedUser: user,
      );
    }
  }

  void unfollowUser(String userId) {
    final currentUsers = state.followingListModel?.followingUsers ?? [];
    final updatedUsers =
        currentUsers.where((user) => user.id != userId).toList();

    state = state.copyWith(
      followingListModel: state.followingListModel?.copyWith(
        followingUsers: updatedUsers,
      ),
    );
  }
}
