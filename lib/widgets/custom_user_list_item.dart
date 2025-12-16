import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';

/** 
 * CustomUserListItem - A reusable user profile list item component
 * 
 * This component displays a user profile with circular image and name text in a horizontal row layout.
 * Features consistent styling, responsive design, and optional tap interaction.
 * 
 * @param imagePath - Path to the user's profile image
 * @param name - Display name of the user
 * @param onTap - Optional callback function when the item is tapped
 * @param margin - Custom margin for the entire component
 */
class CustomUserListItem extends StatelessWidget {
  CustomUserListItem({
    Key? key,
    required this.imagePath,
    required this.name,
    this.onTap,
    this.margin,
  }) : super(key: key);

  /// Path to the user's profile image
  final String imagePath;

  /// Display name of the user
  final String name;

  /// Optional callback function when the item is tapped
  final VoidCallback? onTap;

  /// Custom margin for the entire component
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ??
            EdgeInsets.only(
              top: 14.h,
              right: 16.h,
              left: 16.h,
            ),
        child: Row(
          children: [
            _buildProfileImage(),
            SizedBox(width: 12.h),
            _buildNameText(),
          ],
        ),
      ),
    );
  }

  /// Builds the circular profile image
  Widget _buildProfileImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26.h),
      child: CustomImageView(
        imagePath: imagePath,
        height: 52.h,
        width: 52.h,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds the name text with proper styling
  Widget _buildNameText() {
    return Expanded(
      child: Text(
        name,
        style: TextStyleHelper.instance.title18BoldPlusJakartaSans
            .copyWith(color: appTheme.gray_50, height: 1.28),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
