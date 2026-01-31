import '../core/app_export.dart';

/** 
 * CustomNavigationDrawer - A flexible navigation drawer component that displays a vertical list of menu items
 * 
 * This component provides:
 * - Configurable list of navigation menu items with icons and labels
 * - Consistent styling and spacing between items
 * - Navigation callback support for each menu item
 * - Responsive design using SizeUtils extensions
 * - Customizable margins and text styling
 */
class CustomNavigationDrawer extends StatelessWidget {
  CustomNavigationDrawer({
    Key? key,
    required this.menuItems,
    this.margin,
    this.itemSpacing,
    this.iconTextSpacing,
    this.textStyle,
    this.iconSize,
    this.itemPadding,
    this.itemBorderRadius,
  }) : super(key: key);

  /// List of navigation menu items to display
  final List<CustomNavigationDrawerItem> menuItems;

  /// Margin around the entire drawer content
  final EdgeInsetsGeometry? margin;

  /// Spacing between menu items
  final double? itemSpacing;

  /// Spacing between icon and text in each item
  final double? iconTextSpacing;

  /// Text style for menu item labels
  final TextStyle? textStyle;

  /// Size of the icons
  final double? iconSize;

  /// Padding inside each tappable row (controls hit target size)
  final EdgeInsetsGeometry? itemPadding;

  /// Border radius for tap feedback
  final BorderRadius? itemBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 30.h, left: 0.h),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          menuItems.length,
          (index) => Container(
            margin: EdgeInsets.only(
              bottom: index < menuItems.length - 1 ? (itemSpacing ?? 12.h) : 0,
            ),
            child: _buildMenuItem(menuItems[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(CustomNavigationDrawerItem item) {
    final BorderRadius radius = itemBorderRadius ?? BorderRadius.circular(10.h);

    // Use InkWell (not GestureDetector) so the entire row (including icon)
    // is consistently tappable with proper hit testing + feedback.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: radius,
        child: Padding(
          padding: itemPadding ??
              EdgeInsets.symmetric(
                vertical: 10.h,
                horizontal: 0.h,
              ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: iconSize ?? 24.h,
                color: appTheme.gray_50,
              ),
              SizedBox(width: iconTextSpacing ?? 8.h),
              Expanded(
                child: Text(
                  item.label,
                  style: textStyle ??
                      TextStyleHelper.instance.title16BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                ),
              ),
              if (item.trailing != null) ...[
                SizedBox(width: 10.h),
                item.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for navigation drawer menu items
class CustomNavigationDrawerItem {
  CustomNavigationDrawerItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  /// Material Design icon for the menu item
  final IconData icon;

  /// Text label for the menu item
  final String label;

  /// Callback function when item is tapped
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g., badge)
  final Widget? trailing;
}
