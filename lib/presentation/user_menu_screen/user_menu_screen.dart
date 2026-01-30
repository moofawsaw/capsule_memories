import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../core/utils/theme_provider.dart';
import '../../services/avatar_state_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_menu_item.dart';
import '../../widgets/custom_navigation_drawer.dart';
import '../../widgets/custom_switch.dart';
import '../app_download_screen/app_download_screen.dart';
import 'notifier/user_menu_notifier.dart';

class UserMenuScreen extends ConsumerStatefulWidget {
  UserMenuScreen({Key? key}) : super(key: key);

  @override
  UserMenuScreenState createState() => UserMenuScreenState();
}

class UserMenuScreenState extends ConsumerState<UserMenuScreen> {
  bool _avatarLoadRequested = false;

  Widget _newBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.h),
      decoration: BoxDecoration(
        color: appTheme.deep_purple_A100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'NEW',
        style: TextStyleHelper.instance.body12BoldPlusJakartaSans.copyWith(
          color: appTheme.gray_900_02,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  bool _isNetworkUrl(String? s) {
    final v = (s ?? '').trim();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  void _ensureAvatarLoadedIfNeeded(AvatarState avatarState) {
    if (_avatarLoadRequested) return;
    if (avatarState.isLoading) return;

    final url = (avatarState.avatarUrl ?? '').trim();
    if (url.isNotEmpty) return;

    _avatarLoadRequested = true;
    Future.microtask(
      () => ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the drawer repaints immediately when themeMode changes.
    // Many widgets in this tree read the global `appTheme` (ThemeHelper),
    // so we must rebuild on provider updates.
    ref.watch(themeModeProvider);

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
                bottom: false, // ✅ removes the extra gap at the bottom
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
                            SizedBox(height: 19.h),
                            _buildDarkModeToggle(context),
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

      _ensureAvatarLoadedIfNeeded(avatarState);

      // Prefer global avatar URL, and only accept real http(s) URLs here.
      // (userMenuModel.avatarImagePath is typically a storage key, not a URL)
      final String? avatarUrl = _isNetworkUrl(avatarState.avatarUrl)
          ? avatarState.avatarUrl!.trim()
          : (_isNetworkUrl(userModel?.avatarImagePath)
              ? userModel?.avatarImagePath!.trim()
              : null);

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
                        SizedBox(
                          width: 52.h,
                          height: 52.h,
                          child: showLetterAvatar
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: appTheme.deep_purple_A100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      avatarLetter,
                                      style: TextStyle(
                                        color: appTheme.gray_50,
                                        fontSize: 24.h,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : ClipOval(
                                  child: Image(
                                    image: CachedNetworkImageProvider(
                                      avatarUrl,
                                      // Stable cache key even for signed URLs
                                      cacheKey: Uri.parse(avatarUrl)
                                          .replace(query: '')
                                          .toString(),
                                    ),
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: appTheme.deep_purple_A100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            avatarLetter,
                                            style: TextStyle(
                                              color: appTheme.gray_50,
                                              fontSize: 24.h,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
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
                                    appTheme.gray_50,
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
                              color: appTheme.gray_50,
                              fontSize: 16.h,
                              fontWeight: FontWeight.w700,
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
        icon: Icons.auto_awesome_rounded,
        label: 'Daily Capsule',
        trailing: _newBadge(),
        onTap: () => onTapDailyCapsule(context),
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

  /// Dark mode toggle (shown below the main nav options, not part of the list)
  Widget _buildDarkModeToggle(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final themeMode = ref.watch(themeModeProvider);
      final bool isDark = ThemeModeNotifier.isDarkEffectiveForMode(themeMode);

      return Container(
        margin: EdgeInsets.only(left: 12.h, right: 12.h, top: 8.h),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            final next = isDark ? ThemeMode.light : ThemeMode.dark;
            ref.read(themeModeProvider.notifier).setThemeMode(next);
            // Keep user menu model in sync (best-effort)
            ref.read(userMenuNotifier.notifier).syncDarkModeFromTheme();
          },
          child: Row(
            children: [
              Icon(
                Icons.dark_mode_outlined,
                size: 24.h,
                color: appTheme.gray_50,
              ),
              SizedBox(width: 8.h),
              Expanded(
                child: Text(
                  'Dark mode',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),
              CustomSwitch(
                value: isDark,
                activeColor: appTheme.deep_purple_A100,
                inactiveTrackColor: appTheme.gray_900_02,
                inactiveThumbColor: appTheme.gray_50,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                  // Keep user menu model in sync (best-effort)
                  ref.read(userMenuNotifier.notifier).syncDarkModeFromTheme();
                },
              ),
            ],
          ),
        ),
      );
    });
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
            text: 'Submit a Request',
            leftIcon: Icons.lightbulb_outline, // ✅ IconData
            onPressed: () => onTapSuggestFeature(context),
            buttonStyle: CustomButtonStyle.outlineDark,
            buttonTextStyle: CustomButtonTextStyle.bodyMediumPrimary,
          ),
          SizedBox(height: 8.h),
          CustomButton(
            width: double.infinity,
            height: 56.h,
            text: 'Share the App',
            leftIcon: Icons.share, // ✅ IconData
            onPressed: () => onTapShareApp(context),
            buttonStyle: CustomButtonStyle.outlineDark,
            buttonTextStyle: CustomButtonTextStyle.bodyMedium,
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

  /// Navigates to Daily Capsule (personal daily journal)
  void onTapDailyCapsule(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appDailyCapsule);
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
