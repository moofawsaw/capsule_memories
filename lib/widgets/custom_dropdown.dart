import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomDropdown is a reusable dropdown component with customizable icons and styling.
 * It extends DropdownButtonFormField to provide form validation support.
 * 
 * @param items - List of dropdown items to display
 * @param value - Currently selected value
 * @param onChanged - Callback function when selection changes
 * @param placeholder - Placeholder text when no item is selected
 * @param leftIcon - Optional left icon path
 * @param rightIcon - Optional right icon path  
 * @param validator - Optional validation function for form validation
 * @param fillColor - Background color of the dropdown
 * @param borderRadius - Border radius for the dropdown
 * @param textStyle - Text style for the dropdown text
 * @param padding - Internal padding for the dropdown
 * @param margin - External margin for the dropdown
 */
class CustomDropdown<T> extends StatelessWidget {
  const CustomDropdown({
    Key? key,
    required this.items,
    this.value,
    required this.onChanged,
    this.placeholder,
    this.leftIcon,
    this.rightIcon,
    this.validator,
    this.fillColor,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.margin,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);

  /// List of dropdown items
  final List<DropdownMenuItem<T>> items;

  /// Currently selected value
  final T? value;

  /// Callback when selection changes
  final ValueChanged<T?> onChanged;

  /// Placeholder text when no selection
  final String? placeholder;

  /// ✅ Can be String (asset/url) OR IconData (Material icon)
  final Object? leftIcon;

  /// ✅ Can be String (asset/url) OR IconData (Material icon)
  final Object? rightIcon;

  /// Form validation function
  final String? Function(T?)? validator;

  /// Background fill color
  final Color? fillColor;

  /// Border radius
  final double? borderRadius;

  /// Text style for dropdown
  final TextStyle? textStyle;

  /// Internal padding
  final EdgeInsetsGeometry? padding;

  /// External margin
  final EdgeInsetsGeometry? margin;

  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? appTheme.blue_gray_300;
    final effectiveIconSize = iconSize ?? 20.h;

    return Container(
      margin: margin ?? EdgeInsets.only(top: 20.h),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: placeholder ?? "Select from group...",
          hintStyle: textStyle ??
              TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
          filled: true,
          fillColor: fillColor ?? Color(0xFF1B181E),
          prefixIcon: leftIcon != null
              ? Padding(
                  padding: EdgeInsets.all(12.h),
                  child: _buildAnyIcon(
                    leftIcon!,
                    color: effectiveIconColor,
                    size: effectiveIconSize,
                  ),
                )
              : null,
          suffixIcon: rightIcon != null
              ? Padding(
                  padding: EdgeInsets.all(12.h),
                  child: _buildAnyIcon(
                    rightIcon!,
                    color: effectiveIconColor,
                    size: effectiveIconSize,
                  ),
                )
              : null,
          contentPadding: padding ??
              EdgeInsets.fromLTRB(
                leftIcon != null ? 42.h : 16.h,
                16.h,
                rightIcon != null ? 34.h : 16.h,
                16.h,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8.h),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8.h),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8.h),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8.h),
            borderSide: BorderSide(color: appTheme.redCustom, width: 1.h),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8.h),
            borderSide: BorderSide(color: appTheme.redCustom, width: 1.h),
          ),
        ),
        style: textStyle ??
            TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
        dropdownColor: fillColor ?? Color(0xFF1B181E),
        icon: SizedBox.shrink(),
        isExpanded: true,
      ),
    );
  }

  Widget _buildAnyIcon(Object iconValue,
      {required Color color, required double size}) {
    if (iconValue is IconData) {
      return Icon(iconValue, color: color, size: size);
    }

    final path = iconValue.toString();
    return CustomImageView(
      imagePath: path,
      height: size,
      width: size,
      fit: BoxFit.contain,
      color: color,
    );
  }
}
