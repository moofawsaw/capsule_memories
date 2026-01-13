import '../../core/app_export.dart';
import '../../services/avatar_state_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_profile_header.dart';
import '../../widgets/custom_stat_card.dart';
import '../../widgets/custom_story_card.dart';
import '../../widgets/custom_story_skeleton.dart';
import 'notifier/user_profile_screen_two_notifier.dart';
import '../../core/models/feed_story_context.dart';

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
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _userId = args?['userId'] as String?;

      ref
          .read(userProfileScreenTwoNotifier.notifier)
          .initialize(userId: _userId);

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

        final avatarState = ref.watch(avatarStateProvider);

        return Stack(
          children: [
            GestureDetector(
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
                    avatarImagePath:
                    (isCurrentUser ? avatarState.avatarUrl : null) ??
                        model?.avatarImagePath ??
                        ImageConstant.imgEllipse896x96,
                    userName: model?.userName ?? 'Loading...',
                    // ✅ Do NOT show anything for non-current users
                    //    (CustomProfileHeader will hide the row if empty)
                    email: isCurrentUser ? (model?.email ?? '') : '',
                    onEditTap: isCurrentUser
                        ? () {
                      onTapEditProfile(context);
                    }
                        : null,
                    allowUsernameEdit: isCurrentUser,
                    onUserNameChanged: isCurrentUser
                        ? (newUsername) {
                      ref
                          .read(userProfileScreenTwoNotifier.notifier)
                          .updateUsername(newUsername);
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
            ),
            if (!isCurrentUser)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    final notifier =
                    ref.read(userProfileScreenTwoNotifier.notifier);
                    _showBlockConfirmationDialog(context, state.isBlocked, () {
                      notifier.toggleBlock();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: state.isBlocked
                          ? appTheme.gray_900_01
                          : appTheme.red_500.withAlpha(26),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: state.isBlocked
                            ? appTheme.blue_gray_300
                            : appTheme.red_500,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      state.isBlocked ? Icons.lock_open : Icons.block,
                      color: state.isBlocked
                          ? appTheme.blue_gray_300
                          : appTheme.red_500,
                      size: 20.0,
                    ),
                  ),
                ),
              ),
          ],
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
              count: model?.followersCount ?? '0',
              label: 'followers',
            ),
            SizedBox(width: 12.h),
            CustomStatCard(
              count: model?.followingCount ?? '0',
              label: 'following',
            ),
          ],
        );
      },
    );
  }

  /// Action Buttons Section (Follow, Add Friend)
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
                leftIcon: state.isFollowing ? Icons.person_remove : Icons.person_add,
                buttonStyle: state.isFollowing
                    ? CustomButtonStyle.fillPrimary
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
                    ? 'Unfriend'
                    : state.hasPendingFriendRequest
                    ? 'Pending'
                    : 'Add Friend',
                leftIcon: state.isFriend
                    ? Icons.person_remove_alt_1
                    : state.hasPendingFriendRequest
                    ? Icons.schedule
                    : Icons.group_add,
                buttonStyle: state.hasPendingFriendRequest
                    ? CustomButtonStyle.fillGray
                    : CustomButtonStyle.fillDeepPurpleA,
                onPressed: state.hasPendingFriendRequest
                    ? null
                    : () {
                  if (state.isFriend) {
                    _showUnfriendConfirmationDialog(context, notifier.unfriendUser);
                  } else {
                    notifier.sendFriendRequest();
                  }
                },
              ),

            ),

          ],
        );
      },
    );
  }

  /// Stories Grid Section (uses CustomStoryCard built-in delete overlay)
  Widget _buildStoriesGrid(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final stories = state.userProfileScreenTwoModel?.storyItems ?? [];

        final isCurrentUserProfile = _userId == null;

        if (state.isLoadingStories) {
          return GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 1.h,
              mainAxisSpacing: 1.h,
              childAspectRatio: 0.45,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              return CustomStorySkeleton();
            },
          );
        }

        if (stories.isEmpty) {
          return _buildEmptyStoriesState(context);
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1.h,
            mainAxisSpacing: 1.h,
            childAspectRatio: 0.65,
          ),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];

            final storyId = (story.storyId ?? '').toString();

            return CustomStoryCard(
              userName: story.userName ?? 'User',
              userAvatar: story.userAvatar ?? ImageConstant.imgEllipse896x96,
              backgroundImage: story.backgroundImage ?? ImageConstant.imgImg,
              categoryText: story.categoryText ?? 'Memory',
              categoryIcon: story.categoryIcon ?? ImageConstant.imgVector,
              timestamp: story.timestamp ?? 'Just now',
              onTap: () {
                onTapStoryCard(context, index);
              },

              // ✅ only show delete on YOUR profile + only if ID exists
              showDelete:
              isCurrentUserProfile && storyId.isNotEmpty ? true : false,
              onDelete: (isCurrentUserProfile && storyId.isNotEmpty)
                  ? () => _confirmDeleteStory(context, storyId)
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteStory(BuildContext context, String storyId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: appTheme.gray_900_02,
          title: Text(
            'Delete story?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          content: Text(
            'This can’t be undone.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: appTheme.red_500),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // ✅ Use the notifier method we added: deleteStoryFromProfile(storyId)
    final notifier = ref.read(userProfileScreenTwoNotifier.notifier);
    final success = await notifier.deleteStoryFromProfile(storyId);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete story')),
      );
    }
  }

  /// Empty State for Stories
  Widget _buildEmptyStoriesState(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(12),
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
    final storyItems = ref
        .read(userProfileScreenTwoNotifier)
        .userProfileScreenTwoModel
        ?.storyItems ??
        [];

    if (storyItems.isEmpty || index < 0 || index >= storyItems.length) {
      print('⚠️ WARNING: No stories available or invalid index for navigation');
      return;
    }

    // ✅ Force correct type: List<String>
    final List<String> storyIds = storyItems
        .where((item) => (item.storyId ?? '').isNotEmpty)
        .map((item) => item.storyId!)
        .toList();

    final clickedStoryId = storyItems[index].storyId;

    if (clickedStoryId == null || clickedStoryId.isEmpty) {
      print('⚠️ WARNING: Clicked story has no ID - cannot navigate');
      return;
    }

    if (storyIds.isEmpty) {
      print('⚠️ WARNING: No valid story IDs found in user profile');
      return;
    }

    final feedContext = FeedStoryContext(
      feedType: 'user_profile',
      storyIds: storyIds,
      initialStoryId: clickedStoryId,
    );

    print('🚀 DEBUG: Navigating to story viewer with ${storyIds.length} stories');
    print('   Initial story ID: $clickedStoryId');
    print('   Story index: $index');

    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: feedContext,
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

  void _showUnfriendConfirmationDialog(
      BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appTheme.blue_gray_900_02,
          title: Text(
            'Unfriend User?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          content: Text(
            'This will remove your friendship connection. You can send a friend request again later if you change your mind.',
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
                'Unfriend',
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
}
