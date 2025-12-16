import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_icon_button.dart';

/** 
 * CustomIconButtonRow - A reusable row component that displays two icon buttons with consistent styling
 * 
 * This component provides a horizontal layout with two icon buttons, commonly used for action bars,
 * toolbars, or control panels. Features include:
 * - Consistent spacing and alignment
 * - Configurable icon paths for both buttons
 * - Optional expanded width behavior
 * - Responsive design using SizeUtils extensions
 * - Built-in tap callbacks for both buttons
 */
class CustomIconButtonRow extends StatelessWidget {
  const CustomIconButtonRow({
    Key? key,
    required this.firstIconPath,
    required this.secondIconPath,
    this.onFirstIconTap,
    this.onSecondIconTap,
    this.isExpanded = false,
    this.margin,
  }) : super(key: key);

  /// Path to the first (left) icon image
  final String firstIconPath;

  /// Path to the second (right) icon image
  final String secondIconPath;

  /// Callback function triggered when first icon button is tapped
  final VoidCallback? onFirstIconTap;

  /// Callback function triggered when second icon button is tapped
  final VoidCallback? onSecondIconTap;

  /// Whether the row should expand to fill available width
  final bool isExpanded;

  /// External margin around the entire row
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    Widget rowWidget = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        CustomIconButton(
          iconPath: firstIconPath,
          onTap: onFirstIconTap,
          backgroundColor: appTheme.gray_900_03,
          borderRadius: 24.h,
          height: 48.h,
          width: 48.h,
          padding: EdgeInsets.all(12.h),
        ),
        CustomIconButton(
          iconPath: secondIconPath,
          onTap: onSecondIconTap,
          backgroundColor: appTheme.gray_900_03,
          borderRadius: 24.h,
          height: 48.h,
          width: 48.h,
          padding: EdgeInsets.all(12.h),
          margin: EdgeInsets.only(left: 16.h),
        ),
      ],
    );

    if (isExpanded) {
      rowWidget = Expanded(child: rowWidget);
    }

    if (margin != null) {
      return Container(
        margin: margin,
        child: rowWidget,
      );
    }

    return rowWidget;
  }
}
