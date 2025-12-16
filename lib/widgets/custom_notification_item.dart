import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_icon_button.dart';

/** 
 * CustomNotificationItem - A reusable notification item component that displays notification content with title, subtitle, timestamp, and an action button.
 * 
 * Features:
 * - Flexible content with customizable title, subtitle, and timestamp
 * - Action button with customizable icon and callback
 * - Consistent spacing and typography following design system
 * - Responsive design using SizeUtils extensions
 * - Support for long text with proper text wrapping
 * 
 * @param title - Main notification title text
 * @param subtitle - Secondary description text  
 * @param timestamp - Time information for the notification
 * @param iconPath - Path to the action button icon
 * @param onIconTap - Callback function when action button is tapped
 * @param margin - Optional margin around the component
 */
class CustomNotificationItem extends StatelessWidget {
  const CustomNotificationItem({
    Key? key,
    this.title,
    this.subtitle,
    this.timestamp,
    this.iconPath,
    this.onIconTap,
    this.margin,
  }) : super(key: key);

  /// Main notification title text
  final String? title;

  /// Secondary description text below the title
  final String? subtitle;

  /// Timestamp text showing when the notification occurred
  final String? timestamp;

  /// Path to the icon displayed in the action button
  final String? iconPath;

  /// Callback function triggered when the action button is tapped
  final VoidCallback? onIconTap;

  /// Optional margin around the entire component
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 20.h),
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
                    if (title != null)
                      Text(
                        title!,
                        style: TextStyleHelper
                            .instance.title18BoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50, height: 1.22),
                      ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subtitle!,
                        style: TextStyleHelper
                            .instance.body14RegularPlusJakartaSans
                            .copyWith(
                                color: appTheme.blue_gray_300, height: 1.29),
                      ),
                    ],
                  ],
                ),
              ),
              if (iconPath != null)
                CustomIconButton(
                  iconPath: iconPath!,
                  onTap: onIconTap,
                  height: 48.h,
                  width: 48.h,
                  backgroundColor: appTheme.blue_gray_900_02,
                  borderRadius: 24.h,
                  padding: EdgeInsets.all(12.h),
                ),
            ],
          ),
          if (timestamp != null) ...[
            SizedBox(height: 16.h),
            Text(
              timestamp!,
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300, height: 1.29),
            ),
          ],
        ],
      ),
    );
  }
}
