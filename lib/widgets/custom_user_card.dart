import '../core/app_export.dart';
import 'custom_image_view.dart';

/** 
 * CustomUserCard - A reusable user profile card component that displays user information in a horizontal layout
 * 
 * This component provides a clean, consistent way to display user profiles with:
 * - Circular profile image on the left
 * - User name text with custom styling
 * - Optional action icon on the right
 * - Dark themed background with rounded corners
 * - Flexible spacing and responsive design
 * - Customizable tap interactions for profile and action elements
 * 
 * Features:
 * - Responsive sizing using SizeUtils extensions
 * - Customizable profile image with circular clipping
 * - Flexible text styling for user names
 * - Optional action icon with tap functionality
 * - Consistent padding and border radius
 * - Dark theme optimized colors
 */
class CustomUserCard extends StatelessWidget {
  CustomUserCard({
    Key? key,
    this.profileImagePath,
    this.userName,
    this.actionIconPath,
    this.onProfileTap,
    this.onActionTap,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.textStyle,
    this.profileImageSize,
    this.actionIconSize,
    this.showActionIcon = true,
  }) : super(key: key);

  /// Path to the user's profile image
  final String? profileImagePath;

  /// The user's display name
  final String? userName;

  /// Path to the action icon (e.g., more options, message, etc.)
  final String? actionIconPath;

  /// Callback when profile image or name is tapped
  final VoidCallback? onProfileTap;

  /// Callback when action icon is tapped
  final VoidCallback? onActionTap;

  /// Background color of the card
  final Color? backgroundColor;

  /// Border radius of the card
  final double? borderRadius;

  /// Padding inside the card
  final EdgeInsetsGeometry? padding;

  /// Margin around the card
  final EdgeInsetsGeometry? margin;

  /// Text style for the user name
  final TextStyle? textStyle;

  /// Size of the profile image
  final double? profileImageSize;

  /// Size of the action icon
  final double? actionIconSize;

  /// Whether to show the action icon
  final bool showActionIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 8.h,
            vertical: 6.h,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF151319),
        borderRadius: BorderRadius.circular(borderRadius ?? 6.h),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileSection(context),
          Spacer(),
          if (showActionIcon) _buildActionIcon(context),
        ],
      ),
    );
  }

  /// Builds the profile section with image and name
  Widget _buildProfileSection(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfileImage(),
          SizedBox(width: 8.h),
          _buildUserName(),
        ],
      ),
    );
  }

  /// Builds the circular profile image
  Widget _buildProfileImage() {
    return ClipOval(
      child: CustomImageView(
        imagePath: profileImagePath ?? ImageConstant.imgEllipse81,
        height: profileImageSize ?? 36.h,
        width: profileImageSize ?? 36.h,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds the user name text
  Widget _buildUserName() {
    return Text(
      userName ?? 'Jane Doe',
      style: textStyle ??
          TextStyleHelper.instance.body14BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50, height: 18 / 14),
    );
  }

  /// Builds the action icon
  Widget _buildActionIcon(BuildContext context) {
    return GestureDetector(
      onTap: onActionTap,
      child: Container(
        margin: EdgeInsets.only(right: 10.h),
        child: CustomImageView(
          imagePath: actionIconPath ?? ImageConstant.imgIconBlueGray300,
          height: actionIconSize ?? 28.h,
          width: actionIconSize ?? 28.h,
        ),
      ),
    );
  }
}
