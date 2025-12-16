import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';

/** 
 * CustomUserStatusRow - A reusable user profile row component with status badge
 * 
 * This component displays a user's profile image, name, and optional status badge in a horizontal layout.
 * Features responsive design, customizable status styling, and optional interaction callbacks.
 * 
 * @param profileImagePath - Path to the user's profile image
 * @param userName - Display name of the user  
 * @param statusText - Optional status text to display in badge
 * @param statusBackgroundColor - Background color for status badge
 * @param statusTextColor - Text color for status badge
 * @param onTap - Optional callback when row is tapped
 * @param margin - Optional margin around the entire row
 */
class CustomUserStatusRow extends StatelessWidget {
  CustomUserStatusRow({
    Key? key,
    required this.profileImagePath,
    required this.userName,
    this.statusText,
    this.statusBackgroundColor,
    this.statusTextColor,
    this.onTap,
    this.margin,
  }) : super(key: key);

  /// Path to the user's profile image
  final String profileImagePath;

  /// Display name of the user
  final String userName;

  /// Optional status text to display in badge
  final String? statusText;

  /// Background color for status badge
  final Color? statusBackgroundColor;

  /// Text color for status badge
  final Color? statusTextColor;

  /// Optional callback when row is tapped
  final VoidCallback? onTap;

  /// Optional margin around the entire row
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: EdgeInsets.symmetric(
          horizontal: 8.h,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          borderRadius: BorderRadius.circular(6.h),
        ),
        child: Row(
          children: [
            _buildProfileImage(),
            SizedBox(width: 8.h),
            _buildUserName(),
            if (statusText != null) ...[
              SizedBox(width: 8.h),
              _buildStatusBadge(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return CustomImageView(
      imagePath: profileImagePath,
      height: 36.h,
      width: 36.h,
      radius: BorderRadius.circular(18.h),
      fit: BoxFit.cover,
    );
  }

  Widget _buildUserName() {
    return Expanded(
      child: Text(
        userName,
        style: TextStyleHelper.instance.body14BoldPlusJakartaSans
            .copyWith(color: appTheme.gray_50, height: 1.29),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.h,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: statusBackgroundColor ?? Color(0xFF221730),
        borderRadius: BorderRadius.circular(6.h),
      ),
      child: Text(
        statusText!,
        style: TextStyleHelper.instance.body12BoldPlusJakartaSans.copyWith(
            color: statusTextColor ?? Color(0xFFFF7A00), height: 1.33),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
