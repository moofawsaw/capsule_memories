import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_export.dart';
import '../../core/utils/image_constant.dart';
import '../../core/utils/navigator_service.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_chip.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_fab.dart';
import '../../widgets/custom_feature_card.dart';
import '../../widgets/custom_friend_item.dart';
import '../../widgets/custom_friend_request_card.dart';
import '../../widgets/custom_group_card.dart';
import '../../widgets/custom_group_invitation_card.dart';
import '../../widgets/custom_happening_now_section.dart';
import '../../widgets/custom_header_row.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_info_row.dart';
import '../../widgets/custom_memory_card.dart';
import '../../widgets/custom_menu_item.dart';
import '../../widgets/custom_music_list.dart';
import '../../widgets/custom_navigation_drawer.dart';
import '../../widgets/custom_notification_card.dart';
import '../../widgets/custom_notification_item.dart';
import '../../widgets/custom_notification_settings.dart';
import '../../widgets/custom_profile_display.dart';
import '../../widgets/custom_profile_header.dart';
import '../../widgets/custom_public_memories.dart';
import '../../widgets/custom_qr_info_card.dart';
import '../../widgets/custom_radio_group.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/custom_section_header.dart';
import '../../widgets/custom_settings_row.dart';
import '../../widgets/custom_social_post_card.dart';
import '../../widgets/custom_stat_card.dart';
import '../../widgets/custom_story_card.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/custom_story_progress.dart';
import '../../widgets/custom_story_viewer.dart';
import '../../widgets/custom_switch.dart';
import '../../widgets/custom_user_card.dart';
import '../../widgets/custom_user_info_row.dart';
import '../../widgets/custom_user_list.dart';
import '../../widgets/custom_user_list_item.dart';
import '../../widgets/custom_user_profile.dart';
import '../../widgets/custom_user_profile_item.dart';
import '../../widgets/custom_user_status_row.dart';
import 'models/user_menu_model.dart';
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
                child: SingleChildScrollView(
                    child: Container(
                        width: double.infinity,
                        height: 848.h,
                        child:
                            Stack(alignment: Alignment.centerLeft, children: [
                          Container(
                              width: 310.h,
                              height: double.infinity,
                              decoration:
                                  BoxDecoration(color: appTheme.gray_900_02)),
                          Container(
                              width: double.infinity,
                              height: double.infinity,
                              padding: EdgeInsets.fromLTRB(12.h, 28.h, 12.h, 0),
                              decoration:
                                  BoxDecoration(color: appTheme.color5B0000),
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
                                    SizedBox(height: 80.h),
                                    _buildActionButtons(context),
                                    SizedBox(height: 34.h),
                                    _buildSignOutSection(context),
                                  ])),
                        ]))))));
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
    final navigationItems = [
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
    return Column(children: [
      CustomButton(
          text: 'Share the App',
          width: double.infinity,
          leftIcon: ImageConstant.imgIconWhiteA70020x20,
          onPressed: () => onTapShareApp(context),
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle.bodyMedium),
      SizedBox(height: 8.h),
      CustomButton(
          text: 'Suggest a Feature',
          width: double.infinity,
          leftIcon: ImageConstant.imgIconDeepPurpleA10020x20,
          onPressed: () => onTapSuggestFeature(context),
          buttonStyle: CustomButtonStyle.outlineDark,
          buttonTextStyle: CustomButtonTextStyle.bodyMediumPrimary),
    ]);
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
    NavigatorService.pushNamed(AppRoutes.userProfileScreenTwo);
  }

  /// Navigates to memories dashboard
  void onTapMemories(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.memoriesDashboardScreen);
  }

  /// Navigates to groups management
  void onTapGroups(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.groupsManagementScreen);
  }

  /// Navigates to friends management
  void onTapFriends(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.friendsManagementScreen);
  }

  /// Navigates to following list
  void onTapFollowing(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.followingListScreen);
  }

  /// Navigates to notification settings
  void onTapSettings(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationSettingsScreen);
  }

  /// Closes the menu drawer
  void onTapCloseButton(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles share app functionality
  void onTapShareApp(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appDownloadScreen);
  }

  /// Navigates to feature request screen
  void onTapSuggestFeature(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.featureRequestScreen);
  }

  /// Handles sign out functionality
  void onTapSignOut(BuildContext context) {
    ref.read(userMenuNotifier.notifier).signOut();
    NavigatorService.pushNamedAndRemoveUntil(AppRoutes.loginScreen);
  }
}
