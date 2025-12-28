import '../core/app_export.dart';
import './custom_image_view.dart';
import './custom_switch.dart';

/**
 * CustomSettingsRow - A reusable settings row component that displays an icon, title, description, and toggle switch.
 * 
 * This component provides a consistent layout for settings items with:
 * - Left-aligned icon with customizable source
 * - Title and description text in a vertical column
 * - Right-aligned switch toggle
 * - Responsive design with proper spacing and styling
 * - Customizable margins and switch behavior
 * 
 * @param iconPath - Path to the icon image (SVG or other formats)
 * @param title - Main title text for the setting
 * @param description - Descriptive text below the title
 * @param switchValue - Current state of the toggle switch
 * @param onSwitchChanged - Callback function when switch state changes
 * @param margin - Optional margin around the entire component
 * @param isEnabled - Whether the setting row is interactive
 * @param iconColor - Optional color to apply to the icon
 * @param useIconData - Whether to use IconData instead of image path
 * @param iconData - IconData to use when useIconData is true
 */
class CustomSettingsRow extends StatelessWidget {
  const CustomSettingsRow({
    Key? key,
    this.iconPath,
    required this.title,
    required this.description,
    required this.switchValue,
    required this.onSwitchChanged,
    this.margin,
    this.isEnabled = true,
    this.iconColor,
    this.useIconData = false,
    this.iconData,
  }) : super(key: key);

  /// Path to the icon image displayed on the left
  final String? iconPath;

  /// Main title text for the setting
  final String title;

  /// Descriptive text shown below the title
  final String description;

  /// Current state of the toggle switch
  final bool switchValue;

  /// Callback function triggered when switch value changes
  final Function(bool) onSwitchChanged;

  /// Optional margin around the component
  final EdgeInsetsGeometry? margin;

  /// Whether the setting row is interactive
  final bool isEnabled;

  /// Optional color to apply to the icon
  final Color? iconColor;

  /// Whether to use IconData instead of image path
  final bool useIconData;

  /// IconData to use when useIconData is true
  final IconData? iconData;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.symmetric(
        vertical: 18.h,
        horizontal: 12.h,
      ),
      decoration: BoxDecoration(
        color: appTheme.gray_900,
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Row(
        children: [
          // Left icon
          if (useIconData && iconData != null)
            Icon(
              iconData,
              size: 28.h,
              color: iconColor ?? appTheme.gray_50,
            )
          else
            CustomImageView(
              imagePath: iconPath ?? '',
              height: 28.h,
              width: 28.h,
              color: iconColor,
            ),

          SizedBox(width: 12.h),

          // Title and description column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50, height: 1.28),
                ),
                SizedBox(height: 6.h),
                Text(
                  description,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.29),
                ),
              ],
            ),
          ),

          // Right switch
          CustomSwitch(
            value: switchValue,
            onChanged: isEnabled ? onSwitchChanged : (value) {},
            isEnabled: isEnabled,
          ),
        ],
      ),
    );
  }
}
