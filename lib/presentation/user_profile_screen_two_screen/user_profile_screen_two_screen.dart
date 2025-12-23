import '../../core/app_export.dart';
import '../../services/avatar_state_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_profile_header.dart';
import '../../widgets/custom_stat_card.dart';
import '../../widgets/custom_story_card.dart';
import 'notifier/user_profile_screen_two_notifier.dart';

class UserProfileScreenTwo extends ConsumerStatefulWidget {
  UserProfileScreenTwo({Key? key}) : super(key: key);

  @override
  UserProfileScreenTwoState createState() => UserProfileScreenTwoState();
}

class UserProfileScreenTwoState extends ConsumerState<UserProfileScreenTwo> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Extract userId from navigation arguments
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _userId = args?['userId'] as String?;

      // Initialize with userId (if null, will load current user's profile)
      ref
          .read(userProfileScreenTwoNotifier.notifier)
          .initialize(userId: _userId);

      // Load avatar into global state for app-wide access (only for current user)
      if (_userId == null) {
        ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(userProfileScreenTwoNotifier);

            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: appTheme.color3BD81E,
                ),
              );
            }

            return Container(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.only(top: 24.h, left: 18.h, right: 18.h),
                  child: Column(
                    children: [
                      _buildProfileHeader(context),
                      SizedBox(height: 12.h),
                      _buildStatsSection(context),
                      if (_userId != null) ...[
                        SizedBox(height: 16.h),
                        _buildActionButtons(context),
                      ],
                      SizedBox(height: 28.h),
                      _buildStoriesGrid(context),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Profile Header Section
  Widget _buildProfileHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final model = state.userProfileScreenTwoModel;
        final isCurrentUser = _userId == null;

        // 🔥 Watch global avatar state for real-time updates (only for current user)
        final avatarState = ref.watch(avatarStateProvider);

        return GestureDetector(
          onTap: isCurrentUser
              ? () {
                  ref
                      .read(userProfileScreenTwoNotifier.notifier)
                      .uploadAvatar();
                }
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomProfileHeader(
                // Use avatar from global state if current user, otherwise use model avatar
                avatarImagePath:
                    (isCurrentUser ? avatarState.avatarUrl : null) ??
                        model?.avatarImagePath ??
                        ImageConstant.imgEllipse896x96,
                userName: model?.userName ?? 'Loading...',
                email: model?.email ?? 'Fetching data...',
                onEditTap: isCurrentUser
                    ? () {
                        onTapEditProfile(context);
                      }
                    : null,
                margin: EdgeInsets.symmetric(horizontal: 68.h),
              ),
              if (state.isUploading && isCurrentUser)
                Positioned(
                  child: Container(
                    width: 96.h,
                    height: 96.h,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Stats Section
  Widget _buildStatsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final model = state.userProfileScreenTwoModel;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomStatCard(
              count: model?.followersCount ?? '29',
              label: 'followers',
            ),
            SizedBox(width: 12.h),
            CustomStatCard(
              count: model?.followingCount ?? '6',
              label: 'following',
            ),
          ],
        );
      },
    );
  }

  /// Action Buttons Section (Follow, Add Friend, Block)
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final notifier = ref.read(userProfileScreenTwoNotifier.notifier);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: CustomButton(
                text: state.isFollowing ? 'Unfollow' : 'Follow',
                buttonStyle: state.isFollowing
                    ? CustomButtonStyle.fillGray
                    : CustomButtonStyle.fillDeepPurpleA,
                onPressed: () {
                  notifier.toggleFollow();
                },
              ),
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: CustomButton(
                text: state.isFriend
                    ? 'Friends'
                    : state.hasPendingFriendRequest
                        ? 'Pending'
                        : 'Add Friend',
                buttonStyle: state.isFriend || state.hasPendingFriendRequest
                    ? CustomButtonStyle.fillGray
                    : CustomButtonStyle.fillDeepPurpleA,
                onPressed: state.isFriend || state.hasPendingFriendRequest
                    ? null
                    : () {
                        notifier.sendFriendRequest();
                      },
              ),
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: CustomButton(
                text: state.isBlocked ? 'Unblock' : 'Block',
                buttonStyle: state.isBlocked
                    ? CustomButtonStyle.fillGray
                    : CustomButtonStyle.fillRed,
                onPressed: () {
                  _showBlockConfirmationDialog(context, state.isBlocked, () {
                    notifier.toggleBlock();
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBlockConfirmationDialog(
      BuildContext context, bool isBlocked, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appTheme.gray_900_02,
          title: Text(
            isBlocked ? 'Unblock User?' : 'Block User?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          content: Text(
            isBlocked
                ? 'This user will be able to see your content and interact with you again.'
                : 'This user will no longer be able to see your content or interact with you. All existing relationships (friends, follows) will be removed.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.grey[300],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[300],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text(
                isBlocked ? 'Unblock' : 'Block',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurpleAccent[100],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Stories Grid Section
  Widget _buildStoriesGrid(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final stories = state.userProfileScreenTwoModel?.storyItems ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row with 3 stories
            Row(
              children: [
                Expanded(
                  child: CustomStoryCard(
                    userName: stories.isNotEmpty
                        ? stories[0].userName ?? 'Kelly Jones'
                        : 'Kelly Jones',
                    userAvatar: stories.isNotEmpty
                        ? stories[0].userAvatar ?? ImageConstant.imgFrame2
                        : ImageConstant.imgFrame2,
                    backgroundImage: stories.isNotEmpty
                        ? stories[0].backgroundImage ?? ImageConstant.imgImg
                        : ImageConstant.imgImg,
                    categoryText: stories.isNotEmpty
                        ? stories[0].categoryText ?? 'Vacation'
                        : 'Vacation',
                    categoryIcon: stories.isNotEmpty
                        ? stories[0].categoryIcon ?? ImageConstant.imgVector
                        : ImageConstant.imgVector,
                    timestamp: stories.isNotEmpty
                        ? stories[0].timestamp ?? '2 mins ago'
                        : '2 mins ago',
                    onTap: () {
                      onTapStoryCard(context, 0);
                    },
                  ),
                ),
                SizedBox(width: 1.h),
                Expanded(
                  child: CustomStoryCard(
                    userName: stories.length > 1
                        ? stories[1].userName ?? 'Mac Hollins'
                        : 'Mac Hollins',
                    userAvatar: stories.length > 1
                        ? stories[1].userAvatar ??
                            ImageConstant.imgEllipse826x26
                        : ImageConstant.imgEllipse826x26,
                    backgroundImage: stories.length > 1
                        ? stories[1].backgroundImage ?? ImageConstant.imgImage8
                        : ImageConstant.imgImage8,
                    categoryText: stories.length > 1
                        ? stories[1].categoryText ?? 'Vacation'
                        : 'Vacation',
                    categoryIcon: stories.length > 1
                        ? stories[1].categoryIcon ?? ImageConstant.imgVector
                        : ImageConstant.imgVector,
                    timestamp: stories.length > 1
                        ? stories[1].timestamp ?? '2 mins ago'
                        : '2 mins ago',
                    onTap: () {
                      onTapStoryCard(context, 1);
                    },
                  ),
                ),
                SizedBox(width: 1.h),
                Expanded(
                  child: CustomStoryCard(
                    userName: stories.length > 2
                        ? stories[2].userName ?? 'Beth Way'
                        : 'Beth Way',
                    userAvatar: stories.length > 2
                        ? stories[2].userAvatar ?? ImageConstant.imgFrame48x48
                        : ImageConstant.imgFrame48x48,
                    backgroundImage: stories.length > 2
                        ? stories[2].backgroundImage ??
                            ImageConstant.imgImage8202x116
                        : ImageConstant.imgImage8202x116,
                    categoryText: stories.length > 2
                        ? stories[2].categoryText ?? 'Vacation'
                        : 'Vacation',
                    categoryIcon: stories.length > 2
                        ? stories[2].categoryIcon ?? ImageConstant.imgVector
                        : ImageConstant.imgVector,
                    timestamp: stories.length > 2
                        ? stories[2].timestamp ?? '2 mins ago'
                        : '2 mins ago',
                    onTap: () {
                      onTapStoryCard(context, 2);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Second row with 1 story (bottom left)
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 116.h,
                child: CustomStoryCard(
                  userName: stories.length > 3
                      ? stories[3].userName ?? 'Elliott Freisen'
                      : 'Elliott Freisen',
                  userAvatar: stories.length > 3
                      ? stories[3].userAvatar ?? ImageConstant.imgEllipse81
                      : ImageConstant.imgEllipse81,
                  backgroundImage: stories.length > 3
                      ? stories[3].backgroundImage ?? ImageConstant.imgImage81
                      : ImageConstant.imgImage81,
                  categoryText: stories.length > 3
                      ? stories[3].categoryText ?? 'Vacation'
                      : 'Vacation',
                  categoryIcon: stories.length > 3
                      ? stories[3].categoryIcon ?? ImageConstant.imgVector
                      : ImageConstant.imgVector,
                  timestamp: stories.length > 3
                      ? stories[3].timestamp ?? '2 mins ago'
                      : '2 mins ago',
                  onTap: () {
                    onTapStoryCard(context, 3);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Navigate to notifications screen
  void onTapNotificationIcon(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }

  /// Navigate to edit profile
  void onTapEditProfile(BuildContext context) {
    // Edit profile functionality
  }

  /// Navigate to video call screen when story is tapped
  void onTapStoryCard(BuildContext context, int index) {
    NavigatorService.pushNamed(AppRoutes.appVideoCall);
  }
}
