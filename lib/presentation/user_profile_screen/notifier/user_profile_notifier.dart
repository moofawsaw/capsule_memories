import '../../../core/app_export.dart';
import '../../../services/follows_service.dart';
import '../../../services/supabase_service.dart';
import '../models/story_item_model.dart';
import '../models/user_profile_model.dart';

part 'user_profile_state.dart';

final userProfileNotifier =
    StateNotifierProvider.autoDispose<UserProfileNotifier, UserProfileState>(
  (ref) => UserProfileNotifier(
    UserProfileState(
      userProfileModel: UserProfileModel(),
    ),
  ),
);

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final FollowsService _followsService = FollowsService();

  UserProfileNotifier(UserProfileState state) : super(state) {
    initialize();
  }

  void initialize() {
    List<StoryItemModel> storyItems = [
      StoryItemModel(
        userName: 'Kelly Jones',
        userAvatar: ImageConstant.imgFrame2,
        backgroundImage: ImageConstant.imgImg,
        categoryText: 'Vacation',
        categoryIcon: ImageConstant.imgVector,
        timestamp: '2 mins ago',
      ),
      StoryItemModel(
        userName: 'Mac Hollins',
        userAvatar: ImageConstant.imgEllipse826x26,
        backgroundImage: ImageConstant.imgImage8,
        categoryText: 'Vacation',
        categoryIcon: ImageConstant.imgVector,
        timestamp: '2 mins ago',
      ),
      StoryItemModel(
        userName: 'Beth Way',
        userAvatar: ImageConstant.imgFrame48x48,
        backgroundImage: ImageConstant.imgImage8202x116,
        categoryText: 'Vacation',
        categoryIcon: ImageConstant.imgVector,
        timestamp: '2 mins ago',
      ),
      StoryItemModel(
        userName: 'Elliott Freisen',
        userAvatar: ImageConstant.imgEllipse81,
        backgroundImage: ImageConstant.imgImage81,
        categoryText: 'Vacation',
        categoryIcon: ImageConstant.imgVector,
        timestamp: '2 mins ago',
      ),
    ];

    state = state.copyWith(
      userProfileModel: UserProfileModel(
        profileImage: ImageConstant.imgEllipse864x64,
        userName: 'Lucy Ball',
        followersCount: '29',
        followingCount: '6',
        storyItems: storyItems,
      ),
      isLoading: false,
    );
  }

  Future<void> onFollowButtonPressed(String targetUserId) async {
    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    final currentlyFollowing = state.isFollowing ?? false;

    if (currentlyFollowing) {
      // Unfollow user - no toast notification
      final success =
          await _followsService.unfollowUser(currentUser.id, targetUserId);
      if (success) {
        state = state.copyWith(isFollowing: false);
      }
    } else {
      // Follow user - database trigger will create notification automatically
      final success =
          await _followsService.followUser(currentUser.id, targetUserId);
      if (success) {
        state = state.copyWith(isFollowing: true);
      }
    }
  }

  void onAddFriendButtonPressed() {
    state = state.copyWith(
      isFriend: !(state.isFriend ?? false),
    );
  }

  void onBlockButtonPressed() {
    state = state.copyWith(
      isBlocked: !(state.isBlocked ?? false),
    );
  }
}
