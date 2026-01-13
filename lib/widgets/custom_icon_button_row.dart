import '../core/app_export.dart';

/** 
 * CustomIconButtonRow - A reusable row component that displays two icon buttons with consistent styling
 * 
 * This component provides a horizontal layout with two icon buttons, commonly used for action bars,
 * toolbars, or control panels. Features include:
 * - Consistent spacing and alignment
 * - Configurable icons (SVG paths or Material Design icons)
 * - Optional expanded width behavior
 * - Responsive design using SizeUtils extensions
 * - Built-in tap callbacks for both buttons
 * - Theme-aware icon colors
 */
class CustomIconButtonRow extends StatelessWidget {
  final String? firstIconPath;
  final IconData? firstIcon;
  final String? secondIconPath;
  final IconData? secondIcon;
  final double? firstIconSize;
  final double? secondIconSize;
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
    this.onFirstIconTap,
    this.onSecondIconTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          iconColor: Theme.of(context).colorScheme.onSurface,
          onTap: onSecondIconTap,
        ),
      ],
    );
  }
}
