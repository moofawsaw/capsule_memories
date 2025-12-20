
import '../core/app_export.dart';
import './custom_icon_button.dart';

/** 
 * CustomInfoRow - A reusable information display component that combines an icon button with descriptive text
 * 
 * This component is designed to display informational content with a consistent visual style,
 * featuring a circular icon button with a translucent background and accompanying text.
 * Perfect for onboarding tips, feature descriptions, or instructional content.
 * 
 * Features:
 * - Consistent icon button styling with customizable icons
 * - Flexible text content with responsive width handling
 * - Configurable spacing and margins
 * - Responsive design using SizeUtils extensions
 * - Optional callback for icon button interactions
 */
class CustomInfoRow extends StatelessWidget {
  const CustomInfoRow({
    Key? key,
    required this.iconPath,
    required this.text,
    this.onIconTap,
    this.textWidth,
    this.spacing,
    this.margin,
    this.useFlexText = false,
  }) : super(key: key);

  /// Path to the icon image (SVG or other formats)
  final String iconPath;

  /// Descriptive text content to display next to the icon
  final String text;

  /// Optional callback when the icon button is tapped
  final VoidCallback? onIconTap;

  /// Optional width constraint for the text (as percentage of available space)
  /// Example: 0.82 for 82% width
  final double? textWidth;

  /// Spacing between icon and text (defaults to 12.h)
  final double? spacing;

  /// External margin for the entire row
  final EdgeInsetsGeometry? margin;

  /// Whether to use flexible text layout instead of fixed width
  final bool useFlexText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconButton(
            iconPath: iconPath,
            onTap: onIconTap,
            height: 48.h,
            width: 48.h,
            backgroundColor: appTheme.color41C124,
            borderRadius: 24.h,
            padding: EdgeInsets.all(12.h),
          ),
          SizedBox(width: spacing ?? 12.h),
          Expanded(
            child: _buildTextWidget(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTextWidget(BuildContext context) {
    final textWidget = Text(
      text,
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans
          .copyWith(color: appTheme.blue_gray_300, height: 1.2),
      maxLines: null,
      overflow: TextOverflow.visible,
    );

    if (textWidth != null) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * textWidth!,
        child: textWidget,
      );
    }

    return textWidget;
  }
}
