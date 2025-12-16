import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';

/** 
 * CustomUserProfile - A reusable user profile card component that displays user avatar, name, and email
 * 
 * This component provides a horizontal layout with user avatar image on the left and user information
 * (name and email) on the right. Supports circular or square avatar images, customizable sizing,
 * and optional tap interactions.
 * 
 * Features:
 * - Flexible avatar image handling with CustomImageView
 * - Responsive sizing using SizeUtils extensions  
 * - Customizable avatar shape (circular or square)
 * - Optional tap callback for user interaction
 * - Consistent text styling with proper hierarchy
 * - Configurable margins for layout flexibility
 */
class CustomUserProfile extends StatelessWidget {
  CustomUserProfile({
    Key? key,
    required this.userName,
    required this.userEmail,
    this.avatarImagePath,
    this.isAvatarCircular,
    this.avatarSize,
    this.onTap,
    this.margin,
  }) : super(key: key);

  /// User's display name
  final String userName;

  /// User's email address
  final String userEmail;

  /// Path to user's avatar image
  final String? avatarImagePath;

  /// Whether avatar should be circular (true) or square (false)
  final bool? isAvatarCircular;

  /// Size of the avatar image
  final double? avatarSize;

  /// Callback when user profile is tapped
  final VoidCallback? onTap;

  /// External margin for the component
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.h),
        child: Row(
          children: [
            _buildAvatarImage(),
            SizedBox(width: 12.h),
            Expanded(
              child: _buildUserInfo(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the user avatar image
  Widget _buildAvatarImage() {
    final size = avatarSize ?? 52.h;
    final isCircular = isAvatarCircular ?? true;

    return CustomImageView(
      imagePath: avatarImagePath ?? ImageConstant.imgEllipse852x52,
      height: size,
      width: size,
      radius: isCircular
          ? BorderRadius.circular(size / 2)
          : BorderRadius.circular(8.h),
      fit: BoxFit.cover,
    );
  }

  /// Builds the user information column (name and email)
  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName,
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 2.h),
        Text(
          userEmail,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }
}
