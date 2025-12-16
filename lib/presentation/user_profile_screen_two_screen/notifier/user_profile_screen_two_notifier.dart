import '../models/user_profile_screen_two_model.dart';
import '../models/story_item_model.dart';
import '../../../core/app_export.dart';

part 'user_profile_screen_two_state.dart';

final userProfileScreenTwoNotifier = StateNotifierProvider.autoDispose<
    UserProfileScreenTwoNotifier, UserProfileScreenTwoState>(
  (ref) => UserProfileScreenTwoNotifier(
    UserProfileScreenTwoState(
      userProfileScreenTwoModel: UserProfileScreenTwoModel(),
    ),
  ),
);

class UserProfileScreenTwoNotifier
    extends StateNotifier<UserProfileScreenTwoState> {
  UserProfileScreenTwoNotifier(UserProfileScreenTwoState state) : super(state);

  void initialize() {
    final storyItems = [
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
      userProfileScreenTwoModel: UserProfileScreenTwoModel(
        avatarImagePath: ImageConstant.imgEllipse896x96,
        userName: 'Joe Kool',
        email: 'karl_martin67@hotmail.com',
        followersCount: '29',
        followingCount: '6',
        storyItems: storyItems,
      ),
    );
  }

  void updateProfile(String userName, String email) {
    state = state.copyWith(
      userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
        userName: userName,
        email: email,
      ),
    );
  }

  void updateStats(String followersCount, String followingCount) {
    state = state.copyWith(
      userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
        followersCount: followersCount,
        followingCount: followingCount,
      ),
    );
  }
}
