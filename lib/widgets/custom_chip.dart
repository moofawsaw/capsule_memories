import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';

/** 
 * CustomChip - A flexible chip/tag component with icon and text
 * 
 * This component provides a reusable chip widget that displays an icon
 * followed by text in a horizontal layout. It supports customizable
 * styling, padding, and tap interactions.
 * 
 * Features:
 * - Customizable icon and text content
 * - Flexible styling options for text
 * - Configurable padding and spacing
 * - Optional tap callback functionality
 * - Responsive design using SizeUtils extensions
 * - Consistent spacing between icon and text
 */
class CustomChip extends StatelessWidget {
  const CustomChip({
    Key? key,
    required this.iconPath,
    required this.text,
    this.textStyle,
    this.padding,
    this.onTap,
    this.iconSize,
    this.spacing,
  }) : super(key: key);

  /// Path to the icon/image to display
  final String iconPath;

  /// Text to display next to the icon
  final String text;

  /// Custom text style for the label
  final TextStyle? textStyle;

  /// Padding around the entire chip
  final EdgeInsetsGeometry? padding;

  /// Callback when the chip is tapped
  final VoidCallback? onTap;

  /// Size of the icon
  final double? iconSize;

  /// Spacing between icon and text
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.h),
      child: Container(
        padding: padding ?? EdgeInsets.symmetric(horizontal: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImageView(
              imagePath: iconPath,
              height: iconSize ?? 24.h,
              width: iconSize ?? 24.h,
            ),
            SizedBox(width: spacing ?? 8.h),
            Text(
              text,
              style: textStyle ??
                  TextStyleHelper.instance.body12BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
            ),
          ],
        ),
      ),
    );
  }
}
