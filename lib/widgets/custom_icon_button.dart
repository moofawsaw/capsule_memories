import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';

/**
 * CustomIconButton - A flexible and reusable icon button widget with customizable styling
 * 
 * Features:
 * - Customizable background color and border radius
 * - Flexible padding and margin configuration
 * - Support for various icon sources (SVG, PNG, network images)
 * - Responsive sizing using SizeUtils extensions
 * - Optional tap callback functionality
 * 
 * @param iconPath - Path to the icon image (required)
 * @param onTap - Callback function when button is tapped
 * @param height - Height of the button
 * @param width - Width of the button
 * @param padding - Internal padding around the icon
 * @param margin - External margin around the button
 * @param backgroundColor - Background color of the button
 * @param borderRadius - Border radius for rounded corners
 * @param iconSize - Size of the icon inside the button
 */
class CustomIconButton extends StatelessWidget {
  CustomIconButton({
    Key? key,
    required this.iconPath,
    this.onTap,
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.iconSize,
  }) : super(key: key);

  /// Path to the icon image
  final String iconPath;

  /// Callback function when button is tapped
  final VoidCallback? onTap;

  /// Height of the button
  final double? height;

  /// Width of the button
  final double? width;

  /// Internal padding around the icon
  final EdgeInsetsGeometry? padding;

  /// External margin around the button
  final EdgeInsetsGeometry? margin;

  /// Background color of the button
  final Color? backgroundColor;

  /// Border radius for rounded corners
  final double? borderRadius;

  /// Size of the icon inside the button
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 48.h,
      width: width ?? 48.h,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? appTheme.transparentCustom,
        borderRadius: BorderRadius.circular(borderRadius ?? 24.h),
      ),
      child: IconButton(
        onPressed: onTap,
        padding: padding ?? EdgeInsets.all(12.h),
        icon: CustomImageView(
          imagePath: iconPath,
          height: iconSize ?? 24.h,
          width: iconSize ?? 24.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
