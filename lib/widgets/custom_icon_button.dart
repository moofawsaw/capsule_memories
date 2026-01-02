import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomIconButton - A reusable circular icon button component with full customization
 * 
 * This component provides a flexible, styled button that can display icons from either SVG files
 * or Material Icons. Features include:
 * - Support for both SVG images and Material Design icons
 * - Configurable size, padding, and border radius
 * - Optional tonal, outlined, or filled styles
 * - Theme-aware color handling
 * - Ripple effect on tap
 * - Accessibility support
 */
class CustomIconButton extends StatelessWidget {
  const CustomIconButton({
    Key? key,
    this.iconPath,
    this.icon,
    this.onTap,
    this.height,
    this.width,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.isTonal = false,
    this.isOutlined = false,
    this.iconColor,
    this.iconSize,
    this.semanticLabel,
  })  : assert(iconPath != null || icon != null,
            'Either iconPath or icon must be provided'),
        super(key: key);

  /// Path to SVG icon file (used if no Material icon provided)
  final String? iconPath;

  /// Material Design icon data (takes precedence over iconPath)
  final IconData? icon;

  /// Callback function triggered when button is tapped
  final VoidCallback? onTap;

  /// Fixed height of the button (defaults to 48.h)
  final double? height;

  /// Fixed width of the button (defaults to 48.h)
  final double? width;

  /// Internal padding around the icon
  final EdgeInsetsGeometry? padding;

  /// External margin around the button
  final EdgeInsetsGeometry? margin;

  /// Background color of the button
  final Color? backgroundColor;

  /// Border color (only visible when isOutlined is true)
  final Color? borderColor;

  /// Border radius for rounded corners
  final double? borderRadius;

  /// Whether to apply Material 3 tonal style (background with lower opacity)
  final bool isTonal;

  /// Whether to show only border without fill
  final bool isOutlined;

  /// Color for the icon (only applies to Material icons)
  final Color? iconColor;

  /// Size of the icon (defaults to 24.h)
  final double? iconSize;

  /// Accessibility label for screen readers
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48.h;
    final effectiveWidth = width ?? 48.h;
    final effectivePadding = padding ?? EdgeInsets.all(12.h);
    final effectiveBorderRadius = borderRadius ?? (effectiveHeight / 2);
    final effectiveIconSize = iconSize ?? 24.h;

    // Determine background color based on style
    Color effectiveBackgroundColor;
    if (isOutlined) {
      effectiveBackgroundColor = Colors.transparent;
    } else if (isTonal) {
      effectiveBackgroundColor = backgroundColor?.withAlpha(31) ??
          Theme.of(context).colorScheme.surfaceContainerHighest;
    } else {
      effectiveBackgroundColor = backgroundColor ?? appTheme.gray_900_03;
    }

    // Determine icon color
    final effectiveIconColor =
        iconColor ?? Theme.of(context).colorScheme.onSurface;

    Widget iconWidget;
    if (icon != null) {
      // Use Material Design icon
      iconWidget = Icon(
        icon,
        size: effectiveIconSize,
        color: effectiveIconColor,
        semanticLabel: semanticLabel,
      );
    } else {
      // Use SVG icon
      iconWidget = CustomImageView(
        imagePath: iconPath!,
        height: effectiveIconSize,
        width: effectiveIconSize,
        color: effectiveIconColor,
        fit: BoxFit.contain,
      );
    }

    Widget buttonContent = Container(
      height: effectiveHeight,
      width: effectiveWidth,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: isOutlined
            ? Border.all(
                color: borderColor ?? Theme.of(context).colorScheme.outline,
                width: 1.5,
              )
            : null,
      ),
      child: Center(child: iconWidget),
    );

    if (onTap != null) {
      buttonContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: buttonContent,
      );
    }

    if (margin != null) {
      return Container(
        margin: margin,
        child: buttonContent,
      );
    }

    return buttonContent;
  }
}
