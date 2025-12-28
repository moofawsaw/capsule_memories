import '../core/app_export.dart';
import './custom_icon_button.dart';
import './custom_image_view.dart';

/** 
 * CustomProfileHeader - A reusable profile header component that displays user avatar, name, and email
 * 
 * This component provides:
 * - Circular avatar image with edit button overlay
 * - Letter avatar fallback when no image is available
 * - User name display with customizable styling
 * - Email address display with secondary styling
 * - Edit functionality with callback support
 * - Responsive design using SizeUtils extensions
 * - Proper spacing and alignment for profile information
 */
class CustomProfileHeader extends StatelessWidget {
  const CustomProfileHeader({
    Key? key,
    required this.avatarImagePath,
    required this.userName,
    required this.email,
    this.onEditTap,
    this.margin,
  }) : super(key: key);

  /// Path to the user's avatar image
  final String avatarImagePath;

  /// Display name of the user
  final String userName;

  /// Email address of the user
  final String email;

  /// Callback function when edit button is tapped
  final VoidCallback? onEditTap;

  /// Margin around the entire component
  final EdgeInsetsGeometry? margin;

  /// Determines if the edit button should be displayed
  bool get showEditButton => onEditTap != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 68.h),
      child: Column(
        children: [
          _buildAvatarSection(context),
          SizedBox(height: 4.h),
          _buildUserName(context),
          SizedBox(height: 8.h),

          // Show edit icon only if onEditTap is provided (current user)
          if (onEditTap != null)
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: EdgeInsets.all(2.h),
                child: CustomImageView(
                  imagePath: ImageConstant.imgEdit,
                  height: 20.h,
                  width: 20.h,
                  color: appTheme.gray_50,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the avatar section with optional edit button
  Widget _buildAvatarSection(BuildContext context) {
    final size = 96.h;

    return SizedBox(
      width: size,
      height: size + (showEditButton ? 6.h : 0),
      child: Stack(
        children: [
          // Avatar display - letter avatar or image
          _shouldShowLetterAvatar()
              ? _buildLetterAvatar(size)
              : CustomImageView(
                  imagePath: avatarImagePath,
                  height: size,
                  width: size,
                  fit: BoxFit.cover,
                  radius: BorderRadius.circular(size / 2),
                ),
          // Edit button positioned at bottom-right
          if (showEditButton)
            Positioned(
              bottom: 0,
              right: 0,
              child: CustomIconButton(
                iconPath: ImageConstant.imgEdit,
                onTap: onEditTap,
                backgroundColor: Color(0xFFD81E29).withAlpha(59),
                borderRadius: 18.h,
                height: 38.h,
                width: 38.h,
                padding: EdgeInsets.all(8.h),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds letter avatar fallback
  Widget _buildLetterAvatar(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: appTheme.color3BD81E,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getAvatarLetter(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Determines if letter avatar should be shown
  bool _shouldShowLetterAvatar() {
    return avatarImagePath.isEmpty ||
        avatarImagePath == ImageConstant.imgDefaultAvatar;
  }

  /// Gets the first letter of user name for avatar
  String _getAvatarLetter() {
    return userName.isNotEmpty ? userName[0].toUpperCase() : '?';
  }

  /// Builds the user name text
  Widget _buildUserName(BuildContext context) {
    return Text(
      userName,
      style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
          .copyWith(height: 1.29),
    );
  }

  /// Builds the email text
  Widget _buildEmail(BuildContext context) {
    return Text(
      email,
      style: TextStyleHelper.instance.title16RegularPlusJakartaSans
          .copyWith(color: appTheme.blue_gray_300, height: 1.31),
    );
  }
}
