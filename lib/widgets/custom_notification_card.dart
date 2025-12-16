import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_icon_button.dart';

/**
 * CustomNotificationCard - A reusable card component for displaying notifications, invitations, or memory-related content.
 * 
 * This component provides a consistent layout with an icon button, title, and description text.
 * It supports customizable styling, spacing, and content while maintaining visual consistency.
 * 
 * Features:
 * - Flexible icon button with customizable appearance
 * - Dynamic title and description text
 * - Configurable text alignment and font sizes
 * - Responsive margins and spacing
 * - Optional tap callback for icon interaction
 * 
 * @param iconPath - Path to the icon image (required)
 * @param title - Main heading text (required)
 * @param description - Descriptive text content (required)
 * @param titleFontSize - Font size for the title text
 * @param descriptionAlignment - Text alignment for description
 * @param margin - Custom margin around the card
 * @param onIconTap - Callback function for icon button interaction
 */
class CustomNotificationCard extends StatelessWidget {
  const CustomNotificationCard({
    Key? key,
    required this.iconPath,
    required this.title,
    required this.description,
    this.titleFontSize,
    this.descriptionAlignment,
    this.margin,
    this.onIconTap,
  }) : super(key: key);

  /// Path to the icon image displayed in the button
  final String iconPath;

  /// Main title text displayed below the icon
  final String title;

  /// Description text displayed below the title
  final String description;

  /// Font size for the title text
  final double? titleFontSize;

  /// Text alignment for the description text
  final TextAlign? descriptionAlignment;

  /// Custom margin around the entire card
  final EdgeInsetsGeometry? margin;

  /// Callback function triggered when icon button is tapped
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 46.h, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconButton(
            iconPath: iconPath,
            height: 48.h,
            width: 48.h,
            backgroundColor: appTheme.color41C124,
            borderRadius: 24.h,
            padding: EdgeInsets.all(12.h),
            onTap: onIconTap,
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                .copyWith(
                    color: appTheme.gray_50, fontSize: (titleFontSize ?? 24.0)),
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            textAlign: descriptionAlignment ?? TextAlign.center,
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
        ],
      ),
    );
  }
}
