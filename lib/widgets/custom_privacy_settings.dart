import '../core/app_export.dart';
import './custom_image_view.dart';
import './custom_switch.dart';

/**
 * CustomPrivacySettings - A comprehensive privacy settings card component that displays
 * a header section and a list of privacy preferences with toggle switches.
 */
class CustomPrivacySettings extends StatelessWidget {
  const CustomPrivacySettings({
    Key? key,
    this.headerIcon,
    this.headerTitle,
    this.privacyOptions,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  final IconData? headerIcon;
  final String? headerTitle;
  final List<CustomPrivacyOption>? privacyOptions;
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
          _buildPrivacyOptions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (headerIcon != null)
          Icon(
            headerIcon,
            size: 26.h,
            color: appTheme.gray_50,
          ),
        SizedBox(width: 8.h),
        Text(
          headerTitle ?? 'Privacy',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
      ],
    );
  }

  Widget _buildPrivacyOptions() {
    final options = privacyOptions ?? [];

    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Container(
          margin:
              EdgeInsets.only(bottom: index < options.length - 1 ? 16.h : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    if (option.description != null) ...[
                      SizedBox(height: 6.h),
                      Text(
                        option.description!,
                        style: TextStyleHelper
                            .instance.body14RegularPlusJakartaSans
                            .copyWith(
                                color: appTheme.blue_gray_300, height: 1.2),
                      ),
                    ],
                  ],
                ),
              ),
              CustomSwitch(
                value: option.isEnabled,
                onChanged: option.onChanged,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class CustomPrivacyOption {
  CustomPrivacyOption({
    required this.title,
    this.description,
    required this.isEnabled,
    required this.onChanged,
  });

  final String title;
  final String? description;
  final bool isEnabled;
  final Function(bool) onChanged;
}
