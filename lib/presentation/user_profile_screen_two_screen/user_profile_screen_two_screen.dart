import '../../core/app_export.dart';
import '../../presentation/event_stories_view_screen/models/event_stories_view_model.dart';
import '../../services/avatar_state_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_profile_header.dart';
import '../../widgets/custom_stat_card.dart';
import '../../widgets/custom_story_card.dart';
import '../../widgets/custom_story_skeleton.dart';
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
                leftIcon: state.isFollowing
                    ? 'https://img.icons8.com/ios-filled/50/FFFFFF/checked-user-male.png'
                    : 'https://img.icons8.com/ios-filled/50/FFFFFF/add-user-male.png',
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
                leftIcon: state.isFriend
                    ? 'https://img.icons8.com/ios-filled/50/FFFFFF/friends.png'
                    : state.hasPendingFriendRequest
                        ? 'https://img.icons8.com/ios-filled/50/FFFFFF/clock.png'
                        : 'https://img.icons8.com/ios-filled/50/FFFFFF/add-user-group-man-man.png',
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
                leftIcon: state.isBlocked
                    ? 'https://img.icons8.com/ios-filled/50/FFFFFF/lock-2.png'
                    : 'https://img.icons8.com/ios-filled/50/FFFFFF/block-user.png',
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

        // Show loading placeholders while stories are fetching
        if (state.isLoadingStories) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row with 3 skeleton placeholders
              Row(
                children: [
                  Expanded(child: CustomStorySkeleton()),
                  SizedBox(width: 1.h),
                  Expanded(child: CustomStorySkeleton()),
                  SizedBox(width: 1.h),
                  Expanded(child: CustomStorySkeleton()),
                ],
              ),
              SizedBox(height: 1.h),
              // Second row with 1 skeleton placeholder
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 116.h,
                  child: CustomStorySkeleton(),
                ),
              ),
            ],
          );
        }

        // Show empty state if no stories
        if (stories.isEmpty) {
          return _buildEmptyStoriesState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row with 3 stories
            Row(
              children: [
                if (stories.isNotEmpty)
                  Expanded(
                    child: CustomStoryCard(
                      userName: stories[0].userName ?? 'User',
                      userAvatar: stories[0].userAvatar ??
                          ImageConstant.imgEllipse896x96,
                      backgroundImage:
                          stories[0].backgroundImage ?? ImageConstant.imgImg,
                      categoryText: stories[0].categoryText ?? 'Memory',
                      categoryIcon:
                          stories[0].categoryIcon ?? ImageConstant.imgVector,
                      timestamp: stories[0].timestamp ?? 'Just now',
                      onTap: () {
                        onTapStoryCard(context, 0);
                      },
                    ),
                  ),
                if (stories.length > 1) ...[
                  SizedBox(width: 1.h),
                  Expanded(
                    child: CustomStoryCard(
                      userName: stories[1].userName ?? 'User',
                      userAvatar: stories[1].userAvatar ??
                          ImageConstant.imgEllipse896x96,
                      backgroundImage:
                          stories[1].backgroundImage ?? ImageConstant.imgImage8,
                      categoryText: stories[1].categoryText ?? 'Memory',
                      categoryIcon:
                          stories[1].categoryIcon ?? ImageConstant.imgVector,
                      timestamp: stories[1].timestamp ?? 'Just now',
                      onTap: () {
                        onTapStoryCard(context, 1);
                      },
                    ),
                  ),
                ],
                if (stories.length > 2) ...[
                  SizedBox(width: 1.h),
                  Expanded(
                    child: CustomStoryCard(
                      userName: stories[2].userName ?? 'User',
                      userAvatar: stories[2].userAvatar ??
                          ImageConstant.imgEllipse896x96,
                      backgroundImage: stories[2].backgroundImage ??
                          ImageConstant.imgImage8202x116,
                      categoryText: stories[2].categoryText ?? 'Memory',
                      categoryIcon:
                          stories[2].categoryIcon ?? ImageConstant.imgVector,
                      timestamp: stories[2].timestamp ?? 'Just now',
                      onTap: () {
                        onTapStoryCard(context, 2);
                      },
                    ),
                  ),
                ],
              ],
            ),
            if (stories.length > 3) ...[
              SizedBox(height: 1.h),
              // Second row with additional stories
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 116.h,
                  child: CustomStoryCard(
                    userName: stories[3].userName ?? 'User',
                    userAvatar:
                        stories[3].userAvatar ?? ImageConstant.imgEllipse896x96,
                    backgroundImage:
                        stories[3].backgroundImage ?? ImageConstant.imgImage81,
                    categoryText: stories[3].categoryText ?? 'Memory',
                    categoryIcon:
                        stories[3].categoryIcon ?? ImageConstant.imgVector,
                    timestamp: stories[3].timestamp ?? 'Just now',
                    onTap: () {
                      onTapStoryCard(context, 3);
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Empty State for Stories
  Widget _buildEmptyStoriesState(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appTheme.blue_gray_300.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48.h,
            color: appTheme.blue_gray_300,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Public Stories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: appTheme.white_A700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _userId == null
                ? 'Share your first memory to get started'
                : 'This user hasn\'t shared any public stories yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: appTheme.blue_gray_300,
            ),
          ),
        ],
      ),
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

  /// Navigate to story viewer when story is tapped
  void onTapStoryCard(BuildContext context, int index) {
    // Get all story items from the current model
    final storyItems = ref
            .read(userProfileScreenTwoNotifier)
            .userProfileScreenTwoModel
            ?.storyItems ??
        [];

    // Ensure we have stories and valid index
    if (storyItems.isEmpty || index >= storyItems.length) {
      print('⚠️ WARNING: No stories available or invalid index for navigation');
      return;
    }

    // Extract all story IDs from story items
    final storyIds = storyItems
        .where((item) => item.storyId != null && item.storyId!.isNotEmpty)
        .map((item) => item.storyId!)
        .toList();

    // Get the clicked story ID
    final clickedStoryId = storyItems[index].storyId;

    if (clickedStoryId == null || clickedStoryId.isEmpty) {
      print('⚠️ WARNING: Clicked story has no ID - cannot navigate');
      return;
    }

    if (storyIds.isEmpty) {
      print('⚠️ WARNING: No valid story IDs found in user profile');
      return;
    }

    // Create FeedStoryContext with all user stories for cycling
    final feedContext = FeedStoryContext(
      feedType: 'user_profile',
      storyIds: storyIds,
      initialStoryId: clickedStoryId,
    );

    print(
        '🚀 DEBUG: Navigating to story viewer with ${storyIds.length} stories');
    print('   Initial story ID: $clickedStoryId');
    print('   Story index: $index');

    // Navigate to story viewer with complete story array
    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: feedContext,
    );
  }
}
