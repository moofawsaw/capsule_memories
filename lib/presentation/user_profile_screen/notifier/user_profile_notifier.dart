import '../models/user_profile_model.dart';
import '../models/story_item_model.dart';
import '../../../core/app_export.dart';

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

  void onFollowButtonPressed() {
    state = state.copyWith(
      isFollowing: !(state.isFollowing ?? false),
    );
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
