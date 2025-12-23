import '../core/app_export.dart';
import '../presentation/create_memory_screen/create_memory_screen.dart';
import '../presentation/notifications_screen/notifier/notifications_notifier.dart';
import '../services/avatar_state_service.dart';
import '../services/supabase_service.dart';
import './custom_image_view.dart';

/// Custom AppBar component that provides flexible layout options
/// Supports logo display, action buttons, profile images, and custom titles
/// Implements PreferredSizeWidget for proper AppBar integration
/// INTERNALLY MANAGES notification count state and user avatar - no need for screens to pass them
class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  CustomAppBar({
    Key? key,
    this.logoImagePath,
    this.title,
    this.showIconButton = false,
    this.iconButtonImagePath,
    this.iconButtonBackgroundColor,
    this.actionIcons,
    this.showProfileImage = false,
    this.layoutType = CustomAppBarLayoutType.logoWithActions,
    this.customHeight,
    this.showBottomBorder = true,
    this.backgroundColor,
    this.titleTextStyle,
    this.leadingIcon,
    this.onLeadingTap,
  }) : super(key: key);

  /// Path to the logo image (typically SVG)
  final String? logoImagePath;

  /// Title text for the app bar
  final String? title;

  /// Whether to show the icon button (plus button)
  final bool showIconButton;

  /// Path to the icon button image
  final String? iconButtonImagePath;

  /// Background color for the icon button
  final Color? iconButtonBackgroundColor;

  /// List of action icon paths
  final List<String>? actionIcons;

  /// Whether to show profile image
  final bool showProfileImage;

  /// Layout type for the app bar
  final CustomAppBarLayoutType layoutType;

  /// Custom height for the app bar
  final double? customHeight;

  /// Whether to show bottom border
  final bool showBottomBorder;

  /// Background color for the app bar
  final Color? backgroundColor;

  /// Custom text style for title
  final TextStyle? titleTextStyle;

  /// Leading icon path
  final String? leadingIcon;

  /// Callback for leading icon tap
  final VoidCallback? onLeadingTap;

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
        (customHeight ?? 102.h) + (showBottomBorder ? 1.h : 0),
      );
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  bool _isUserAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // Delay to avoid modifying provider during build
    Future.microtask(() => _checkAuthenticationState());
  }

  /// Check authentication state WITHOUT loading avatar
  /// Avatar is loaded once at app startup in main.dart
  Future<void> _checkAuthenticationState() async {
    if (!widget.showProfileImage) return;

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        if (mounted) setState(() => _isUserAuthenticated = false);
        return;
      }

      final user = client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isUserAuthenticated = false);
        return;
      }

      if (mounted) setState(() => _isUserAuthenticated = true);

      // 🔥 CACHE CHECK: Only load avatar if it's NOT already cached in global state
      final currentAvatarState = ref.read(avatarStateProvider);

      // If avatar is not loaded yet AND user is authenticated, load it ONCE
      if (currentAvatarState.avatarUrl == null &&
          currentAvatarState.userId == null &&
          !currentAvatarState.isLoading) {
        // Delay avatar loading to happen AFTER build completes
        await ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
      }
    } catch (e) {
      print('❌ Error checking authentication: $e');
      if (mounted) setState(() => _isUserAuthenticated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch notifications state to get unread count automatically
    final notificationsState = ref.watch(notificationsNotifier);
    final unreadCount = notificationsState.notificationsModel?.unreadCount ?? 0;

    return AppBar(
      backgroundColor: widget.backgroundColor ?? appTheme.transparentCustom,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: widget.customHeight ?? 102.h,
      title: _buildAppBarContent(context, unreadCount),
      titleSpacing: 0,
      bottom: widget.showBottomBorder ? _buildBottomBorder() : null,
    );
  }

  Widget _buildAppBarContent(BuildContext context, int unreadCount) {
    switch (widget.layoutType) {
      case CustomAppBarLayoutType.logoWithActions:
        return _buildLogoWithActionsLayout(context, unreadCount);
      case CustomAppBarLayoutType.titleWithLeading:
        return _buildTitleWithLeadingLayout();
      case CustomAppBarLayoutType.spaceBetween:
        return _buildSpaceBetweenLayout();
      default:
        return _buildLogoWithActionsLayout(context, unreadCount);
    }
  }

  Widget _buildLogoWithActionsLayout(BuildContext context, int unreadCount) {
    // 🔥 Get current route to determine active state
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 26.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.logoImagePath != null) ...[
            Expanded(
              flex: 44,
              child: GestureDetector(
                onTap: () => _handleLogoTap(context),
                child: CustomImageView(
                  imagePath: widget.logoImagePath!,
                  height: 26.h,
                  width: 130.h,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            SizedBox(width: 18.h),
          ],
          // Only show action buttons and icons if user is authenticated
          if (_isUserAuthenticated) ...[
            if (widget.showIconButton &&
                widget.iconButtonImagePath != null) ...[
              Container(
                width: 46.h,
                height: 46.h,
                decoration: BoxDecoration(
                  color: widget.iconButtonBackgroundColor ?? Color(0x3BD81E29),
                  borderRadius: BorderRadius.circular(22.h),
                ),
                child: IconButton(
                  onPressed: () => _handlePlusButtonTap(context),
                  padding: EdgeInsets.all(6.h),
                  icon: CustomImageView(
                    imagePath: widget.iconButtonImagePath!,
                    width: 34.h,
                    height: 34.h,
                  ),
                ),
              ),
              SizedBox(width: 18.h),
            ],
            if (widget.actionIcons != null) ...[
              ...widget.actionIcons!.asMap().entries.map((entry) {
                int index = entry.key;
                String iconPath = entry.value;
                bool isNotificationIcon = _isNotificationIcon(iconPath);
                bool isPicturesIcon = _isPicturesIcon(iconPath);

                // 🎯 Determine if this icon should be in active state
                bool isActive = false;
                Color? activeColor;

                if (isNotificationIcon &&
                    currentRoute == AppRoutes.appNotifications) {
                  isActive = true;
                  activeColor = appTheme.deep_purple_A100;
                } else if (isPicturesIcon &&
                    currentRoute == AppRoutes.appMemories) {
                  isActive = true;
                  activeColor = appTheme.deep_purple_A100;
                }

                return Padding(
                  padding: EdgeInsets.only(left: index > 0 ? 6.h : 0),
                  child: GestureDetector(
                    onTap: () => _handleActionIconTap(context, iconPath),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Icon with conditional active state
                        Container(
                          width: 32.h,
                          height: 32.h,
                          padding: EdgeInsets.all(isActive ? 6.h : 0),
                          decoration: isActive
                              ? BoxDecoration(
                                  color: activeColor,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: CustomImageView(
                            imagePath: iconPath,
                            width: isActive ? 20.h : 32.h,
                            height: isActive ? 20.h : 32.h,
                            color: isActive ? appTheme.gray_50 : null,
                          ),
                        ),
                        if (isNotificationIcon && unreadCount > 0)
                          Positioned(
                            right: -4.h,
                            top: -4.h,
                            child: Container(
                              padding: EdgeInsets.all(4.h),
                              decoration: BoxDecoration(
                                color: appTheme.colorFF52D1,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: appTheme.gray_900_02,
                                  width: 1.5.h,
                                ),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 18.h,
                                minHeight: 18.h,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99
                                      ? '99+'
                                      : unreadCount.toString(),
                                  style: TextStyleHelper
                                      .instance.body10BoldPlusJakartaSans
                                      .copyWith(
                                    color: appTheme.gray_50,
                                    height: 1.0,
                                    fontSize: unreadCount > 99 ? 8.h : 10.h,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
          if (widget.showProfileImage) ...[
            SizedBox(width: 8.h),
            _buildAuthenticationWidget(context),
          ],
        ],
      ),
    );
  }

  /// Build authentication widget - shows login button or user avatar based on auth state
  Widget _buildAuthenticationWidget(BuildContext context) {
    // 🔥 Watch global avatar state - will automatically refresh when avatar changes
    final avatarState = ref.watch(avatarStateProvider);

    if (avatarState.isLoading) {
      return Container(
        width: 50.h,
        height: 50.h,
        decoration: BoxDecoration(
          color: appTheme.deep_purple_A100.withAlpha(77),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 20.h,
            height: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.h,
              valueColor: AlwaysStoppedAnimation<Color>(appTheme.gray_50),
            ),
          ),
        ),
      );
    }

    if (!_isUserAuthenticated) {
      // Show login button when user is not authenticated
      return GestureDetector(
        onTap: () => _handleLoginButtonTap(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
          decoration: BoxDecoration(
            color: appTheme.deep_purple_A100,
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Text(
            'Login',
            style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        ),
      );
    }

    // Show user avatar when authenticated - automatically updates from global state
    return GestureDetector(
      onTap: () => _handleProfileTap(context),
      child: _buildUserAvatar(avatarState),
    );
  }

  /// Handle login button tap - navigate to login screen
  void _handleLoginButtonTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.authLogin);
  }

  /// Build user avatar widget with real data from global state
  /// Automatically refreshes when avatar changes anywhere in the app
  Widget _buildUserAvatar(AvatarState avatarState) {
    return Container(
      width: 50.h,
      height: 50.h,
      decoration: BoxDecoration(
        color: appTheme.deep_purple_A100,
        shape: BoxShape.circle,
      ),
      child: avatarState.isLoading
          ? Center(
              child: SizedBox(
                width: 20.h,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.h,
                  valueColor: AlwaysStoppedAnimation<Color>(appTheme.gray_50),
                ),
              ),
            )
          : avatarState.avatarUrl != null && avatarState.avatarUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(25.h),
                  child: CustomImageView(
                    imagePath: avatarState.avatarUrl!,
                    width: 50.h,
                    height: 50.h,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Text(
                    _getAvatarFallbackText(avatarState.userEmail),
                    style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                        .copyWith(
                      color: appTheme.gray_50,
                      fontSize: 20.h,
                    ),
                  ),
                ),
    );
  }

  /// Get fallback avatar text (first letter of email)
  String _getAvatarFallbackText(String? userEmail) {
    if (userEmail != null && userEmail.isNotEmpty) {
      return userEmail.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  Widget _buildTitleWithLeadingLayout() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.h, vertical: 4.h),
      child: Row(
        children: [
          if (widget.leadingIcon != null)
            GestureDetector(
              onTap: widget.onLeadingTap,
              child: CustomImageView(
                imagePath: widget.leadingIcon!,
                width: 42.h,
                height: 42.h,
              ),
            ),
          if (widget.title != null) ...[
            SizedBox(width: 52.h),
            Text(
              widget.title!,
              style: widget.titleTextStyle ??
                  TextStyleHelper.instance.headline28ExtraBoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50, height: 1.28),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpaceBetweenLayout() {
    return Padding(
      padding: EdgeInsets.fromLTRB(19.h, 14.h, 18.h, 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.leadingIcon != null)
            GestureDetector(
              onTap: widget.onLeadingTap,
              child: CustomImageView(
                imagePath: widget.leadingIcon!,
                width: 26.h,
                height: 26.h,
              ),
            ),
          if (widget.title != null)
            Text(
              widget.title!,
              style: widget.titleTextStyle ??
                  TextStyleHelper.instance.title18BoldPlusJakartaSans
                      .copyWith(color: appTheme.blue_A700, height: 1.28),
            ),
        ],
      ),
    );
  }

  /// Handles plus button tap - always opens memory_create bottom sheet
  void _handlePlusButtonTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateMemoryScreen(),
    );
  }

  /// Handles action icon tap - identifies and navigates accordingly
  /// Bell/notification icons always navigate to notifications screen
  /// Pictures/gallery icons navigate to memories screen
  void _handleActionIconTap(BuildContext context, String iconPath) {
    // Check if this is a notification/bell icon
    if (_isNotificationIcon(iconPath)) {
      NavigatorService.pushNamed(AppRoutes.appNotifications);
    }
    // Check if this is a pictures/gallery icon
    else if (_isPicturesIcon(iconPath)) {
      NavigatorService.pushNamed(AppRoutes.appMemories);
    }
  }

  /// Identifies if an icon is a notification/bell icon
  bool _isNotificationIcon(String iconPath) {
    // 🎯 EXACT match for notification bell icon - outline version used in app_shell
    // This is the default notification icon that gets styled when active
    return iconPath.contains('icon_gray_50_32x32');
  }

  /// Identifies if an icon is a pictures/gallery icon
  bool _isPicturesIcon(String iconPath) {
    // 🎯 EXACT match for pictures/memories icon - must match the icon used in app_shell
    // This is the ONLY pictures icon in the app
    return iconPath.contains('icon_gray_50') &&
        !iconPath
            .contains('icon_gray_50_32x32') && // Exclude notification bell icon
        !iconPath.contains('icon_gray_50_18x') &&
        !iconPath.contains('icon_gray_50_20x') &&
        !iconPath.contains('icon_gray_50_24x') &&
        !iconPath.contains('icon_gray_50_26x') &&
        !iconPath.contains('icon_gray_50_42x');
  }

  /// Handles profile avatar tap - always opens the user menu drawer
  void _handleProfileTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appMenu);
  }

  /// Handles logo tap - always navigates to feed screen
  void _handleLogoTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appFeed);
  }

  PreferredSizeWidget? _buildBottomBorder() {
    return PreferredSize(
      preferredSize: Size.fromHeight(1.h),
      child: Container(
        height: 1.h,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: appTheme.blue_gray_900,
              width: 1.h,
            ),
          ),
        ),
      ),
    );
  }
}

/// Layout types for the custom app bar
enum CustomAppBarLayoutType {
  /// Logo with action icons and profile (default)
  logoWithActions,

  /// Title with leading icon
  titleWithLeading,

  /// Space between layout for leading and trailing elements
  spaceBetween,
}
