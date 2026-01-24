import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomEditText is a reusable text input field component that provides
 * comprehensive customization options including icons, validation, password fields,
 * and responsive design. Supports various input types and visual configurations.
 * 
 * @param controller - TextEditingController for managing text input
 * @param hintText - Placeholder text displayed when field is empty
 * @param validator - Validation function for form validation
 * @param textStyle - Custom text style for input text
 * @param hintStyle - Custom text style for hint/placeholder text
 * @param prefixIcon - Icon or image displayed on the left side
 * @param suffixIcon - Icon or image displayed on the right side
 * @param isPassword - Whether this field should obscure text input
 * @param keyboardType - Type of keyboard to display for input
 * @param maxLines - Maximum number of lines for text input
 * @param fillColor - Background fill color of the input field
 * @param borderRadius - Border radius for the input field decoration
 * @param contentPadding - Internal padding for the input field content
 * @param enabled - Whether the input field is enabled for interaction
 * @param readOnly - Whether the input field is read-only
 * @param onTap - Callback function when the field is tapped
 * @param focusNode - FocusNode for managing input focus state
 * @param autofillHints - List of autofill hints for browser/system autofill
 */
class CustomEditText extends StatefulWidget {
  CustomEditText({
    Key? key,
    this.controller,
    this.hintText,
    this.validator,
    this.textStyle,
    this.hintStyle,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.maxLines,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.autofillHints,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);

  final TextEditingController? controller;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  /// ✅ Can be String (asset/url) OR IconData (Material icon)
  final Object? prefixIcon;
  /// ✅ Can be String (asset/url) OR IconData (Material icon)
  final Object? suffixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Color? fillColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  final Color? iconColor;
  final double? iconSize;

  @override
  State<CustomEditText> createState() => _CustomEditTextState();
}

class _CustomEditTextState extends State<CustomEditText> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = widget.iconColor ?? appTheme.blue_gray_300;
    final effectiveIconSize = widget.iconSize ?? 18.h;

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: widget.isPassword ? _isObscured : false,
      keyboardType: widget.keyboardType ?? _getKeyboardType(),
      maxLines: widget.isPassword ? 1 : (widget.maxLines ?? 1),
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      focusNode: widget.focusNode,
      autofillHints: widget.autofillHints,
      style: widget.textStyle ?? _getDefaultTextStyle(),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle ?? _getDefaultHintStyle(),
        filled: true,
        fillColor: widget.fillColor ?? appTheme.gray_900,
        contentPadding: widget.contentPadding ?? _getDefaultPadding(),
        prefixIcon: widget.prefixIcon != null
            ? _buildAnyIcon(
                widget.prefixIcon!,
                padding: EdgeInsets.symmetric(horizontal: 12.h),
                color: effectiveIconColor,
                size: effectiveIconSize,
              )
            : null,
        suffixIcon: _buildSuffixIcon(
          color: effectiveIconColor,
          size: effectiveIconSize,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.h),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.h),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.h),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.h),
          borderSide: BorderSide(color: appTheme.redCustom, width: 1.h),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.h),
          borderSide: BorderSide(color: appTheme.redCustom, width: 1.h),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon({required Color color, required double size}) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          color: color,
          size: size,
        ),
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
        },
      );
    } else if (widget.suffixIcon != null) {
      return _buildAnyIcon(
        widget.suffixIcon!,
        padding: EdgeInsets.symmetric(horizontal: 12.h),
        color: color,
        size: size,
      );
    }
    return null;
  }

  Widget _buildAnyIcon(
    Object iconValue, {
    required EdgeInsetsGeometry padding,
    required Color color,
    required double size,
  }) {
    if (iconValue is IconData) {
      return Padding(
        padding: padding,
        child: Icon(iconValue, color: color, size: size),
      );
    }

    final path = iconValue.toString();
    return Padding(
      padding: padding,
      child: CustomImageView(
        imagePath: path,
        height: size,
        width: size,
        fit: BoxFit.contain,
        color: color,
      ),
    );
  }

  TextInputType _getKeyboardType() {
    if (widget.hintText?.toLowerCase().contains('email') == true) {
      return TextInputType.emailAddress;
    } else if (widget.isPassword) {
      return TextInputType.visiblePassword;
    } else if (widget.maxLines != null && widget.maxLines! > 1) {
      return TextInputType.multiline;
    }
    return TextInputType.text;
  }

  TextStyle _getDefaultTextStyle() {
    return TextStyleHelper.instance.title16RegularPlusJakartaSans
        .copyWith(color: appTheme.blue_gray_300, height: 1.3);
  }

  TextStyle _getDefaultHintStyle() {
    return TextStyleHelper.instance.title16RegularPlusJakartaSans
        .copyWith(color: appTheme.blue_gray_300, height: 1.3);
  }

  EdgeInsetsGeometry _getDefaultPadding() {
    if (widget.prefixIcon != null) {
      return EdgeInsets.fromLTRB(32.h, 14.h, 16.h, 14.h);
    }
    return EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h);
  }
}
