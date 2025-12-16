import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_icon_button.dart';
import 'models/following_list_model.dart';
import 'notifier/following_list_notifier.dart';
import 'widgets/following_user_item_widget.dart';

class FollowingListScreen extends ConsumerStatefulWidget {
  FollowingListScreen({Key? key}) : super(key: key);

  @override
  FollowingListScreenState createState() => FollowingListScreenState();
}

class FollowingListScreenState extends ConsumerState<FollowingListScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          child: Column(
            children: [
              SizedBox(height: 24.h),
              _buildAppBarSection(context),
              SizedBox(height: 24.h),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Column(
                    spacing: 20.h,
                    children: [
                      _buildTabSection(context),
                      Expanded(child: _buildFollowingList(context))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget - App Bar
  Widget _buildAppBarSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.fromLTRB(22.h, 26.h, 22.h, 24.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appTheme.blue_gray_900,
            width: 1.h,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            child: CustomImageView(
              imagePath: ImageConstant.imgLogo,
              height: 26.h,
              width: 130.h,
            ),
          ),
          CustomIconButton(
            iconPath: ImageConstant.imgFrame19,
            backgroundColor: appTheme.color3BD81E,
            borderRadius: 22.h,
            height: 46.h,
            width: 46.h,
            padding: EdgeInsets.all(6.h),
            margin: EdgeInsets.only(left: 18.h),
            onTap: () {
              onTapCreateContent(context);
            },
          ),
          GestureDetector(
            onTap: () {
              onTapGalleryIcon(context);
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(18.h, 0, 0, 8.h),
              child: CustomImageView(
                imagePath: ImageConstant.imgIconGray50,
                height: 32.h,
                width: 32.h,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              onTapNotificationIcon(context);
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(6.h, 0, 0, 8.h),
              child: CustomImageView(
                imagePath: ImageConstant.imgIconGray5032x32,
                height: 32.h,
                width: 32.h,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              onTapProfileAvatar(context);
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(8.h, 22.h, 0, 0),
              child: CustomImageView(
                imagePath: ImageConstant.imgEllipse8,
                height: 50.h,
                width: 50.h,
                radius: BorderRadius.circular(24.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget - Tab Section
  Widget _buildTabSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(followingListNotifier);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 2.h),
              child: CustomImageView(
                imagePath: ImageConstant.imgIcon11,
                height: 26.h,
                width: 26.h,
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(6.h, 4.h, 0, 0),
              child: Text(
                'Following (3)',
                style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans
                    .copyWith(height: 1.3),
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                onTapFollowersTab(context);
              },
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
                  'Followers (21)',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50, height: 1.31),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Section Widget - Following List
  Widget _buildFollowingList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(followingListNotifier);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8.h),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: BouncingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return SizedBox(height: 20.h);
            },
            itemCount: state.followingListModel?.followingUsers?.length ?? 0,
            itemBuilder: (context, index) {
              final user = state.followingListModel?.followingUsers?[index];
              return FollowingUserItemWidget(
                user: user,
                onUserTap: () {
                  onTapFollowingUser(context, user);
                },
                onActionTap: () {
                  onTapUserAction(context, user);
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Navigates to create content screen
  void onTapCreateContent(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.createMemoryScreen);
  }

  /// Navigates to gallery screen
  void onTapGalleryIcon(BuildContext context) {
    // Navigate to gallery/media screen
  }

  /// Navigates to notifications screen
  void onTapNotificationIcon(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }

  /// Navigates to profile screen
  void onTapProfileAvatar(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  /// Navigates to followers screen
  void onTapFollowersTab(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.followersManagementScreen);
  }

  /// Navigates to user profile screen
  void onTapFollowingUser(BuildContext context, FollowingUserModel? user) {
    NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  /// Handles user action (more options)
  void onTapUserAction(BuildContext context, FollowingUserModel? user) {
    // Show user options menu or bottom sheet
    ref.read(followingListNotifier.notifier).onUserAction(user);
  }
}
