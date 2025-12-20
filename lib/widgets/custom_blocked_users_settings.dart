
import '../core/app_export.dart';
import './custom_button.dart';
import './custom_image_view.dart';

/**
 * CustomBlockedUsersSettings - Blocked users list card with unblock functionality
 */
class CustomBlockedUsersSettings extends StatelessWidget {
  const CustomBlockedUsersSettings({
    Key? key,
    this.headerIcon,
    this.headerTitle,
    this.blockedUsers,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  final String? headerIcon;
  final String? headerTitle;
  final List<BlockedUserItem>? blockedUsers;
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
          _buildBlockedUsersList(),
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
          headerTitle ?? 'Blocked Users',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
      ],
    );
  }

  Widget _buildBlockedUsersList() {
    final users = blockedUsers ?? [];

    if (users.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Text(
          'No blocked users',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      );
    }

    return Column(
      children: users.asMap().entries.map((entry) {
        final index = entry.key;
        final user = entry.value;

        return Container(
          margin: EdgeInsets.only(bottom: index < users.length - 1 ? 16.h : 0),
          child: Row(
            children: [
              CustomImageView(
                imagePath: user.avatarUrl,
                height: 42.h,
                width: 42.h,
                radius: BorderRadius.circular(21.h),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Text(
                  user.username,
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 12.h),
              CustomButton(
                text: 'unblock',
                onPressed: user.onUnblock,
                buttonStyle: CustomButtonStyle(
                  backgroundColor: Colors.transparent,
                  borderSide: BorderSide(color: appTheme.gray_50, width: 1),
                  variant: CustomButtonVariant.outline,
                ),
                buttonTextStyle: CustomButtonTextStyle(
                    color: appTheme.gray_50,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class BlockedUserItem {
  BlockedUserItem({
    required this.username,
    required this.avatarUrl,
    required this.onUnblock,
  });

  final String username;
  final String avatarUrl;
  final VoidCallback onUnblock;
}