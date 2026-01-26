import '../core/app_export.dart';

/// A shared, consistent title bar used across multiple screens.
///
/// Keeps header metrics identical:
/// - height: 52.h
/// - horizontal padding: handled by parent (typically 16.h)
/// - icon: 26.h, deep_purple_A100
/// - title: title20ExtraBoldPlusJakartaSans
class StandardTitleBar extends StatelessWidget {
  const StandardTitleBar({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.trailing,
    this.iconColor,
    this.iconSize,
    this.titleStyle,
    this.height,
  });

  final IconData leadingIcon;
  final String title;
  final Widget? trailing;

  final Color? iconColor;
  final double? iconSize;
  final TextStyle? titleStyle;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 52.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            leadingIcon,
            size: iconSize ?? 26.h,
            color: iconColor ?? appTheme.deep_purple_A100,
          ),
          SizedBox(width: 6.h),
          Text(
            title,
            style: titleStyle ??
                TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

