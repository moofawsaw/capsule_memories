import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomUserListItem - A reusable user profile list item component
 *
 * Displays a circular user avatar and name in a horizontal row.
 * Avatar size is configurable while preserving backward compatibility.
 */
class CustomUserListItem extends StatelessWidget {
  CustomUserListItem({
    Key? key,
    required this.imagePath,
    required this.name,
    this.onTap,
    this.margin,
    this.avatarSize = 52, // default keeps existing behavior
  }) : super(key: key);

  /// Path to the user's profile image
  final String imagePath;

  /// Display name of the user
  final String name;

  /// Optional callback when the item is tapped
  final VoidCallback? onTap;

  /// Custom margin for the entire component
  final EdgeInsetsGeometry? margin;

  /// Avatar size in logical pixels
  final double avatarSize;

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
      borderRadius: BorderRadius.circular(avatarSize.h / 2),
      child: CustomImageView(
        imagePath: imagePath,
        height: avatarSize.h,
        width: avatarSize.h,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Builds the name text
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
