import '../core/app_export.dart';

/** 
 * CustomQrInfoCard - A reusable information card component for QR code related content
 * 
 * This component displays an icon button with title and description text in a vertical layout.
 * It's designed for showcasing QR code functionality with consistent styling and flexible content.
 * 
 * Features:
 * - Consistent icon button styling with semi-transparent background
 * - Customizable title and description text
 * - Flexible margin configuration
 * - Configurable text alignment for descriptions
 * - Responsive design using SizeUtils extensions
 * - Proper spacing between elements
 * 
 * @param title The main heading text displayed below the icon
 * @param description The subtitle text providing additional information
 * @param margin Optional margin around the entire component
 * @param textAlign Text alignment for the description (defaults to left)
 */
class CustomQrInfoCard extends StatelessWidget {
  const CustomQrInfoCard({
    Key? key,
    required this.title,
    required this.description,
    this.margin,
    this.textAlign,
  }) : super(key: key);

  /// The main heading text displayed below the icon button
  final String title;

  /// The description text providing additional context or instructions
  final String description;

  /// Optional margin around the entire component
  final EdgeInsetsGeometry? margin;

  /// Text alignment for the description text
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconButton(
            icon: Icons.qr_code_2_rounded,
            height: 48.h,
            width: 48.h,
            padding: EdgeInsets.all(12.h),
            backgroundColor: appTheme.color41C124,
            borderRadius: 24.h,
            iconColor: appTheme.gray_50,
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans
                .copyWith(height: 1.3),
          ),
          SizedBox(height: textAlign == TextAlign.center ? 2.h : 0.h),
          Text(
            description,
            textAlign: textAlign ?? TextAlign.left,
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(
                    color: appTheme.blue_gray_300,
                    height: textAlign == TextAlign.center ? 1.25 : 1.31),
          ),
        ],
      ),
    );
  }
}
