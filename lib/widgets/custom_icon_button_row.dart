import '../core/app_export.dart';

class CustomIconButtonRow extends StatelessWidget {
  final String? firstIconPath;
  final IconData? firstIcon;
  final String? secondIconPath;
  final IconData? secondIcon;
  final double? firstIconSize;
  final double? secondIconSize;
  final Color? firstIconColor;   // ✅ add
  final Color? secondIconColor;  // ✅ add
  final VoidCallback? onFirstIconTap;
  final VoidCallback? onSecondIconTap;

  const CustomIconButtonRow({
    Key? key,
    this.firstIconPath,
    this.firstIcon,
    this.secondIconPath,
    this.secondIcon,
    this.firstIconSize,
    this.secondIconSize,
    this.firstIconColor,   // ✅ add
    this.secondIconColor,  // ✅ add
    this.onFirstIconTap,
    this.onSecondIconTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        CustomIconButton(
          height: 44.h,
          width: 44.h,
          iconPath: firstIconPath,
          icon: firstIcon,
          backgroundColor: appTheme.gray_900_01.withAlpha(179),
          borderRadius: 22.h,
          iconSize: firstIconSize ?? 24.h,
          iconColor: firstIconColor ?? defaultIconColor, // ✅ apply
          onTap: onFirstIconTap,
        ),
        SizedBox(width: 8.h),
        CustomIconButton(
          height: 44.h,
          width: 44.h,
          iconPath: secondIconPath,
          icon: secondIcon,
          backgroundColor: appTheme.gray_900_01.withAlpha(179),
          borderRadius: 22.h,
          iconSize: secondIconSize ?? 24.h,
          iconColor: secondIconColor ?? defaultIconColor, // ✅ apply
          onTap: onSecondIconTap,
        ),
      ],
    );
  }
}