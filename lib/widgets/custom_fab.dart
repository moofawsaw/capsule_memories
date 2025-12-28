import '../core/app_export.dart';
import './custom_image_view.dart';

/// Custom Floating Action Button component that supports various positioning and styling options
///
/// This component provides a flexible implementation of FloatingActionButton with:
/// - Customizable positioning (left, right, center, custom alignment)
/// - Custom icon support through CustomImageView
/// - Configurable background colors and dimensions
/// - Responsive sizing using SizeUtils
/// - Support for custom margins and tap handling
///
/// @param iconPath - Path to the icon image (required)
/// @param onTap - Callback function when FAB is tapped
/// @param backgroundColor - Background color of the FAB
/// @param size - Size of the FAB (width and height)
/// @param alignment - Alignment for positioning the FAB
/// @param margin - Margin around the FAB
/// @param borderRadius - Border radius for the FAB
class CustomFab extends StatelessWidget {
  const CustomFab({
    Key? key,
    required this.iconPath,
    this.onTap,
    this.backgroundColor,
    this.size,
    this.alignment,
    this.margin,
    this.borderRadius,
  }) : super(key: key);

  /// Path to the icon image
  final String iconPath;

  /// Callback function when FAB is tapped
  final VoidCallback? onTap;

  /// Background color of the FAB
  final Color? backgroundColor;

  /// Size of the FAB (width and height)
  final double? size;

  /// Alignment for positioning the FAB
  final Alignment? alignment;

  /// Margin around the FAB
  final EdgeInsetsGeometry? margin;

  /// Border radius for the FAB
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: Align(
        alignment: alignment ?? Alignment.bottomRight,
        child: SizedBox(
          width: size ?? 64.h,
          height: size ?? 64.h,
          child: FloatingActionButton(
            onPressed: onTap,
            backgroundColor: backgroundColor ?? Color(0x4187242F),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 32.h),
            ),
            child: CustomImageView(
              imagePath: iconPath,
              height: (size ?? 64.h) * 0.5,
              width: (size ?? 64.h) * 0.5,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// Factory constructor for bottom right positioned FAB
  factory CustomFab.bottomRight({
    required String iconPath,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? size,
    double? rightMargin,
    double? bottomMargin,
    double? borderRadius,
  }) {
    return CustomFab(
      iconPath: iconPath,
      onTap: onTap,
      backgroundColor: backgroundColor,
      size: size,
      borderRadius: borderRadius,
      alignment: Alignment.bottomRight,
      margin: EdgeInsets.only(
        right: rightMargin ?? 28.h,
        bottom: bottomMargin ?? 46.h,
      ),
    );
  }

  /// Factory constructor for bottom left positioned FAB
  factory CustomFab.bottomLeft({
    required String iconPath,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? size,
    double? leftMargin,
    double? bottomMargin,
    double? borderRadius,
  }) {
    return CustomFab(
      iconPath: iconPath,
      onTap: onTap,
      backgroundColor: backgroundColor,
      size: size,
      borderRadius: borderRadius,
      alignment: Alignment.bottomLeft,
      margin: EdgeInsets.only(
        left: leftMargin ?? 28.h,
        bottom: bottomMargin ?? 46.h,
      ),
    );
  }
}
