import '../core/app_export.dart';
import './custom_image_view.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    Key? key,
    this.text,
    this.onPressed,
    this.width,
    this.height,
    this.size,
    this.buttonStyle,
    this.buttonTextStyle,
    this.isDisabled,
    this.isLoading,
    this.alignment,
    this.leftIcon,
    this.rightIcon,
    this.margin,
    this.padding,
  }) : super(key: key);

  final String? text;
  final VoidCallback? onPressed;

  final double? width;
  final double? height;
  final CustomButtonSize? size;

  final CustomButtonStyle? buttonStyle;
  final CustomButtonTextStyle? buttonTextStyle;

  final bool? isDisabled;
  final bool? isLoading;

  final Alignment? alignment;

  /// ✅ Can be String (asset path) OR IconData (Material icon)
  final Object? leftIcon;

  /// ✅ Can be String (asset path) OR IconData (Material icon)
  final Object? rightIcon;

  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? CustomButtonSize.primary;
    return Container(
      width: width,
      height: height ?? effectiveSize.height,
      margin: margin,
      alignment: alignment,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    final style = buttonStyle ?? CustomButtonStyle.fillPrimary;
    final effectiveSize = size ?? CustomButtonSize.primary;
    final baseTextStyle =
        buttonTextStyle ?? effectiveSize.defaultTextStyle;
    final textStyle = _resolveEffectiveTextStyle(context, style, baseTextStyle);

    final disabled = (isDisabled ?? false) || (isLoading ?? false);

    switch (style.variant) {
      case CustomButtonVariant.fill:
        return _buildElevatedButton(style, textStyle, disabled);
      case CustomButtonVariant.outline:
        return _buildOutlinedButton(style, textStyle, disabled);
      case CustomButtonVariant.text:
        return _buildTextButton(style, textStyle, disabled);
    }
  }

  CustomButtonTextStyle _resolveEffectiveTextStyle(
    BuildContext context,
    CustomButtonStyle style,
    CustomButtonTextStyle textStyle,
  ) {
    final brightness = Theme.of(context).brightness;
    final bool isOutlineVariant = style.variant == CustomButtonVariant.outline;

    // ✅ Fix: outlineDark + outlinePrimary should have dark text in light mode.
    // This matches typical UX expectations for outline buttons on light surfaces.
    final bool isOutlineDark = isOutlineVariant &&
        style.borderSide != null &&
        style.borderSide!.width >= 2 &&
        style.borderSide!.color == appTheme.blue_gray_900;

    final bool isOutlinePrimary = isOutlineVariant &&
        style.borderSide != null &&
        style.borderSide!.color == appTheme.deep_purple_A100;

    if (!isOutlineDark && !isOutlinePrimary) return textStyle;

    // Match outlineDark behavior for both styles.
    final Color desiredColor = (brightness == Brightness.light)
        ? Theme.of(context).colorScheme.onSurface
        : appTheme.gray_50;

    return CustomButtonTextStyle(
      color: desiredColor,
      fontSize: textStyle.fontSize,
      fontWeight: textStyle.fontWeight,
      iconSize: textStyle.iconSize,
    );
  }

  Widget _buildElevatedButton(
      CustomButtonStyle style,
      CustomButtonTextStyle textStyle,
      bool disabled,
      ) {
    final effectiveSize = size ?? CustomButtonSize.primary;
    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: style.backgroundColor ?? appTheme.deep_purple_A100,
        foregroundColor: textStyle.color ?? appTheme.whiteCustom,
        elevation: 0,
        shadowColor: appTheme.transparentCustom,
        side: style.borderSide,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.borderRadius ?? 6.h),
        ),
        padding: padding ?? effectiveSize.padding,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _buildButtonContent(textStyle),
    );
  }

  Widget _buildOutlinedButton(
      CustomButtonStyle style,
      CustomButtonTextStyle textStyle,
      bool disabled,
      ) {
    final effectiveSize = size ?? CustomButtonSize.primary;
    return OutlinedButton(
      onPressed: disabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: style.backgroundColor ?? appTheme.transparentCustom,
        foregroundColor: textStyle.color ?? appTheme.blue_gray_300,
        side: style.borderSide ??
            BorderSide(
              color: appTheme.blue_gray_900,
              width: 1,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.borderRadius ?? 6.h),
        ),
        padding: padding ?? effectiveSize.padding,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _buildButtonContent(textStyle),
    );
  }

  Widget _buildTextButton(
      CustomButtonStyle style,
      CustomButtonTextStyle textStyle,
      bool disabled,
      ) {
    final effectiveSize = size ?? CustomButtonSize.primary;
    return TextButton(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: style.backgroundColor ?? appTheme.transparentCustom,
        foregroundColor: textStyle.color ?? appTheme.blue_gray_300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.borderRadius ?? 6.h),
        ),
        padding: padding ?? effectiveSize.padding,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _buildButtonContent(textStyle),
    );
  }

  Widget _buildButtonContent(CustomButtonTextStyle textStyle) {
    if (isLoading ?? false) {
      return SizedBox(
        height: 20.h,
        width: 20.h,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textStyle.color ?? appTheme.whiteCustom,
          ),
        ),
      );
    }

    final hasLeftIcon = leftIcon != null;
    final hasRightIcon = rightIcon != null;
    final hasText = text != null && text!.isNotEmpty;
    final effectiveTextStyle = TextStyleHelper.instance.bodyTextPlusJakartaSans.copyWith(
      color: textStyle.color,
      fontSize: textStyle.fontSize,
      fontWeight: textStyle.fontWeight,
      height: 1.0, // helps prevent bottom clipping in tight heights
    );

    if (!hasLeftIcon && !hasRightIcon && hasText) {
      return Text(
        text!,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: effectiveTextStyle,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasLeftIcon) ...[
          _buildAnyIcon(leftIcon!, textStyle),
          if (hasText) SizedBox(width: 8.h),
        ],
        if (hasText)
          Text(
            text!,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: effectiveTextStyle,
          ),
        if (hasRightIcon) ...[
          if (hasText) SizedBox(width: 8.h),
          _buildAnyIcon(rightIcon!, textStyle),
        ],
      ],
    );
  }

  Widget _buildAnyIcon(Object iconValue, CustomButtonTextStyle textStyle) {
    final size = textStyle.iconSize ?? 20.h;
    final color = textStyle.color ?? appTheme.whiteCustom;

    if (iconValue is IconData) {
      return Icon(iconValue, size: size, color: color);
    }

    // Treat anything else as asset path
    final path = iconValue.toString();
    return CustomImageView(
      imagePath: path,
      height: size,
      width: size,
    );
  }
}

class CustomButtonStyle {
  CustomButtonStyle({
    this.backgroundColor,
    this.borderSide,
    this.borderRadius,
    this.variant = CustomButtonVariant.fill,
  });

  final Color? backgroundColor;
  final BorderSide? borderSide;
  final double? borderRadius;
  final CustomButtonVariant variant;

  static CustomButtonStyle get fillPrimary => CustomButtonStyle(
    backgroundColor: appTheme.deep_purple_A100,
    variant: CustomButtonVariant.fill,
  );

  static CustomButtonStyle get fillSuccess => CustomButtonStyle(
    backgroundColor: appTheme.green_500,
    variant: CustomButtonVariant.fill,
  );

  static CustomButtonStyle get fillError => CustomButtonStyle(
    backgroundColor: appTheme.red_500,
    variant: CustomButtonVariant.fill,
  );

  static CustomButtonStyle get fillDark => CustomButtonStyle(
    backgroundColor: appTheme.gray_900_02,
    variant: CustomButtonVariant.fill,
  );

  static CustomButtonStyle get fillTransparentRed => CustomButtonStyle(
    backgroundColor: appTheme.color41C124,
    variant: CustomButtonVariant.fill,
  );

  static CustomButtonStyle get fillGray => CustomButtonStyle(
    backgroundColor: appTheme.gray_400,
    variant: CustomButtonVariant.fill,
  );

  static CustomButtonStyle get fillDeepPurpleA => CustomButtonStyle(
    backgroundColor: appTheme.deep_purple_A200,
    variant: CustomButtonVariant.fill,
  );

  static CustomButtonStyle get fillRed => CustomButtonStyle(
    backgroundColor: appTheme.red_500,
    variant: CustomButtonVariant.fill,
  );

  static CustomButtonStyle get outlineDark => CustomButtonStyle(
    borderSide: BorderSide(
      color: appTheme.blue_gray_900,
      width: 2,
    ),
    variant: CustomButtonVariant.outline,
  );

  static CustomButtonStyle get outlinePrimary => CustomButtonStyle(
    borderSide: BorderSide(
      color: appTheme.deep_purple_A100,
      width: 1,
    ),
    variant: CustomButtonVariant.outline,
  );

  static CustomButtonStyle get textOnly => CustomButtonStyle(
    variant: CustomButtonVariant.text,
  );
}

class CustomButtonTextStyle {
  CustomButtonTextStyle({
    this.color,
    this.fontSize,
    this.fontWeight,
    this.iconSize,
  });

  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? iconSize;

  static CustomButtonTextStyle get bodyMedium => CustomButtonTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: appTheme.whiteCustom,
  );

  static CustomButtonTextStyle get bodySmall => CustomButtonTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: appTheme.whiteCustom,
  );

  static CustomButtonTextStyle get bodyMediumGray => CustomButtonTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: appTheme.blue_gray_300,
  );

  static CustomButtonTextStyle get bodySmallPrimary => CustomButtonTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: appTheme.deep_purple_A100,
  );

  static CustomButtonTextStyle get bodyMediumPrimary => CustomButtonTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: appTheme.deep_purple_A100,
  );
}

enum CustomButtonVariant {
  fill,
  outline,
  text,
}

/// Shared, consistent button sizing presets.
///
/// - `primary`: default 56dp height (used for main CTAs).
/// - `compact`: medium-small height for inline actions like "Follow back",
///   and friend invite Accept/Decline/Cancel actions.
enum CustomButtonSize {
  primary,
  compact,
  mini,
}

extension CustomButtonSizeX on CustomButtonSize {
  double get height {
    switch (this) {
      case CustomButtonSize.primary:
        return 56.h;
      case CustomButtonSize.compact:
        return 40.h;
      case CustomButtonSize.mini:
        return 32.h;
    }
  }

  EdgeInsetsGeometry get padding {
    switch (this) {
      case CustomButtonSize.primary:
        return EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h);
      case CustomButtonSize.compact:
        return EdgeInsets.symmetric(horizontal: 14.h, vertical: 8.h);
      case CustomButtonSize.mini:
        // True symmetric padding for tiny outlined buttons.
        return EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h);
    }
  }

  CustomButtonTextStyle get defaultTextStyle {
    switch (this) {
      case CustomButtonSize.primary:
        return CustomButtonTextStyle.bodyMedium;
      case CustomButtonSize.compact:
        return CustomButtonTextStyle.bodySmall;
      case CustomButtonSize.mini:
        return CustomButtonTextStyle.bodySmall;
    }
  }
}
