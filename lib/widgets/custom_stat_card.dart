import '../core/app_export.dart';

/** CustomStatCard - A reusable statistic display card component that shows a count value with a descriptive label in a styled container. Features customizable count and label text, consistent dark theme styling with rounded corners, responsive typography and spacing, and compact layout optimized for stat displays. */
class CustomStatCard extends StatelessWidget {
  const CustomStatCard({
    Key? key,
    required this.count,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.countTextStyle,
    this.labelTextStyle,
    this.spacing,
  }) : super(key: key);

  /// The numeric count value to display (e.g., "29", "1.2k")
  final String count;

  /// The descriptive label text (e.g., "followers", "following")
  final String label;

  /// Background color of the container
  final Color? backgroundColor;

  /// Color for both count and label text
  final Color? textColor;

  /// Border radius for the container corners
  final double? borderRadius;

  /// Padding inside the container
  final EdgeInsetsGeometry? padding;

  /// Custom text style for the count number
  final TextStyle? countTextStyle;

  /// Custom text style for the label
  final TextStyle? labelTextStyle;

  /// Spacing between count and label
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(8.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF151319),
        borderRadius: BorderRadius.circular(borderRadius ?? 8.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: countTextStyle ??
                TextStyleHelper.instance.title18BoldPlusJakartaSans
                    .copyWith(color: textColor ?? Color(0xFFF8FAFC)),
          ),
          SizedBox(width: spacing ?? 2.h),
          Text(
            label,
            style: labelTextStyle ??
                TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: textColor ?? Color(0xFFF8FAFC)),
          ),
        ],
      ),
    );
  }
}
