import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';

/// Custom AppBar component that provides flexible layout options
/// Supports logo display, action buttons, profile images, and custom titles
/// Implements PreferredSizeWidget for proper AppBar integration
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  CustomAppBar({
    Key? key,
    this.logoImagePath,
    this.title,
    this.showIconButton = false,
    this.iconButtonImagePath,
    this.iconButtonBackgroundColor,
    this.onIconButtonTap,
    this.actionIcons,
    this.profileImagePath,
    this.showProfileImage = false,
    this.isProfileCircular = false,
    this.onProfileTap,
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

  /// Whether to show the icon button
  final bool showIconButton;

  /// Path to the icon button image
  final String? iconButtonImagePath;

  /// Background color for the icon button
  final Color? iconButtonBackgroundColor;

  /// Callback for icon button tap
  final VoidCallback? onIconButtonTap;

  /// List of action icon paths
  final List<String>? actionIcons;

  /// Path to the profile image
  final String? profileImagePath;

  /// Whether to show profile image
  final bool showProfileImage;

  /// Whether profile image should be circular
  final bool isProfileCircular;

  /// Callback for profile image tap
  final VoidCallback? onProfileTap;

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
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? appTheme.transparentCustom,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: customHeight ?? 102.h,
      title: _buildAppBarContent(),
      titleSpacing: 0,
      bottom: showBottomBorder ? _buildBottomBorder() : null,
    );
  }

  Widget _buildAppBarContent() {
    switch (layoutType) {
      case CustomAppBarLayoutType.logoWithActions:
        return _buildLogoWithActionsLayout();
      case CustomAppBarLayoutType.titleWithLeading:
        return _buildTitleWithLeadingLayout();
      case CustomAppBarLayoutType.spaceBetween:
        return _buildSpaceBetweenLayout();
      default:
        return _buildLogoWithActionsLayout();
    }
  }

  Widget _buildLogoWithActionsLayout() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 26.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (logoImagePath != null) ...[
            Expanded(
              flex: 44,
              child: CustomImageView(
                imagePath: logoImagePath!,
                height: 26.h,
                width: 130.h,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
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
                onPressed: onIconButtonTap,
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
              return Padding(
                padding: EdgeInsets.only(left: index > 0 ? 6.h : 0),
                child: CustomImageView(
                  imagePath: iconPath,
                  width: 32.h,
                  height: 32.h,
                ),
              );
            }),
          ],
          if (showProfileImage && profileImagePath != null) ...[
            SizedBox(width: 8.h),
            GestureDetector(
              onTap: onProfileTap,
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
