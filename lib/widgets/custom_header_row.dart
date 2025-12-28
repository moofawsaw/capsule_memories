import '../core/app_export.dart';
import './custom_image_view.dart';

/** 
 * CustomHeaderRow - A reusable header component with title text and trailing icon button
 * 
 * This component provides a consistent header layout with:
 * - Left-aligned or center-aligned title text with customizable content
 * - Right-aligned icon button with tap functionality
 * - Responsive design using SizeUtils extensions
 * - Configurable margins for flexible placement
 * - Consistent styling following app design system
 */
class CustomHeaderRow extends StatelessWidget {
  CustomHeaderRow({
    Key? key,
    required this.title,
    this.onIconTap,
    this.textAlignment,
    this.margin,
    this.iconPath,
  }) : super(key: key);

  /// The title text to display in the header
  final String title;

  /// Callback function when the trailing icon is tapped
  final VoidCallback? onIconTap;

  /// Text alignment for the title (defaults to left alignment)
  final TextAlign? textAlignment;

  /// Custom margin around the entire component
  final EdgeInsetsGeometry? margin;

  /// Custom icon path (defaults to standard close/back icon)
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 12.h, vertical: 18.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans,
              textAlign: textAlignment ?? TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: 22.h),
          GestureDetector(
            onTap: onIconTap,
            child: CustomImageView(
              imagePath: iconPath ?? ImageConstant.imgFrame19,
              height: 42.h,
              width: 42.h,
            ),
          ),
        ],
      ),
    );
  }
}
