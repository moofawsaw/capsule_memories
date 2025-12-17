import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import 'models/followers_management_model.dart';
import 'notifier/followers_management_notifier.dart';

class FollowersManagementScreen extends ConsumerStatefulWidget {
  FollowersManagementScreen({Key? key}) : super(key: key);

  @override
  FollowersManagementScreenState createState() =>
      FollowersManagementScreenState();
}

class FollowersManagementScreenState
    extends ConsumerState<FollowersManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        appBar: _buildAppBar(context),
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
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      layoutType: CustomAppBarLayoutType.logoWithActions,
      logoImagePath: ImageConstant.imgLogo,
      showIconButton: true,
      iconButtonImagePath: ImageConstant.imgFrame19,
      iconButtonBackgroundColor: appTheme.color3BD81E,
      actionIcons: [
        ImageConstant.imgIconGray50,
        ImageConstant.imgIconGray5032x32,
      ],
      showProfileImage: true,
      profileImagePath: ImageConstant.imgEllipse8,
      isProfileCircular: true,
      customHeight: 101.h,
    );
  }

  /// Section Widget
  Widget _buildTabSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(followersManagementNotifier);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgIconDeepPurpleA10026x26,
              height: 26.h,
              width: 26.h,
              margin: EdgeInsets.only(top: 2.h),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 6.h,
                top: 4.h,
              ),
              child: Text(
                'Followers (${state.followersManagementModel?.followersList?.length ?? 0})',
                style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans,
              ),
            ),
            Spacer(),
            CustomButton(
              text: 'Following (3)',
              buttonStyle: CustomButtonStyle
                  .fillDark, // Modified: Fixed CustomButtonStyle type
              buttonTextStyle: CustomButtonTextStyle
                  .bodyMedium, // Modified: Fixed CustomButtonTextStyle type
              padding: EdgeInsets.symmetric(
                horizontal: 14.h,
                vertical: 10.h,
              ),
              onPressed: () => onTapFollowing(context),
            ),
          ],
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

            ref.listen(
              followersManagementNotifier,
              (previous, current) {
                if (current.isBlocked ?? false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User blocked successfully'),
                      backgroundColor: appTheme.deep_purple_A100,
                    ),
                  );
                }
              },
            );

            if (state.isLoading ?? false) {
              return Center(child: CircularProgressIndicator());
            }

            return ListView.separated(
              padding: EdgeInsets.zero,
              physics: BouncingScrollPhysics(),
              shrinkWrap: true,
              separatorBuilder: (context, index) {
                return SizedBox(height: 20.h);
              },
              itemCount:
                  state.followersManagementModel?.followersList?.length ?? 0,
              itemBuilder: (context, index) {
                final follower =
                    state.followersManagementModel?.followersList?[index];
                return _buildFollowerItem(context, follower, index);
              },
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

    return GestureDetector(
      onTap: () => onTapFollower(context, follower),
      child: Row(
        children: [
          CustomImageView(
            imagePath: follower.profileImage,
            height: 52.h,
            width: 52.h,
            radius: BorderRadius.circular(26.h),
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
            text: 'block',
            width: null,
            buttonStyle: CustomButtonStyle
                .fillPrimary, // Modified: Fixed CustomButtonStyle type
            buttonTextStyle: CustomButtonTextStyle
                .bodySmall, // Modified: Fixed CustomButtonTextStyle type
            padding: EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 12.h,
            ),
            onPressed: () => onTapBlock(context, follower, index),
          ),
        ],
      ),
    );
  }

  /// Navigates to create content screen
  void onTapCreateContent(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.postScreen);
  }

  /// Navigates to notifications screen
  void onTapNotifications(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }

  /// Navigates to profile screen
  void onTapProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.profileScreen);
  }

  /// Navigates to following screen
  void onTapFollowing(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.followingScreen);
  }

  /// Navigates to follower profile
  void onTapFollower(BuildContext context, FollowerItemModel follower) {
    NavigatorService.pushNamed(AppRoutes.profileScreen);
  }

  /// Blocks the selected follower
  void onTapBlock(BuildContext context, FollowerItemModel follower, int index) {
    ref.read(followersManagementNotifier.notifier).blockFollower(index);
  }
}