import '../core/app_export.dart';
import 'custom_image_view.dart';

/** 
 * CustomUserInfoRow - A reusable user information display component featuring a profile image, name, and action icon
 * 
 * This component displays user information in a horizontal layout with:
 * - Circular profile image on the left
 * - User name text in the center
 * - Optional action icon on the right
 * - Customizable styling and tap callbacks
 * - Responsive design support
 * 
 * Perfect for user lists, comment sections, participant displays, and similar UI patterns.
 */
class CustomUserInfoRow extends StatelessWidget {
  CustomUserInfoRow({
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
  }) : super(key: key);

  /// Path to the user's profile image
  final String? profileImagePath;

  /// Display name of the user
  final String? userName;

  /// Path to the action icon (optional)
  final String? actionIconPath;

  /// Callback when profile image or name is tapped
  final VoidCallback? onProfileTap;

  /// Callback when action icon is tapped
  final VoidCallback? onActionTap;

  /// Background color of the container
  final Color? backgroundColor;

  /// Border radius of the container
  final double? borderRadius;

  /// Padding inside the container
  final EdgeInsetsGeometry? padding;

  /// Margin around the container
  final EdgeInsetsGeometry? margin;

  /// Text style for the user name
  final TextStyle? textStyle;

  /// Size of the profile image
  final double? profileImageSize;

  /// Size of the action icon
  final double? actionIconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 6.h, vertical: 2.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF253153),
        borderRadius: BorderRadius.circular(borderRadius ?? 16.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfileSection(context),
          if (actionIconPath != null) _buildActionIcon(context),
        ],
      ),
    );
  }

  /// Builds the profile image and name section
  Widget _buildProfileSection(BuildContext context) {
    return InkWell(
      onTap: onProfileTap,
      borderRadius: BorderRadius.circular(16.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Image
          CustomImageView(
            // Modified: Fixed import reference
            imagePath: profileImagePath ?? ImageConstant.imgEllipse81,
            height: profileImageSize ?? 28.h,
            width: profileImageSize ?? 28.h,
            radius: BorderRadius.circular((profileImageSize ?? 28.h) / 2),
            fit: BoxFit.cover,
          ),

          // User Name
          if (userName != null) ...[
            SizedBox(width: 8.h),
            Text(
              userName!,
              style: textStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    // Modified: Fixed theme reference
                    color: appTheme.gray_50,
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the action icon section
  Widget _buildActionIcon(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 28.h),
      child: InkWell(
        onTap: onActionTap,
        borderRadius: BorderRadius.circular(10.h),
        child: CustomImageView(
          // Modified: Fixed import reference
          imagePath: actionIconPath!,
          height: actionIconSize ?? 20.h,
          width: actionIconSize ?? 20.h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}