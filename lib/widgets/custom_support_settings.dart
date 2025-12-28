import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomSupportSettings - Support links card for help and feedback options
 */
class CustomSupportSettings extends StatelessWidget {
  const CustomSupportSettings({
    Key? key,
    this.headerIcon,
    this.headerTitle,
    this.supportOptions,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  final String? headerIcon;
  final String? headerTitle;
  final List<CustomSupportOption>? supportOptions;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(24.h),
      margin: margin ?? EdgeInsets.only(left: 16.h, right: 24.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(borderRadius ?? 20.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildSupportOptions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (headerIcon != null)
          CustomImageView(
            imagePath: headerIcon!,
            height: 26.h,
            width: 26.h,
          ),
        SizedBox(width: 8.h),
        Text(
          headerTitle ?? 'Support',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
      ],
    );
  }

  Widget _buildSupportOptions() {
    final options = supportOptions ?? [];

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return GestureDetector(
          onTap: option.onTap,
          child: Container(
            margin:
                EdgeInsets.only(bottom: index < options.length - 1 ? 16.h : 0),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: index < options.length - 1
                      ? appTheme.blue_gray_900
                      : Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  option.title,
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                Icon(
                  Icons.chevron_right,
                  color: appTheme.blue_gray_300,
                  size: 24.h,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CustomSupportOption {
  CustomSupportOption({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;
}
