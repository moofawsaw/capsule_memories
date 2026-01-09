import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomButton - A versatile button component that supports multiple styles and configurations
 *
 * @param text - The text content displayed on the button
 * @param onPressed - Callback function when button is pressed
 * @param width - Button width, can be specific value or null for auto-sizing
 * @param height - Button height
 * @param buttonStyle - The style variant of the button
 * @param buttonTextStyle - Text style configuration for the button text
 * @param isDisabled - Whether the button is disabled
 * @param alignment - Button alignment within its parent
 * @param leftIcon - Icon to display on the left side of the text
 * @param rightIcon - Icon to display on the right side of the text
 * @param margin - External spacing around the button
 * @param padding - Internal spacing within the button
 */
class CustomButton extends StatelessWidget {
  const CustomButton({
    Key? key,
    this.text,
    this.onPressed,
    this.width,
    this.height,
    this.buttonStyle,
    this.buttonTextStyle,
    this.isDisabled,
    this.alignment,
    this.leftIcon,
    this.rightIcon,
    this.margin,
    this.padding,
  }) : super(key: key);

  /// The text content displayed on the button
  final String? text;

  /// Callback function when button is pressed
  final VoidCallback? onPressed;

  /// Button width - can be specific value or null for auto-sizing
  final double? width;

  /// Button height
  final double? height;

  /// The style variant of the button
  final CustomButtonStyle? buttonStyle;

  /// Text style configuration for the button text
  final CustomButtonTextStyle? buttonTextStyle;

  /// Whether the button is disabled
  final bool? isDisabled;

  /// Button alignment within its parent
  final Alignment? alignment;

  /// Icon to display on the left side of the text
  final String? leftIcon;

  /// Icon to display on the right side of the text
  final String? rightIcon;

  /// External spacing around the button
  final EdgeInsetsGeometry? margin;

  /// Internal spacing within the button
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 56.h,
      margin: margin,
      alignment: alignment,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    final style = buttonStyle ?? CustomButtonStyle.fillPrimary;
    final textStyle = buttonTextStyle ?? CustomButtonTextStyle.bodyMedium;
    final disabled = isDisabled ?? false;

    switch (style.variant) {
      case CustomButtonVariant.fill:
        return _buildElevatedButton(style, textStyle, disabled);
      case CustomButtonVariant.outline:
        return _buildOutlinedButton(style, textStyle, disabled);
      case CustomButtonVariant.text:
        return _buildTextButton(style, textStyle, disabled);
    }
  }

  Widget _buildElevatedButton(
      CustomButtonStyle style,
      CustomButtonTextStyle textStyle,
      bool disabled,
      ) {
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
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 12.h,
            ),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _buildButtonContent(textStyle),
    );
  }

  /// outline buttons must render an OutlinedButton
  Widget _buildOutlinedButton(
      CustomButtonStyle style,
      CustomButtonTextStyle textStyle,
      bool disabled,
      ) {
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
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 12.h,
            ),
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
    return TextButton(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: style.backgroundColor ?? appTheme.transparentCustom,
        foregroundColor: textStyle.color ?? appTheme.blue_gray_300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.borderRadius ?? 6.h),
        ),
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 12.h,
            ),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _buildButtonContent(textStyle),
    );
  }

  Widget _buildButtonContent(CustomButtonTextStyle textStyle) {
    final hasLeftIcon = leftIcon != null && leftIcon!.isNotEmpty;
    final hasRightIcon = rightIcon != null && rightIcon!.isNotEmpty;
    final hasText = text != null && text!.isNotEmpty;

    if (!hasLeftIcon && !hasRightIcon && hasText) {
      return Text(
        text!,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        textAlign: TextAlign.center,
        style: TextStyleHelper.instance.bodyTextPlusJakartaSans
            .copyWith(color: textStyle.color),
      );
    }

    // ✅ CRITICAL FIX:
    // Row(mainAxisSize: max) can request infinite width in unbounded parents
    // (common inside horizontal scroll + Row).
    // Use min + no Flexible so the button content always shrink-wraps.
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasLeftIcon) ...[
          CustomImageView(
            imagePath: leftIcon!,
            height: textStyle.iconSize ?? 20.h,
            width: textStyle.iconSize ?? 20.h,
          ),
          if (hasText) SizedBox(width: 8.h),
        ],
        if (hasText)
          Text(
            text!,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.bodyTextPlusJakartaSans
                .copyWith(color: textStyle.color),
          ),
        if (hasRightIcon) ...[
          if (hasText) SizedBox(width: 8.h),
          CustomImageView(
            imagePath: rightIcon!,
            height: textStyle.iconSize ?? 20.h,
            width: textStyle.iconSize ?? 20.h,
          ),
        ],
      ],
    );
  }
}

/// Button style configuration
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

/// Button text style configuration
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

/// Button variant enumeration
enum CustomButtonVariant {
  fill,
  outline,
  text,
}
