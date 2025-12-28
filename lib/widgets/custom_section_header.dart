import '../core/app_export.dart';
import './custom_image_view.dart';

/** 
 * CustomSectionHeader - A reusable section header component that displays an icon with accompanying text
 * 
 * This component provides a consistent layout for section titles throughout the app, featuring:
 * - Flexible icon and text content
 * - Responsive margin and spacing using SizeUtils
 * - Customizable text styling while maintaining design consistency
 * - Optimal layout using Row widget with proper spacing
 * 
 * Perfect for content section headers, category titles, and navigation labels.
 */
class CustomSectionHeader extends StatelessWidget {
  CustomSectionHeader({
    Key? key,
    this.iconPath,
    this.text,
    this.textStyle,
    this.margin,
    this.iconSize,
    this.spacing,
    this.onTap,
  }) : super(key: key);

  /// Path to the icon image (SVG, PNG, etc.)
  final String? iconPath;

  /// Text content to display next to the icon
  final String? text;

  /// Custom text style for the label
  final TextStyle? textStyle;

  /// Margin around the entire component
  final EdgeInsetsGeometry? margin;

  /// Size of the icon
  final double? iconSize;

  /// Spacing between icon and text
  final double? spacing;

  /// Optional tap callback for the entire component
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ??
          EdgeInsets.only(
            top: 30.h,
            left: 24.h,
            right: 24.h,
          ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null)
              CustomImageView(
                imagePath: iconPath!,
                height: iconSize ?? 22.h,
                width: iconSize ?? 22.h,
              ),
            if (iconPath != null && text != null)
              SizedBox(width: spacing ?? 8.h),
            if (text != null)
              Expanded(
                child: Text(
                  text!,
                  style: textStyle ??
                      TextStyleHelper.instance.title16BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50, height: 1.25),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
