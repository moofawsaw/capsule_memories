import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/standard_title_bar.dart';
import './models/followers_management_model.dart';
import 'notifier/followers_management_notifier.dart';

class FollowersManagementScreen extends ConsumerStatefulWidget {
  FollowersManagementScreen({Key? key}) : super(key: key);

  @override
  FollowersManagementScreenState createState() =>
      FollowersManagementScreenState();
}

class FollowersManagementScreenState
    extends ConsumerState<FollowersManagementScreen> {
  late final ProviderSubscription<FollowersManagementState>
      _followBackToastSub;

  @override
  void initState() {
    super.initState();

    _followBackToastSub = ref.listenManual<FollowersManagementState>(
      followersManagementNotifier,
      (previous, current) {
        final prev = previous?.didFollowBack ?? false;
        final next = current.didFollowBack ?? false;
        if (!prev && next) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Followed back'),
              backgroundColor: appTheme.deep_purple_A100,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _followBackToastSub.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(followersManagementNotifier.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: Container(
        width: double.maxFinite,
        padding: EdgeInsets.only(
          top: 24.h,
          left: 16.h,
          right: 16.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSection(context),
            SizedBox(height: 20.h),
            _buildFollowersList(context),
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildTabSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(followersManagementNotifier);
        final followersCount =
            state.followersManagementModel?.followersList?.length ?? 0;

        return StandardTitleBar(
          leadingIcon: Icons.people_alt_rounded,
          title: 'Followers ($followersCount)',
          trailing: GestureDetector(
            onTap: () => onTapFollowing(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
              decoration: BoxDecoration(
                color: appTheme.color41C124,
                border: Border.all(
                  color: appTheme.blue_gray_900,
                  width: 1.h,
                ),
                borderRadius: BorderRadius.circular(22.h),
              ),
              child: Text(
                'Following',
                style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50, height: 1.31),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildFollowersList(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.h),
        child: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(followersManagementNotifier);

            final followersList =
                state.followersManagementModel?.followersList ?? [];

            return RefreshIndicator(
              color: appTheme.deep_purple_A100,
              backgroundColor: appTheme.gray_900_01,
              displacement: 30,
              onRefresh: _onRefresh,
              child: (state.isLoading ?? false)
                  ? ListView(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(height: 60.h),
                        Center(
                          child: CircularProgressIndicator(
                            color: appTheme.deep_purple_A100,
                          ),
                        ),
                      ],
                    )
                  : followersList.isEmpty
                      ? ListView(
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            SizedBox(height: 60.h),
                            Center(
                              child: Text(
                                'No followers yet',
                                style: TextStyleHelper
                                    .instance.body14RegularPlusJakartaSans
                                    .copyWith(color: appTheme.blue_gray_300),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          separatorBuilder: (context, index) {
                            return SizedBox(height: 20.h);
                          },
                          itemCount: followersList.length,
                          itemBuilder: (context, index) {
                            final follower = followersList[index];
                            return _buildFollowerItem(context, follower, index);
                          },
                        ),
            );
          },
        ),
      ),
    );
  }

  /// Follower Item Widget
  Widget _buildFollowerItem(
      BuildContext context, FollowerItemModel? follower, int index) {
    if (follower == null) return SizedBox.shrink();

    final isFollowingBack = follower.isFollowingBack ?? false;

    return GestureDetector(
      onTap: () => onTapFollower(context, follower),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48.h,
            child: CustomImageView(
              imagePath: follower.profileImage,
              height: 48.h,
              width: 48.h,
              fit: BoxFit.cover,
              isCircular: true,
              enableCategoryIconResolution: false,
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  follower.name ?? '',
                  style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                Text(
                  follower.followersCount ?? '',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
              ],
            ),
          ),
          CustomButton(
            text: isFollowingBack ? 'Following' : 'Follow back',
            width: null,
            size: CustomButtonSize.compact,
            buttonStyle: isFollowingBack
                ? CustomButtonStyle.fillPrimary
                : CustomButtonStyle.outlinePrimary,
            buttonTextStyle: isFollowingBack
                ? CustomButtonTextStyle.bodySmallPrimary
                : CustomButtonTextStyle.bodySmall,
            isDisabled: isFollowingBack,
            onPressed: isFollowingBack ? null : () => onTapFollowBack(follower),
          ),
        ],
      ),
    );
  }

  /// Navigates to create content screen
  void onTapCreateContent(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appPost);
  }

  /// Navigates to notifications screen
  void onTapNotifications(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }

  /// Navigates to profile screen
  void onTapProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  /// Navigates to following screen
  void onTapFollowing(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appFollowing);
  }

  /// Navigates to follower profile
  void onTapFollower(BuildContext context, FollowerItemModel follower) {
    if (follower.id == null || follower.id!.isEmpty) return;

    NavigatorService.pushNamed(
      AppRoutes.appProfileUser,
      arguments: {'userId': follower.id},
    );
  }

  void onTapFollowBack(FollowerItemModel follower) {
    final id = (follower.id ?? '').trim();
    if (id.isEmpty) return;
    ref.read(followersManagementNotifier.notifier).followBack(id);
  }
}
