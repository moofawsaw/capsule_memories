import '../core/app_export.dart';
import 'custom_icon_button.dart';

/** 
 * CustomFeatureCard - A reusable card component for displaying features with icon, title, and description
 * 
 * This component provides a consistent way to display feature information with:
 * - Customizable icon with background styling
 * - Title text with prominent typography
 * - Description text with secondary styling
 * - Flexible background and border customization
 * - Responsive design support
 * 
 * @param iconPath - Path to the icon image (required)
 * @param title - Feature title text (required)
 * @param description - Feature description text (required)  
 * @param backgroundColor - Background color of the card
 * @param borderColor - Border color of the card
 * @param borderRadius - Border radius of the card
 * @param margin - External margin of the card
 * @param iconBackgroundColor - Background color of the icon button
 * @param titleColor - Color of the title text
 * @param descriptionColor - Color of the description text
 * @param onIconTap - Callback when icon is tapped
 */
class CustomFeatureCard extends StatelessWidget {
  CustomFeatureCard({
    Key? key,
    required this.iconPath,
    required this.title,
    required this.description,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.margin,
    this.iconBackgroundColor,
    this.titleColor,
    this.descriptionColor,
    this.onIconTap,
  }) : super(key: key);

  final String iconPath;
  final String title;
  final String description;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? iconBackgroundColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.fromLTRB(10.h, 16.h, 10.h, 16.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xF716A855),
        borderRadius: BorderRadius.circular(borderRadius ?? 6.h),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.h)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconButton(
            iconPath: iconPath,
            backgroundColor: iconBackgroundColor ?? Color(0x41C1242F),
            borderRadius: 24.h,
            height: 48.h,
            width: 48.h,
            padding: EdgeInsets.all(12.h),
            margin: EdgeInsets.only(top: 2.h),
            onTap: onIconTap,
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(
                            color: titleColor ?? Color(0xFF913AF9),
                            height: 1.31),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(
                            color: descriptionColor ?? Color(0xFF94A3B8),
                            height: 1.21),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
