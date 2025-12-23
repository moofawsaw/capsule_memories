import '../core/app_export.dart';
import './custom_image_view.dart';

/** 
 * CustomFriendRequestCard - A reusable card component for displaying friend requests or user notifications
 * 
 * Features:
 * - Circular profile image with customizable background
 * - User name display with proper typography
 * - Accept button with callback functionality
 * - Secondary button (Decline) with callback functionality
 * - Consistent dark theme styling
 * - Responsive design using SizeUtils extensions
 * - Flexible content with spacer for proper alignment
 */
class CustomFriendRequestCard extends StatelessWidget {
  /// Path to the user's profile image
  final String? profileImagePath;

  /// User's display name
  final String? userName;

  /// Text displayed on the action button
  final String? buttonText;

  /// Callback function when the action button is pressed
  final VoidCallback? onButtonPressed;

  /// Callback function when the secondary button (Decline) is pressed
  final VoidCallback? onSecondaryButtonTap;

  /// Callback function when the profile image is tapped
  final VoidCallback? onProfileTap;

  /// Background color of the card
  final Color? backgroundColor;

  /// Background color of the profile image container
  final Color? profileBackgroundColor;

  /// Background color of the action button
  final Color? buttonBackgroundColor;

  /// Background color of the secondary button
  final Color? secondaryButtonBackgroundColor;

  /// Text style for the user name
  final TextStyle? userNameTextStyle;

  /// Text style for the button text
  final TextStyle? buttonTextStyle;

  /// Text style for the secondary button text
  final TextStyle? secondaryButtonTextStyle;

  /// External margin for the card
  final EdgeInsetsGeometry? margin;

  const CustomFriendRequestCard({
    Key? key,
    this.profileImagePath,
    this.userName,
    this.buttonText,
    this.onButtonPressed,
    this.onSecondaryButtonTap,
    this.onProfileTap,
    this.backgroundColor,
    this.profileBackgroundColor,
    this.buttonBackgroundColor,
    this.secondaryButtonBackgroundColor,
    this.userNameTextStyle,
    this.buttonTextStyle,
    this.secondaryButtonTextStyle,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.h),
        color: backgroundColor ?? Color(0xFF151319),
      ),
      child: Row(
        children: [
          _buildProfileSection(context),
          _buildUserNameSection(),
          Spacer(),
          if (onSecondaryButtonTap != null) _buildSecondaryButton(),
          if (onSecondaryButtonTap != null) SizedBox(width: 8.h),
          _buildActionButton(),
        ],
      ),
    );
  }

  /// Builds the profile image section with circular background
  Widget _buildProfileSection(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        margin: EdgeInsets.only(left: 16.h),
        padding: EdgeInsets.all(10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.h),
          color: profileBackgroundColor ?? Color(0x41C1242F),
        ),
        child: CustomImageView(
          imagePath: profileImagePath ?? ImageConstant.imgFrame2,
          height: 28.h,
          width: 28.h,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Builds the user name text section
  Widget _buildUserNameSection() {
    return Container(
      margin: EdgeInsets.only(left: 16.h),
      child: Text(
        userName ?? 'User Name',
        style: userNameTextStyle ??
            TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50, height: 1.31),
      ),
    );
  }

  /// Builds the secondary button (Decline)
  Widget _buildSecondaryButton() {
    return Container(
      child: GestureDetector(
        onTap: onSecondaryButtonTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.h,
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.h),
            color: secondaryButtonBackgroundColor ?? Color(0xFFE53935),
          ),
          child: Text(
            'Decline',
            style: secondaryButtonTextStyle ??
                TextStyleHelper.instance.body12BoldPlusJakartaSans
                    .copyWith(color: appTheme.white_A700, height: 1.33),
          ),
        ),
      ),
    );
  }

  /// Builds the action button (Accept)
  Widget _buildActionButton() {
    return Container(
      margin: EdgeInsets.only(right: 14.h),
      child: GestureDetector(
        onTap: onButtonPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.h,
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.h),
            color: buttonBackgroundColor ?? Color(0xFF34B456),
          ),
          child: Text(
            buttonText ?? 'Accept',
            style: buttonTextStyle ??
                TextStyleHelper.instance.body12BoldPlusJakartaSans
                    .copyWith(color: appTheme.white_A700, height: 1.33),
          ),
        ),
      ),
    );
  }
}
