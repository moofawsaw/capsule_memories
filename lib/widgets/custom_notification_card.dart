import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_icon_button.dart';

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
 * - Optional tap callback for entire card interaction
 * - Customizable background color for read/unread states
 * 
 * @param iconPath - Path to the icon image (required)
 * @param title - Main heading text (required)
 * @param description - Descriptive text content (required)
 * @param titleFontSize - Font size for the title text
 * @param descriptionAlignment - Text alignment for description
 * @param margin - Custom margin around the card
 * @param onIconTap - Callback function for icon button interaction
 * @param onTap - Callback function for entire card interaction
 * @param backgroundColor - Background color for the notification card
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
    this.onTap,
    this.backgroundColor,
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

  /// Callback function triggered when entire card is tapped
  final VoidCallback? onTap;

  /// Background color for the notification card
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? EdgeInsets.symmetric(horizontal: 20.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyleHelper
                            .instance.title18BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50, height: 1.22),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: TextStyleHelper
                            .instance.body14RegularPlusJakartaSans
                            .copyWith(
                                color: appTheme.blue_gray_300, height: 1.29),
                      ),
                    ],
                  ),
                ),
                CustomIconButton(
                  iconPath: iconPath,
                  onTap: onIconTap,
                  height: 48.h,
                  width: 48.h,
                  backgroundColor: appTheme.blue_gray_900_02,
                  borderRadius: 24.h,
                  padding: EdgeInsets.all(12.h),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
