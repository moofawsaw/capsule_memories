import 'package:flutter/material.dart';

import '../core/app_export.dart';
import '../presentation/create_memory_screen/create_memory_screen.dart';
import '../presentation/notifications_screen/notifier/notifications_notifier.dart';
import './custom_image_view.dart';

/// Custom AppBar component that provides flexible layout options
/// Supports logo display, action buttons, profile images, and custom titles
/// Implements PreferredSizeWidget for proper AppBar integration
/// INTERNALLY MANAGES notification count state - no need for screens to pass it
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  CustomAppBar({
    Key? key,
    this.logoImagePath,
    this.title,
    this.showIconButton = false,
    this.iconButtonImagePath,
    this.iconButtonBackgroundColor,
    this.actionIcons,
    this.profileImagePath,
    this.showProfileImage = false,
    this.isProfileCircular = false,
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

  /// Path to the profile image
  final String? profileImagePath;

  /// Whether to show profile image
  final bool showProfileImage;

  /// Whether profile image should be circular
  final bool isProfileCircular;

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
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch notifications state to get unread count automatically
    final notificationsState = ref.watch(notificationsNotifier);
    final unreadCount = notificationsState.notificationsModel?.notificationsList
            ?.where((notification) => !(notification.isRead ?? false))
            .length ??
        0;

    return AppBar(
      backgroundColor: backgroundColor ?? appTheme.transparentCustom,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: customHeight ?? 102.h,
      title: _buildAppBarContent(context, unreadCount),
      titleSpacing: 0,
      bottom: showBottomBorder ? _buildBottomBorder() : null,
    );
  }

  Widget _buildAppBarContent(BuildContext context, int unreadCount) {
    switch (layoutType) {
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 26.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (logoImagePath != null) ...[
            Expanded(
              flex: 44,
              child: GestureDetector(
                onTap: () => _handleLogoTap(context),
                child: CustomImageView(
                  imagePath: logoImagePath!,
                  height: 26.h,
                  width: 130.h,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            SizedBox(width: 18.h),
          ],
          if (showIconButton && iconButtonImagePath != null) ...[
            Container(
              width: 46.h,
              height: 46.h,
              decoration: BoxDecoration(
                color: iconButtonBackgroundColor ?? Color(0x3BD81E29),
                borderRadius: BorderRadius.circular(22.h),
              ),
              child: IconButton(
                onPressed: () => _handlePlusButtonTap(context),
                padding: EdgeInsets.all(6.h),
                icon: CustomImageView(
                  imagePath: iconButtonImagePath!,
                  width: 34.h,
                  height: 34.h,
                ),
              ),
            ),
            SizedBox(width: 18.h),
          ],
          if (actionIcons != null) ...[
            ...actionIcons!.asMap().entries.map((entry) {
              int index = entry.key;
              String iconPath = entry.value;
              bool isNotificationIcon = _isNotificationIcon(iconPath);

              return Padding(
                padding: EdgeInsets.only(left: index > 0 ? 6.h : 0),
                child: GestureDetector(
                  onTap: () => _handleActionIconTap(context, iconPath),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomImageView(
                        imagePath: iconPath,
                        width: 32.h,
                        height: 32.h,
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
          if (showProfileImage && profileImagePath != null) ...[
            SizedBox(width: 8.h),
            GestureDetector(
              onTap: () => _handleProfileTap(context),
              child: Container(
                width: 50.h,
                height: 50.h,
                decoration: isProfileCircular
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                      )
                    : null,
                child: CustomImageView(
                  imagePath: profileImagePath!,
                  width: 50.h,
                  height: 50.h,
                  radius:
                      isProfileCircular ? BorderRadius.circular(24.h) : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleWithLeadingLayout() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.h, vertical: 4.h),
      child: Row(
        children: [
          if (leadingIcon != null)
            GestureDetector(
              onTap: onLeadingTap,
              child: CustomImageView(
                imagePath: leadingIcon!,
                width: 42.h,
                height: 42.h,
              ),
            ),
          if (title != null) ...[
            SizedBox(width: 52.h),
            Text(
              title!,
              style: titleTextStyle ??
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
          if (leadingIcon != null)
            GestureDetector(
              onTap: onLeadingTap,
              child: CustomImageView(
                imagePath: leadingIcon!,
                width: 26.h,
                height: 26.h,
              ),
            ),
          if (title != null)
            Text(
              title!,
              style: titleTextStyle ??
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
      NavigatorService.pushNamed(AppRoutes.notificationsScreen);
    }
    // Check if this is a pictures/gallery icon
    else if (_isPicturesIcon(iconPath)) {
      NavigatorService.pushNamed(AppRoutes.memoriesScreen);
    }
  }

  /// Identifies if an icon is a notification/bell icon
  bool _isNotificationIcon(String iconPath) {
    // Match against actual notification icon paths used in the app
    // These patterns match the bell/notification icons from image_constant.dart
    final notificationIconPatterns = [
      'icon_deep_purple_a100_32x32',
      'icon_deep_purple_a100_22x22',
      'icon_deep_purple_a100_26x26',
      'icon_deep_purple_a100_20x20',
      'icon_deep_purple_a100_14x14',
      'icon_deep_purple_a100',
      'icon_22x22',
      'icon_gray_50_32x32',
      'icons_26x26',
      'icons',
    ];

    return notificationIconPatterns
        .any((pattern) => iconPath.contains(pattern));
  }

  /// Identifies if an icon is a pictures/gallery icon
  bool _isPicturesIcon(String iconPath) {
    // Match against actual pictures/gallery icon paths used in the app
    final picturesIconPatterns = [
      'imagesmode',
      'icon_22x22',
      'img',
    ];

    return picturesIconPatterns.any((pattern) => iconPath.contains(pattern));
  }

  /// Handles profile avatar tap - always opens the user menu drawer
  void _handleProfileTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.menuScreen);
  }

  /// Handles logo tap - always navigates to feed screen
  void _handleLogoTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.feedScreen);
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

  @override
  Size get preferredSize => Size.fromHeight(
        (customHeight ?? 102.h) + (showBottomBorder ? 1.h : 0),
      );
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
