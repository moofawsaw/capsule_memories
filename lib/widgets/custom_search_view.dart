import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomSearchView - A reusable search input component with customizable styling
 * 
 * Features:
 * - Dark themed search field with rounded borders
 * - Left-aligned search icon
 * - Customizable placeholder text
 * - Built-in validation support
 * - Responsive design using SizeUtils
 * - Configurable margins and callbacks
 * 
 * @param controller - TextEditingController for managing input text
 * @param placeholder - Placeholder text displayed in the search field
 * @param validator - Optional validation function for form validation
 * @param onChanged - Callback function triggered when text changes
 * @param onFieldSubmitted - Callback function triggered when search is submitted
 * @param margin - Optional margin around the search view
 * @param enabled - Whether the search field is enabled for input
 */
class CustomSearchView extends StatelessWidget {
  CustomSearchView({
    Key? key,
    this.controller,
    this.placeholder,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.margin,
    this.enabled = true,
  }) : super(key: key);

  /// Controller for managing the text input
  final TextEditingController? controller;

  /// Placeholder text shown in the search field
  final String? placeholder;

  /// Validation function for form validation
  final String? Function(String?)? validator;

  /// Callback function when text changes
  final Function(String)? onChanged;

  /// Callback function when search is submitted
  final Function(String)? onFieldSubmitted;

  /// Margin around the search view
  final EdgeInsets? margin;

  /// Whether the search field is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyleHelper.instance.title16RegularPlusJakartaSans
            .copyWith(color: appTheme.blue_gray_300, height: 1.31),
        decoration: InputDecoration(
          hintText: placeholder ?? "Search...",
          hintStyle: TextStyleHelper.instance.title16RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300, height: 1.31),
          prefixIcon: Container(
            padding: EdgeInsets.all(14.h),
            child: Icon(
              Icons.search,
              size: 20.h,
              color: appTheme.blue_gray_300,
            ),
          ),
          filled: true,
          fillColor: appTheme.gray_900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.h),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.h),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.h),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.h),
            borderSide: BorderSide(
              color: appTheme.redCustom,
              width: 1.h,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.h),
            borderSide: BorderSide(
              color: appTheme.redCustom,
              width: 1.h,
            ),
          ),
          contentPadding: EdgeInsets.only(
            top: 14.h,
            right: 16.h,
            bottom: 14.h,
            left: 36.h,
          ),
        ),
        keyboardType: TextInputType.text,
      ),
    );
  }
}
