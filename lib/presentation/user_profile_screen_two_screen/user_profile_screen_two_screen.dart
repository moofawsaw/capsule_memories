import '../../core/app_export.dart';
import '../../services/avatar_state_service.dart';
import '../../widgets/custom_app_bar.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProfileScreenTwoNotifier.notifier).initialize();

      // Load avatar into global state for app-wide access
      ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        appBar: _buildAppBar(context),
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

  /// AppBar Section
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      logoImagePath: ImageConstant.imgLogo,
      showIconButton: true,
      iconButtonImagePath: ImageConstant.imgFrame19,
      iconButtonBackgroundColor: appTheme.color3BD81E,
      actionIcons: [
        ImageConstant.imgIconGray50,
        ImageConstant.imgIconGray5032x32
      ],
      showProfileImage: true,
    );
  }

  /// Profile Header Section
  Widget _buildProfileHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final model = state.userProfileScreenTwoModel;

        // 🔥 Watch global avatar state for real-time updates
        final avatarState = ref.watch(avatarStateProvider);

        return GestureDetector(
          onTap: () {
            ref.read(userProfileScreenTwoNotifier.notifier).uploadAvatar();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomProfileHeader(
                // Use avatar from global state if available, otherwise use local model
                avatarImagePath: avatarState.avatarUrl ??
                    model?.avatarImagePath ??
                    ImageConstant.imgEllipse896x96,
                userName: model?.userName ?? 'Loading...',
                email: model?.email ?? 'Fetching data...',
                onEditTap: () {
                  onTapEditProfile(context);
                },
                margin: EdgeInsets.symmetric(horizontal: 68.h),
              ),
              if (state.isUploading)
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