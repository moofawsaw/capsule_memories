import '../core/app_export.dart';

/** 
 * CustomHeaderSection - A reusable header component that displays a title and description text
 * with consistent styling and responsive design.
 * 
 * Features:
 * - Consistent typography with Plus Jakarta Sans font family
 * - Responsive sizing using SizeUtils extensions  
 * - Customizable margin for flexible positioning
 * - Proper text alignment (title left, description center)
 * - Support for variable content lengths
 * 
 * @param title - The main heading text to display
 * @param description - The descriptive text shown below the title
 * @param margin - Optional custom margin around the component
 */
class CustomHeaderSection extends StatelessWidget {
  const CustomHeaderSection({
    Key? key,
    required this.title,
    required this.description,
    this.margin,
  }) : super(key: key);

  /// The main heading text displayed prominently
  final String title;

  /// The descriptive text shown below the title
  final String description;

  /// Optional margin around the entire component
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ??
          EdgeInsets.only(
            top: 32.h,
            left: 52.h,
            right: 52.h,
          ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                .copyWith(height: 1.29),
          ),
          SizedBox(height: 2.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300, height: 1.25),
          ),
        ],
      ),
    );
  }
}
