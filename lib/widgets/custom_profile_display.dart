import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';

/** 
 * CustomProfileDisplay - A reusable profile display component that shows a circular profile image with name text below.
 * 
 * This component provides:
 * - Circular profile image with customizable size
 * - Name text with configurable styling  
 * - Responsive design using SizeUtils extensions
 * - Flexible alignment and spacing options
 * - Consistent visual hierarchy for profile information
 * 
 * @param imagePath - Path to the profile image (required)
 * @param name - Display name text (required)
 * @param imageSize - Size of the profile image (optional, defaults to 64.h)
 * @param textStyle - Custom text style for the name (optional)
 * @param spacing - Gap between image and text (optional, defaults to 12.h)
 * @param alignment - Cross axis alignment for the column (optional)
 * @param margin - External margin for the entire component (optional)
 */
class CustomProfileDisplay extends StatelessWidget {
  const CustomProfileDisplay({
    Key? key,
    required this.imagePath,
    required this.name,
    this.imageSize,
    this.textStyle,
    this.spacing,
    this.alignment,
    this.margin,
    this.onTap,
  }) : super(key: key);

  /// Path to the profile image
  final String imagePath;

  /// Display name text
  final String name;

  /// Size of the profile image
  final double? imageSize;

  /// Custom text style for the name
  final TextStyle? textStyle;

  /// Gap between image and text
  final double? spacing;

  /// Cross axis alignment for the column
  final CrossAxisAlignment? alignment;

  /// External margin for the entire component
  final EdgeInsetsGeometry? margin;

  /// Callback when profile is tapped
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular((imageSize ?? 64.h) / 2),
        child: Column(
          crossAxisAlignment: alignment ?? CrossAxisAlignment.center,
          children: [
            CustomImageView(
              imagePath: imagePath,
              height: imageSize ?? 64.h,
              width: imageSize ?? 64.h,
              radius: BorderRadius.circular((imageSize ?? 64.h) / 2),
              fit: BoxFit.cover,
            ),
            SizedBox(height: spacing ?? 12.h),
            Text(
              name,
              style: textStyle ??
                  TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans
                      .copyWith(height: 1.3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
