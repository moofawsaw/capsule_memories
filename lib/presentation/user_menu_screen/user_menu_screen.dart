import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_menu_item.dart';
import '../../widgets/custom_navigation_drawer.dart';
import '../../widgets/custom_settings_row.dart';
import '../../widgets/custom_user_profile.dart';
import 'notifier/user_menu_notifier.dart';

class UserMenuScreen extends ConsumerStatefulWidget {
  UserMenuScreen({Key? key}) : super(key: key);

  @override
  UserMenuScreenState createState() => UserMenuScreenState();
}

class UserMenuScreenState extends ConsumerState<UserMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: appTheme.color5B0000,
            body: Container(
                width: double.maxFinite,
                child: Stack(alignment: Alignment.centerLeft, children: [
                  Container(
                      width: 310.h,
                      height: double.infinity,
                      decoration: BoxDecoration(color: appTheme.gray_900_02)),
                  Container(
                      width: 310.h,
                      padding: EdgeInsets.fromLTRB(12.h, 28.h, 12.h, 16.h),
                      decoration: BoxDecoration(color: appTheme.color5B0000),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileSection(context),
                            SizedBox(height: 30.h),
                            _buildNavigationMenu(context),
                            SizedBox(height: 26.h),
                            _buildDivider(context),
                            SizedBox(height: 20.h),
                            _buildDarkModeSection(context),
                            SizedBox(height: 22.h),
                            _buildBottomDivider(context),
                            Spacer(),
                            _buildActionButtons(context),
                            SizedBox(height: 16.h),
                            _buildSignOutSection(context),
                          ])),
                ]))));
  }

  /// Profile section with user info and close button
  Widget _buildProfileSection(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: Row(children: [
          Expanded(
              flex: 7,
              child: CustomUserProfile(
                  userName: 'Joe Kool',
                  userEmail: 'email112@gmail.com',
                  avatarImagePath: ImageConstant.imgEllipse852x52,
                  onTap: () => onTapProfile(context))),
          GestureDetector(
              onTap: () => onTapCloseButton(context),
              child: CustomImageView(
                  imagePath: ImageConstant.imgFrame19,
                  height: 26.h,
                  width: 26.h)),
        ]));
  }

  /// Main navigation menu items
  Widget _buildNavigationMenu(BuildContext context) {
    final navigationItems = <CustomNavigationDrawerItem>[
      CustomNavigationDrawerItem(
          iconPath: ImageConstant.imgIconGray5024x24,
          label: 'Profile',
          onTap: () => onTapProfile(context)),
      CustomNavigationDrawerItem(
          iconPath: ImageConstant.imgIconGray50,
          label: 'Memories',
          onTap: () => onTapMemories(context)),
      CustomNavigationDrawerItem(
          iconPath: ImageConstant.imgIcon24x24,
          label: 'Groups',
          onTap: () => onTapGroups(context)),
      CustomNavigationDrawerItem(
          iconPath: ImageConstant.imgIcon2,
          label: 'Friends',
          onTap: () => onTapFriends(context)),
      CustomNavigationDrawerItem(
          iconPath: ImageConstant.imgIcon3,
          label: 'Following',
          onTap: () => onTapFollowing(context)),
      CustomNavigationDrawerItem(
          iconPath: ImageConstant.imgIcon4,
          label: 'Settings',
          onTap: () => onTapSettings(context)),
    ];

    return CustomNavigationDrawer(
        menuItems: navigationItems, margin: EdgeInsets.only(left: 12.h));
  }

  /// Divider line
  Widget _buildDivider(BuildContext context) {
    return Container(width: 304.h, height: 1.h, color: appTheme.color41C124);
  }

  /// Dark mode toggle section
  Widget _buildDarkModeSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(userMenuNotifier);

      return CustomSettingsRow(
          iconPath: ImageConstant.imgIcon5,
          // Modified: Added required parameters for CustomSettingsRow
          title: 'Dark mode',
          description: 'Toggle dark mode on or off',
          switchValue: state.userMenuModel?.isDarkModeEnabled ?? true,
          onSwitchChanged: (value) =>
              ref.read(userMenuNotifier.notifier).toggleDarkMode(),
          margin: EdgeInsets.only(right: 12.h, left: 12.h));
    });
  }

  /// Bottom divider line
  Widget _buildBottomDivider(BuildContext context) {
    return Container(width: 304.h, height: 1.h, color: appTheme.color41C124);
  }

  /// Action buttons section
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.h),
        child: Column(children: [
          CustomButton(
              width: double.infinity,
              height: 56.h,
              text: 'Share the App',
              leftIcon: ImageConstant.imgIconWhiteA70020x20,
              onPressed: () => onTapShareApp(context),
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium),
          SizedBox(height: 8.h),
          CustomButton(
              width: double.infinity,
              height: 56.h,
              text: 'Suggest a Feature',
              leftIcon: ImageConstant.imgIconDeepPurpleA10020x20,
              onPressed: () => onTapSuggestFeature(context),
              buttonStyle: CustomButtonStyle.outlineDark,
              buttonTextStyle: CustomButtonTextStyle.bodyMediumPrimary),
        ]));
  }

  /// Sign out section
  Widget _buildSignOutSection(BuildContext context) {
    return CustomMenuItem(
        iconPath: ImageConstant.imgIconRed500,
        title: 'Sign Out',
        onTap: () => onTapSignOut(context),
        margin: EdgeInsets.only(right: 8.h, left: 8.h));
  }

  /// Navigates to user profile screen
  void onTapProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.profileTwoScreen);
  }

  /// Navigates to memories dashboard
  void onTapMemories(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.memoriesScreen);
  }

  /// Navigates to groups management
  void onTapGroups(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.groupsScreen);
  }

  /// Navigates to friends management
  void onTapFriends(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.friendsScreen);
  }

  /// Navigates to following list
  void onTapFollowing(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.followingScreen);
  }

  /// Navigates to notification settings
  void onTapSettings(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.settingsScreen);
  }

  /// Closes the menu drawer
  void onTapCloseButton(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles share app functionality
  void onTapShareApp(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.downloadScreen);
  }

  /// Navigates to feature request screen
  void onTapSuggestFeature(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.feedbackScreen);
  }

  /// Handles sign out functionality
  void onTapSignOut(BuildContext context) {
    ref.read(userMenuNotifier.notifier).signOut();
    NavigatorService.pushNamedAndRemoveUntil(AppRoutes.loginScreen);
  }
}
