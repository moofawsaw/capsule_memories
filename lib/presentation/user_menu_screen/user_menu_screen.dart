import '../../core/app_export.dart';
import '../../services/avatar_state_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_menu_item.dart';
import '../../widgets/custom_navigation_drawer.dart';
import '../../widgets/custom_settings_row.dart';
import 'notifier/user_menu_notifier.dart';

class UserMenuScreen extends ConsumerStatefulWidget {
  UserMenuScreen({Key? key}) : super(key: key);

  @override
  UserMenuScreenState createState() => UserMenuScreenState();
}

class UserMenuScreenState extends ConsumerState<UserMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 310.h,
            height: double.infinity,
            decoration: BoxDecoration(color: appTheme.color5B0000),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  width: 310.h,
                  height: double.infinity,
                  decoration: BoxDecoration(color: appTheme.gray_900_02),
                ),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Profile section with authenticated user info and close button
  Widget _buildProfileSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(userMenuNotifier);
      final avatarState = ref.watch(avatarStateProvider);
      final userModel = state.userMenuModel;

      // Use global avatar state if available, otherwise fallback to local state
      final avatarUrl = (avatarState.avatarUrl?.isNotEmpty ?? false)
          ? avatarState.avatarUrl
          : (userModel?.avatarImagePath?.isNotEmpty ?? false)
              ? userModel?.avatarImagePath
              : null;

      // Generate avatar letter from email if no avatar URL
      final email = userModel?.userEmail ?? '';
      final avatarLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U';

      // Determine if we should show letter avatar (no valid URL)
      final showLetterAvatar = avatarUrl == null || avatarUrl.isEmpty;

      return Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Row(children: [
            Expanded(
                flex: 7,
                child: GestureDetector(
                  onTap: () => onTapProfile(context),
                  child: Row(
                    children: [
                      // Avatar - show letter or image
                      Container(
                        width: 52.h,
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: showLetterAvatar
                              ? appTheme.deep_purple_A100
                              : null,
                          shape: BoxShape.circle,
                          image: !showLetterAvatar
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: showLetterAvatar
                            ? Center(
                                child: Text(
                                  avatarLetter,
                                  style: TextStyle(
                                    color: appTheme.white_A700,
                                    fontSize: 24.h,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 12.h),
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userModel?.userName ?? 'User',
                              style: TextStyle(
                                color: appTheme.white_A700,
                                fontSize: 16.h,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              userModel?.userEmail ?? '',
                              style: TextStyle(
                                color: appTheme.gray_50,
                                fontSize: 14.h,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            GestureDetector(
                onTap: () => onTapCloseButton(context),
                child: CustomImageView(
                    imagePath: ImageConstant.imgFrame19,
                    height: 26.h,
                    width: 26.h)),
          ]));
    });
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
    NavigatorService.pushNamed(AppRoutes.appProfileUser);
  }

  /// Navigates to memories dashboard
  void onTapMemories(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appMemories);
  }

  /// Navigates to groups management
  void onTapGroups(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appGroups);
  }

  /// Navigates to friends management
  void onTapFriends(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appFriends);
  }

  /// Navigates to following list
  void onTapFollowing(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appFollowing);
  }

  /// Navigates to notification settings
  void onTapSettings(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appSettings);
  }

  /// Closes the menu drawer
  void onTapCloseButton(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles share app functionality
  void onTapShareApp(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appBsDownload);
  }

  /// Navigates to feature request screen
  void onTapSuggestFeature(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appFeedback);
  }

  /// Handles sign out functionality with database integration
  void onTapSignOut(BuildContext context) async {
    await ref.read(userMenuNotifier.notifier).signOut();
    NavigatorService.pushNamedAndRemoveUntil(AppRoutes.authLogin);
  }
}
