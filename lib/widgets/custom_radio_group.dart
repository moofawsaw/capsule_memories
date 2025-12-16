import 'package:flutter/material.dart';
import '../core/app_export.dart';

/**
 * CustomRadioGroup - A reusable radio button group component
 * 
 * A flexible radio group widget that displays a list of selectable options
 * with consistent styling and proper spacing. Supports generic types for
 * flexible value handling.
 * 
 * @param options - List of radio options to display
 * @param selectedValue - Currently selected value
 * @param onChanged - Callback when selection changes
 * @param textStyle - Custom text style for labels
 * @param activeColor - Color for active radio button
 * @param spacing - Vertical spacing between options
 */
class CustomRadioGroup<T> extends StatelessWidget {
  CustomRadioGroup({
    Key? key,
    required this.options,
    this.selectedValue,
    this.onChanged,
    this.textStyle,
    this.activeColor,
    this.spacing,
  }) : super(key: key);

  /// List of radio options to display
  final List<CustomRadioOption<T>> options;

  /// Currently selected value
  final T? selectedValue;

  /// Callback function triggered when selection changes
  final ValueChanged<T?>? onChanged;

  /// Custom text style for option labels
  final TextStyle? textStyle;

  /// Color for active radio button state
  final Color? activeColor;

  /// Vertical spacing between radio options
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isFirst = index == 0;

        return Column(
          children: [
            if (!isFirst) SizedBox(height: spacing ?? 14.h),
            RadioListTile<T>(
              value: option.value,
              groupValue: selectedValue,
              onChanged: onChanged,
              title: Text(
                option.label,
                style: textStyle ?? _defaultTextStyle,
              ),
              activeColor: activeColor ?? Color(0xFF52D1C6),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        );
      }),
    );
  }

  /// Default text style for radio option labels
  TextStyle get _defaultTextStyle =>
      TextStyleHelper.instance.title16BoldPlusJakartaSans
          .copyWith(color: appTheme.gray_50, height: 1.31);
}

/// Data model for radio option items
class CustomRadioOption<T> {
  CustomRadioOption({
    required this.value,
    required this.label,
  });

  /// The value associated with this radio option
  final T value;

  /// Display label for the radio option
  final String label;
}
