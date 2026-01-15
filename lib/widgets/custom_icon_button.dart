import '../core/app_export.dart';
import './custom_image_view.dart';

/// CustomIconButton - A reusable circular icon button component.
///
/// Supports:
/// - Material icons via [icon]
/// - SVG/assets via [iconPath] (optional fallback)
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

  /// Path to SVG/icon asset (optional)
  final String? iconPath;

  /// Material icon data (preferred)
  final IconData? icon;

  final VoidCallback? onTap;

  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;

  final bool isTonal;
  final bool isOutlined;

  final Color? iconColor;
  final double? iconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48.h;
    final effectiveWidth = width ?? 48.h;

    // NOTE:
    // For Option A (IconButton), we must NOT rely on Container padding to "center"
    // the glyph; IconButton will handle sizing when configured with zero padding.
    // For SVGs, we still use padding to keep them visually balanced.
    final effectivePadding = padding ?? EdgeInsets.all(12.h);

    final effectiveBorderRadius = borderRadius ?? (effectiveHeight / 2);
    final effectiveIconSize = iconSize ?? 24.h;

    // Background color based on style
    Color effectiveBackgroundColor;
    if (isOutlined) {
      effectiveBackgroundColor = Colors.transparent;
    } else if (isTonal) {
      effectiveBackgroundColor =
          (backgroundColor ?? Theme.of(context).colorScheme.surface)
              .withAlpha(31);
    } else {
      effectiveBackgroundColor = backgroundColor ?? appTheme.gray_900_03;
    }

    // Icon color
    final effectiveIconColor =
        iconColor ?? Theme.of(context).colorScheme.onSurface;

    // Build inner content
    Widget innerChild;

    if (icon != null) {
      // ✅ Option A: IconButton with zero padding/constraints
      // This removes default IconButton padding/constraints that can cause drift
      // inside tightly sized circular buttons.
      innerChild = IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          semanticLabel: semanticLabel,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
        iconSize: effectiveIconSize,
        color: effectiveIconColor,
        splashRadius: (effectiveHeight / 2).clamp(18.0, 28.0),
        tooltip: semanticLabel,
      );
    } else {
      // Asset/SVG path fallback
      innerChild = Padding(
        padding: effectivePadding,
        child: Center(
          child: CustomImageView(
            imagePath: iconPath!,
            height: effectiveIconSize,
            width: effectiveIconSize,
            color: effectiveIconColor,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      side: isOutlined
          ? BorderSide(
        color: borderColor ?? Theme.of(context).colorScheme.outline,
        width: 1.5,
      )
          : BorderSide.none,
    );

    Widget button = SizedBox(
      height: effectiveHeight,
      width: effectiveWidth,
      child: Material(
        color: effectiveBackgroundColor,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // If icon != null, IconButton already handles taps.
          // But we still want Ink ripple on the entire circle for SVG + general consistency.
          // For IconButton path, InkWell onTap is null so there isn't a double tap handler.
          onTap: (icon == null) ? onTap : null,
          child: Center(child: innerChild),
        ),
      ),
    );

    if (margin != null) {
      button = Padding(
        padding: margin as EdgeInsetsGeometry,
        child: button,
      );
    }

    return button;
  }
}
