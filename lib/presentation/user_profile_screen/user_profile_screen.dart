import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_profile_display.dart';
import '../../widgets/custom_stat_card.dart';
import '../user_menu_screen/user_menu_screen.dart';
import './widgets/story_grid_item.dart';
import 'notifier/user_profile_notifier.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  UserProfileScreen({Key? key}) : super(key: key);

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  String? _targetUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extract userId from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    final userId = args is Map ? args['userId'] as String? : null;

    // Initialize profile with target user ID if not already loaded
    if (userId != _targetUserId) {
      _targetUserId = userId;

      // Initialize the notifier with the target user's ID
      Future.microtask(() {
        ref.read(userProfileNotifier.notifier).initialize(userId: userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileNotifier);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(userProfileNotifier.notifier).initialize();
          },
          color: appTheme.deep_purple_A100,
          backgroundColor: appTheme.gray_900_01,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileHeader(context),
                    _buildStatsRow(context),
                    _buildActionButtons(context),
                  ],
                ),
              ),
              _buildStoriesSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildProfileSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileNotifier);

        return Container(
          child: Column(
            spacing: 12.h,
            children: [
              _buildProfileHeader(context),
              _buildStatsRow(context),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  /// Profile Header Widget
  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.h),
      child: Row(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgIcon32x32,
            height: 32.h,
            width: 32.h,
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 32.h),
              child: CustomProfileDisplay(
                imagePath: ImageConstant.imgEllipse864x64,
                name: 'Lucy Ball',
                imageSize: 64.h,
                textStyle:
                    TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans,
              ),
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgIcon6,
            height: 32.h,
            width: 32.h,
          ),
        ],
      ),
    );
  }

  /// Stats Row Widget
  Widget _buildStatsRow(BuildContext context) {
    return Row(
      spacing: 12.h,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomStatCard(
          count: '29',
          label: 'followers',
        ),
        CustomStatCard(
          count: '6',
          label: 'following',
        ),
      ],
    );
  }

  /// Action Buttons Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileNotifier);
        final notifier = ref.read(userProfileNotifier.notifier);
        final isFollowing = state.isFollowing ?? false;
        final isFriend = state.isFriend ?? false;

        // Get target user ID from route arguments
        final args = ModalRoute.of(context)?.settings.arguments;
        final targetUserId = args is Map ? args['userId'] as String? : null;

        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (targetUserId != null) {
                    notifier.onFollowButtonPressed(targetUserId);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isFollowing
                        ? appTheme.gray_50
                        : appTheme.deep_purple_A100,
                    borderRadius: BorderRadius.circular(6.h),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.h, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8.h,
                    children: [
                      Text(
                        isFollowing ? 'following' : 'follow',
                        style: TextStyleHelper
                            .instance.body14BoldPlusJakartaSans
                            .copyWith(
                                color: isFollowing
                                    ? appTheme.gray_900_02
                                    : appTheme.white_A700),
                      ),
                      CustomImageView(
                        imagePath: ImageConstant.imgIconWhiteA70018x18,
                        height: 18.h,
                        width: 18.h,
                        color: isFollowing
                            ? appTheme.gray_900_02
                            : appTheme.white_A700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (targetUserId == null) return;

                  if (isFriend) {
                    // Show confirmation dialog for friend removal
                    _showRemoveFriendConfirmation(context, targetUserId);
                  } else {
                    // Send friend request
                    notifier.onAddFriendButtonPressed(targetUserId);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isFriend ? appTheme.red_500 : appTheme.deep_purple_A100,
                    borderRadius: BorderRadius.circular(6.h),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 6.h, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8.h,
                    children: [
                      Text(
                        isFriend ? 'remove friend' : 'add friend',
                        style: TextStyleHelper
                            .instance.body14BoldPlusJakartaSans
                            .copyWith(color: appTheme.white_A700),
                      ),
                      CustomImageView(
                        imagePath: ImageConstant.imgIconWhiteA70018x18,
                        height: 18.h,
                        width: 18.h,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: appTheme.red_500,
                  borderRadius: BorderRadius.circular(6.h),
                ),
                padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8.h,
                  children: [
                    Text(
                      'block',
                      style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                          .copyWith(color: appTheme.white_A700),
                    ),
                    CustomImageView(
                      imagePath: ImageConstant.imgIcon18x18,
                      height: 18.h,
                      width: 18.h,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog for friend removal
  void _showRemoveFriendConfirmation(
      BuildContext context, String targetUserId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: appTheme.gray_900_02,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        title: Text(
          'Remove Friend',
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans
              .copyWith(color: appTheme.white_A700),
        ),
        content: Text(
          'Are you sure you want to remove this person from your friends?',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // Remove friend
              final notifier = ref.read(userProfileNotifier.notifier);
              final success =
                  await notifier.onRemoveFriendButtonPressed(targetUserId);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Friend removed successfully'),
                    backgroundColor: appTheme.deep_purple_A100,
                  ),
                );
              }
            },
            child: Text(
              'Remove',
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(color: appTheme.red_500),
            ),
          ),
        ],
      ),
    );
  }

  /// Stories Section Widget
  Widget _buildStoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileNotifier);

        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StoryGridItem(
                      model: state.userProfileModel?.storyItems?[0],
                      onTap: () => onTapStoryItem(context, 0),
                    ),
                  ),
                  SizedBox(width: 1.h),
                  Expanded(
                    child: StoryGridItem(
                      model: state.userProfileModel?.storyItems?[1],
                      height: 160.h, // <-- set your desired height
                      onTap: () => onTapStoryItem(context, 1),
                    ),
                  ),
                  SizedBox(width: 1.h),
                  Expanded(
                    child: StoryGridItem(
                      model: state.userProfileModel?.storyItems?[2],
                      height: 160.h, // <-- set your desired height
                      onTap: () => onTapStoryItem(context, 2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              StoryGridItem(
                model: state.userProfileModel?.storyItems?[3],
                height: 160.h, // <-- set your desired height
                onTap: () => onTapStoryItem(context, 3),
                width: 116.h,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigation Functions
  void onTapStoryItem(BuildContext context, int index) {
    NavigatorService.pushNamed(AppRoutes.appVideoCall);
  }

  void onTapNotification(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }

  /// Opens user menu as a side drawer
  void _openUserMenuDrawer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            UserMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false,
      ),
    );
  }
}
