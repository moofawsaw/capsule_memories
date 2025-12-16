import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_profile_display.dart';
import '../../widgets/custom_stat_card.dart';
import 'notifier/user_profile_notifier.dart';
import 'widgets/story_grid_item.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  UserProfileScreen({Key? key}) : super(key: key);

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        appBar: _buildAppBar(context),
        body: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 24.h),
              child: Column(
                spacing: 40.h,
                children: [
                  _buildProfileSection(context),
                  _buildStoriesSection(context),
                ],
              ),
            ),
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
      onIconButtonTap: () {
        // Handle icon button tap
      },
      actionIcons: [
        ImageConstant.imgIconGray50,
        ImageConstant.imgIconGray5032x32
      ],
      showProfileImage: true,
      profileImagePath: ImageConstant.imgEllipse8DeepOrange100,
      isProfileCircular: true,
      onProfileTap: () {
        // Handle profile tap
      },
      customHeight: 99.h,
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
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: appTheme.deep_purple_A100,
                  borderRadius: BorderRadius.circular(6.h),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8.h,
                  children: [
                    Text(
                      'follow',
                      style: TextStyleHelper.instance.body14BoldPlusJakartaSans
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
            SizedBox(width: 8.h),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: appTheme.deep_purple_A100,
                  borderRadius: BorderRadius.circular(6.h),
                ),
                padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8.h,
                  children: [
                    Text(
                      'add friend',
                      style: TextStyleHelper.instance.body14BoldPlusJakartaSans
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
                      onTap: () => onTapStoryItem(context, 1),
                    ),
                  ),
                  SizedBox(width: 1.h),
                  Expanded(
                    child: StoryGridItem(
                      model: state.userProfileModel?.storyItems?[2],
                      onTap: () => onTapStoryItem(context, 2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              StoryGridItem(
                model: state.userProfileModel?.storyItems?[3],
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
    NavigatorService.pushNamed(AppRoutes.videoCallScreen);
  }

  void onTapNotification(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }
}
