import '../models/followers_management_model.dart';
import '../../../core/app_export.dart';

part 'followers_management_state.dart';

final followersManagementNotifier = StateNotifierProvider.autoDispose<
    FollowersManagementNotifier, FollowersManagementState>(
  (ref) => FollowersManagementNotifier(
    FollowersManagementState(
      followersManagementModel: FollowersManagementModel(),
    ),
  ),
);

class FollowersManagementNotifier
    extends StateNotifier<FollowersManagementState> {
  FollowersManagementNotifier(FollowersManagementState state) : super(state) {
    initialize();
  }

  void initialize() {
    // Initialize with sample followers data
    final followersList = [
      FollowerItemModel(
        name: 'Tyler James',
        followersCount: '25 followers',
        profileImage: ImageConstant.imgEllipse8DeepOrange100,
      ),
      FollowerItemModel(
        name: 'Jackson Hill',
        followersCount: '25 followers',
        profileImage: ImageConstant.imgEllipse8Orange100,
      ),
      FollowerItemModel(
        name: 'Billy Volek',
        followersCount: '25 followers',
        profileImage: ImageConstant.imgEllipse8Orange100,
      ),
    ];

    state = state.copyWith(
      followersManagementModel: state.followersManagementModel?.copyWith(
        followersList: followersList,
      ),
      isLoading: false,
    );
  }

  void blockFollower(int index) {
    state = state.copyWith(isLoading: true);

    // Remove follower from the list
    final updatedList = List<FollowerItemModel>.from(
        state.followersManagementModel?.followersList ?? []);

    if (index >= 0 && index < updatedList.length) {
      updatedList.removeAt(index);

      state = state.copyWith(
        followersManagementModel: state.followersManagementModel?.copyWith(
          followersList: updatedList,
        ),
        isLoading: false,
        isBlocked: true,
      );

      // Reset blocked status after showing message
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          state = state.copyWith(isBlocked: false);
        }
      });
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void switchToFollowing() {
    // Handle switching to following tab
    // This would typically navigate to following screen or update tab state
  }
}
