import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';

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
class CustomAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
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

class _CustomAppBarState extends ConsumerState<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _plusSpinController;
  late final Animation<double> _plusSpin;

  // ✅ Keep a stable ImageProvider so rebuilds don’t thrash the avatar image
  String? _cachedAvatarUrl;
  ImageProvider? _cachedAvatarProvider;

  @override
  void initState() {
    super.initState();

    // Plus micro-interaction (one quick spin)
    _plusSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _plusSpin = CurvedAnimation(
      parent: _plusSpinController,
      curve: Curves.easeOutCubic,
    );

    // Load avatar only if not already cached
    if (widget.showProfileImage) {
      Future.microtask(() => _ensureAvatarLoaded());
    }
  }

  @override
  void dispose() {
    _plusSpinController.dispose();
    super.dispose();
  }

  /// Ensure avatar is loaded whenever avatarUrl is null/empty
  /// 🎯 UPDATED: Load based on avatarUrl state, not userId
  Future<void> _ensureAvatarLoaded() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final user = client.auth.currentUser;
      if (user == null) return;

      final currentAvatarState = ref.read(avatarStateProvider);

      // 🎯 CRITICAL: Load if avatarUrl is null/empty (not based on userId)
      if ((currentAvatarState.avatarUrl == null ||
          currentAvatarState.avatarUrl!.isEmpty) &&
          !currentAvatarState.isLoading) {
        await ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
        print('✅ Avatar loaded in custom_app_bar based on empty avatarUrl');
      }
    } catch (e) {
      print('❌ Error ensuring avatar loaded: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Only rebuild AppBar title content when unreadCount changes (not on every notifier change)
    final unreadCount = ref.watch(
      notificationsNotifier.select(
            (s) => s.notificationsModel?.unreadCount ?? 0,
      ),
    );

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
    // ✅ Only watch the auth flag here (prevents avatarUrl changes from rebuilding the whole row)
    final isAuthenticated = ref.watch(
      avatarStateProvider.select((s) => s.userId != null),
    );

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

          if (isAuthenticated) ...[
            // ➕ PLUS BUTTON (spin stays)
            if (widget.showIconButton && widget.iconButtonImagePath != null) ...[
              Container(
                width: 46.h,
                height: 46.h,
                decoration: BoxDecoration(
                  color: widget.iconButtonBackgroundColor ?? const Color(0x3BD81E29),
                  borderRadius: BorderRadius.circular(22.h),
                ),
                child: IconButton(
                  onPressed: () => _handlePlusButtonTap(context),
                  padding: EdgeInsets.all(6.h),
                  icon: AnimatedBuilder(
                    animation: _plusSpinController,
                    builder: (context, child) {
                      final angle = _plusSpin.value * 2 * math.pi;
                      return Transform.rotate(
                        angle: angle,
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.add,
                      size: 34,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 18.h),
            ],

            // ACTION ICONS
            if (widget.actionIcons != null) ...[
              ...widget.actionIcons!.asMap().entries.map((entry) {
                final index = entry.key;
                final iconPath = entry.value;

                final isNotificationIcon = _isNotificationIcon(iconPath);
                final isPicturesIcon = _isPicturesIcon(iconPath);

                bool isActive = false;
                if (isNotificationIcon && currentRoute == AppRoutes.appNotifications) {
                  isActive = true;
                } else if (isPicturesIcon && currentRoute == AppRoutes.appMemories) {
                  isActive = true;
                }

                // OUTLINE vs FILLED
                IconData outlineIcon;
                IconData filledIcon;

                if (isNotificationIcon) {
                  outlineIcon = Icons.notifications_outlined;
                  filledIcon = Icons.notifications;
                } else if (isPicturesIcon) {
                  outlineIcon = Icons.photo_outlined;
                  filledIcon = Icons.photo;
                } else {
                  outlineIcon = Icons.help_outline;
                  filledIcon = Icons.help;
                }

                final iconColor = isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface;

                return Padding(
                  padding: EdgeInsets.only(left: index > 0 ? 6.h : 0),
                  child: GestureDetector(
                    onTap: () => _handleActionIconTap(context, iconPath),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: 32.h,
                          height: 32.h,
                          child: Center(
                            child: Icon(
                              isActive ? filledIcon : outlineIcon,
                              size: 32,
                              color: iconColor,
                            ),
                          ),
                        ),

                        // 🔔 Notification badge (unchanged)
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
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
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
  /// ✅ Optimized: only rebuilds when the small set of fields used by this widget change
  Widget _buildAuthenticationWidget(BuildContext context) {
    final userId = ref.watch(avatarStateProvider.select((s) => s.userId));
    final avatarUrl = ref.watch(avatarStateProvider.select((s) => s.avatarUrl));
    final userEmail = ref.watch(avatarStateProvider.select((s) => s.userEmail));
    final isLoading = ref.watch(avatarStateProvider.select((s) => s.isLoading));

    final isAuthenticated = userId != null;

    // Show loading only if we have nothing to display yet (prevents “spinner flash” while other UI updates happen)
    if (!isAuthenticated && isLoading) {
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

    if (!isAuthenticated) {
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
            style: TextStyleHelper.instance.body14BoldPlusJakartaSans.copyWith(
              color: appTheme.gray_50,
            ),
          ),
        ),
      );
    }

    // Show user avatar when authenticated
    return GestureDetector(
      onTap: () => _handleProfileTap(context),
      child: _buildUserAvatar(
        avatarUrl: avatarUrl,
        userEmail: userEmail,
        isLoading: isLoading,
      ),
    );
  }

  /// Handle login button tap - navigate to login screen
  void _handleLoginButtonTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.authLogin);
  }

  /// ✅ Stable avatar rendering:
  /// - Uses CachedNetworkImageProvider
  /// - Keeps a stable ImageProvider instance while URL is unchanged
  /// - Does NOT replace avatar with spinner if we already have an avatar URL
  Widget _buildUserAvatar({
    required String? avatarUrl,
    required String? userEmail,
    required bool isLoading,
  }) {
    final hasUrl = (avatarUrl != null && avatarUrl.isNotEmpty);

    // Generate avatar letter from email if no avatar URL
    final email = userEmail ?? '';
    final avatarLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    // Cache provider by URL so rebuilds don't thrash image resolution
    if (hasUrl) {
      if (_cachedAvatarUrl != avatarUrl || _cachedAvatarProvider == null) {
        _cachedAvatarUrl = avatarUrl;
        _cachedAvatarProvider = CachedNetworkImageProvider(avatarUrl);
      }
    } else {
      _cachedAvatarUrl = null;
      _cachedAvatarProvider = null;
    }

    return Container(
      width: 50.h,
      height: 50.h,
      decoration: BoxDecoration(
        color: !hasUrl ? appTheme.deep_purple_A100 : null,
        shape: BoxShape.circle,
        image: hasUrl
            ? DecorationImage(
          image: _cachedAvatarProvider!,
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: !hasUrl
          ? Center(
        child: Text(
          avatarLetter,
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans.copyWith(
            color: appTheme.gray_50,
            fontSize: 20.h,
          ),
        ),
      )
          : (isLoading
          ? Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 20.h,
          height: 20.h,
          child: CircularProgressIndicator(
            strokeWidth: 2.h,
            valueColor: AlwaysStoppedAnimation<Color>(appTheme.gray_50),
          ),
        ),
      )
          : null),
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
              child: Icon(
                Icons.arrow_back,
                size: 42,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          if (widget.title != null) ...[
            SizedBox(width: 52.h),
            Text(
              widget.title!,
              style: widget.titleTextStyle ??
                  TextStyleHelper.instance.headline28ExtraBoldPlusJakartaSans.copyWith(
                    color: appTheme.gray_50,
                    height: 1.28,
                  ),
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
              child: Icon(
                Icons.close,
                size: 26,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          if (widget.title != null)
            Text(
              widget.title!,
              style: widget.titleTextStyle ??
                  TextStyleHelper.instance.title18BoldPlusJakartaSans.copyWith(
                    color: appTheme.blue_A700,
                    height: 1.28,
                  ),
            ),
        ],
      ),
    );
  }

  /// Handles plus button tap - always opens memory_create bottom sheet
  void _handlePlusButtonTap(BuildContext context) {
    // Start spin immediately
    _plusSpinController.forward(from: 0);

    // Open bottom sheet on the next frame so the first rotation frame paints
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CreateMemoryScreen(),
      );
    });
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
        !iconPath.contains('icon_gray_50_32x32') && // Exclude notification bell icon
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
