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
    this.iconPath,
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.size,
    this.alignment,
    this.margin,
    this.borderRadius,
    this.iconColor,
    this.iconSize,
  })  : assert(iconPath != null || icon != null,
            'Either iconPath or icon must be provided'),
        super(key: key);

  /// Optional path to an asset/network icon (legacy)
  final String? iconPath;

  /// ✅ Preferred: Material icon
  final IconData? icon;

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

  final Color? iconColor;
  final double? iconSize;

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
            child: _buildInnerIcon(),
          ),
        ),
      ),
    );
  }

  Widget _buildInnerIcon() {
    final effectiveSize = size ?? 64.h;
    final glyphSize = iconSize ?? (effectiveSize * 0.5);
    final glyphColor = iconColor ?? appTheme.gray_50;

    if (icon != null) {
      return Icon(icon, size: glyphSize, color: glyphColor);
    }

    return CustomImageView(
      imagePath: iconPath!,
      height: glyphSize,
      width: glyphSize,
      fit: BoxFit.contain,
      color: glyphColor,
    );
  }

  /// Factory constructor for bottom right positioned FAB
  factory CustomFab.bottomRight({
    String? iconPath,
    IconData? icon,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? size,
    double? rightMargin,
    double? bottomMargin,
    double? borderRadius,
    Color? iconColor,
    double? iconSize,
  }) {
    return CustomFab(
      iconPath: iconPath,
      icon: icon,
      onTap: onTap,
      backgroundColor: backgroundColor,
      size: size,
      borderRadius: borderRadius,
      iconColor: iconColor,
      iconSize: iconSize,
      alignment: Alignment.bottomRight,
      margin: EdgeInsets.only(
        right: rightMargin ?? 28.h,
        bottom: bottomMargin ?? 46.h,
      ),
    );
  }

  /// Factory constructor for bottom left positioned FAB
  factory CustomFab.bottomLeft({
    String? iconPath,
    IconData? icon,
    VoidCallback? onTap,
    Color? backgroundColor,
    double? size,
    double? leftMargin,
    double? bottomMargin,
    double? borderRadius,
    Color? iconColor,
    double? iconSize,
  }) {
    return CustomFab(
      iconPath: iconPath,
      icon: icon,
      onTap: onTap,
      backgroundColor: backgroundColor,
      size: size,
      borderRadius: borderRadius,
      iconColor: iconColor,
      iconSize: iconSize,
      alignment: Alignment.bottomLeft,
      margin: EdgeInsets.only(
        left: leftMargin ?? 28.h,
        bottom: bottomMargin ?? 46.h,
      ),
    );
  }
}
