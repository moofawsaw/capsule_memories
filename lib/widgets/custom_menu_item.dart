import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomMenuItem - A reusable menu item component with icon and text
 * 
 * This component creates a tappable menu item with an icon and text label,
 * commonly used in navigation drawers, settings screens, and option lists.
 * 
 * Features:
 * - Customizable icon and text content
 * - Configurable colors and styling
 * - Built-in tap handling with navigation support
 * - Responsive spacing using SizeUtils extensions
 * - Flexible margin and padding configuration
 * 
 * @param iconPath - Path to the menu item icon (required)
 * @param title - Text label for the menu item (required)
 * @param onTap - Callback function when item is tapped
 * @param iconColor - Color for the icon
 * @param textColor - Color for the text label
 * @param textStyle - Custom text styling
 * @param margin - External spacing around the component
 * @param padding - Internal padding within the component
 * @param iconSize - Size of the icon
 * @param spacing - Space between icon and text
 */
class CustomMenuItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;
  final double? spacing;

  const CustomMenuItem({
    Key? key,
    required this.iconPath,
    required this.title,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.textStyle,
    this.margin,
    this.padding,
    this.iconSize,
    this.spacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 34.h, left: 8.h, right: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.h),
        child: Container(
          padding: padding ?? EdgeInsets.all(8.h),
          child: Row(
            children: [
              CustomImageView(
                imagePath: iconPath,
                height: iconSize ?? 24.h,
                width: iconSize ?? 24.h,
                color: iconColor,
              ),
              SizedBox(width: spacing ?? 8.h),
              Expanded(
                child: Text(
                  title,
                  style: textStyle ?? _getDefaultTextStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _getDefaultTextStyle(BuildContext context) {
    return TextStyleHelper.instance.title16BoldPlusJakartaSans
        .copyWith(color: textColor ?? Color(0xFFEF4444), height: 1.31);
  }
}
