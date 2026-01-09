import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../services/avatar_state_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_menu_item.dart';
import '../../widgets/custom_navigation_drawer.dart';
import '../app_download_screen/app_download_screen.dart';
import 'notifier/user_menu_notifier.dart';

class UserMenuScreen extends ConsumerStatefulWidget {
  UserMenuScreen({Key? key}) : super(key: key);

  @override
  UserMenuScreenState createState() => UserMenuScreenState();
}

class UserMenuScreenState extends ConsumerState<UserMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ FIX: Make the overlay explicitly fill the screen so taps always register.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => onTapCloseButton(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withAlpha(128),
            ),
          ),
        ),

        // Menu content - prevent tap propagation
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {}, // Absorb taps on menu to prevent dismissal
            behavior: HitTestBehavior.opaque,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
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
          ),
        ),
      ],
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
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: GestureDetector(
                onTap: () => _handleAvatarTap(context, ref),
                child: Row(
                  children: [
                    // Avatar - show letter or image with loading indicator
                    Stack(
                      children: [
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
                        // Loading overlay
                        if (avatarState.isLoading)
                          Container(
                            width: 52.h,
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(128),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 24.h,
                                height: 24.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    appTheme.white_A700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
              ),
            ),
            GestureDetector(
              onTap: () => onTapCloseButton(context),
              child: Icon(
                Icons.close,
                size: 26,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Handle avatar tap - show image picker and upload
  Future<void> _handleAvatarTap(BuildContext context, WidgetRef ref) async {
    try {
      // Show image picker
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Set loading state
      final avatarNotifier = ref.read(avatarStateProvider.notifier);

      // Read image bytes
      final imageBytes = await image.readAsBytes();

      // Upload to Supabase Storage
      final storagePath = await UserProfileService.instance.uploadAvatar(
        imageBytes,
        image.name,
      );

      if (storagePath == null) {
        _showErrorSnackbar(context, 'Failed to upload image');
        return;
      }

      // Update user profile in database
      final success = await UserProfileService.instance.updateUserProfile(
        avatarUrl: storagePath,
      );

      if (!success) {
        _showErrorSnackbar(context, 'Failed to update profile');
        return;
      }

      // Get signed URL for display
      final signedUrl =
      await UserProfileService.instance.getAvatarUrl(storagePath);

      if (signedUrl != null) {
        // Update global avatar state - this will refresh all widgets showing the avatar
        avatarNotifier.updateAvatar(signedUrl);

        // Refresh local menu state
        await ref.read(userMenuNotifier.notifier).refreshProfile();

        _showSuccessSnackbar(context, 'Profile picture updated successfully');
      }
    } catch (e) {
      debugPrint('❌ Error updating avatar: $e');
      _showErrorSnackbar(
        context,
        'An error occurred while updating profile picture',
      );
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Main navigation menu items
  Widget _buildNavigationMenu(BuildContext context) {
    final navigationItems = <CustomNavigationDrawerItem>[
      CustomNavigationDrawerItem(
        icon: Icons.person_outline,
        label: 'Profile',
        onTap: () => onTapProfile(context),
      ),
      CustomNavigationDrawerItem(
        icon: Icons.photo_outlined,
        label: 'Memories',
        onTap: () => onTapMemories(context),
      ),
      CustomNavigationDrawerItem(
        icon: Icons.group_outlined,
        label: 'Groups',
        onTap: () => onTapGroups(context),
      ),
      CustomNavigationDrawerItem(
        icon: Icons.people_outline,
        label: 'Friends',
        onTap: () => onTapFriends(context),
      ),
      CustomNavigationDrawerItem(
        icon: Icons.favorite_border,
        label: 'Following',
        onTap: () => onTapFollowing(context),
      ),
      CustomNavigationDrawerItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => onTapSettings(context),
      ),
    ];

    return CustomNavigationDrawer(
      menuItems: navigationItems,
      margin: EdgeInsets.only(left: 12.h),
    );
  }

  /// Divider line
  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 304.h,
      height: 1.h,
      color: appTheme.color41C124,
    );
  }

  /// Action buttons section
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.h),
      child: Column(
        children: [
          CustomButton(
            width: double.infinity,
            height: 56.h,
            text: 'Share the App',
            leftIcon: ImageConstant.imgIconWhiteA70020x20,
            onPressed: () => onTapShareApp(context),
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodyMedium,
          ),
          SizedBox(height: 8.h),
          CustomButton(
            width: double.infinity,
            height: 56.h,
            text: 'Suggest a Feature',
            leftIcon: ImageConstant.imgIconDeepPurpleA10020x20,
            onPressed: () => onTapSuggestFeature(context),
            buttonStyle: CustomButtonStyle.outlineDark,
            buttonTextStyle: CustomButtonTextStyle.bodyMediumPrimary,
          ),
        ],
      ),
    );
  }

  /// Sign out section
  Widget _buildSignOutSection(BuildContext context) {
    return CustomMenuItem(
      icon: Icons.logout_outlined,
      title: 'Sign Out',
      iconColor: const Color(0xFFEF4444),
      onTap: () => onTapSignOut(context),
      margin: EdgeInsets.only(right: 8.h, left: 8.h),
    );
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
    AppDownloadScreen.show(context);
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
