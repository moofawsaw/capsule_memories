import '../core/app_export.dart';
import './custom_button.dart';
import './custom_image_view.dart';

/** 
 * CustomUserList - A flexible user list component that displays user profiles with customizable actions
 * 
 * This component renders a vertical list of user cards, each containing:
 * - Circular profile image
 * - User name and follower count
 * - Configurable action (button or icon)
 * 
 * Features:
 * - Support for both button and icon actions
 * - Responsive design using SizeUtils extensions
 * - Customizable styling and callbacks
 * - Efficient list rendering with proper spacing
 * - Profile navigation and action callbacks
 */
class CustomUserList extends StatelessWidget {
  const CustomUserList({
    Key? key,
    required this.users,
    this.actionType,
    this.onUserTap,
    this.onActionTap,
    this.spacing,
    this.margin,
  }) : super(key: key);

  /// List of user data to display
  final List<CustomUserItem> users;

  /// Type of action to show (button or icon)
  final CustomUserActionType? actionType;

  /// Callback when user profile is tapped
  final Function(CustomUserItem)? onUserTap;

  /// Callback when action button/icon is tapped
  final Function(CustomUserItem)? onActionTap;

  /// Spacing between user items
  final double? spacing;

  /// Margin around the entire list
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 8.h),
      child: Column(
        children: List.generate(users.length, (index) {
          final user = users[index];
          return Container(
            margin: EdgeInsets.only(
                bottom: index < users.length - 1 ? (spacing ?? 20.h) : 0),
            child: _buildUserCard(context, user),
          );
        }),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, CustomUserItem user) {
    return InkWell(
      onTap: () => onUserTap?.call(user),
      borderRadius: BorderRadius.circular(8.h),
      child: Padding(
        padding: EdgeInsets.all(4.h),
        child: Row(
          children: [
            _buildProfileImage(user),
            SizedBox(width: 12.h),
            _buildUserInfo(user),
            SizedBox(width: 12.h),
            _buildActionWidget(user),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(CustomUserItem user) {
    return CustomImageView(
      imagePath: user.profileImagePath,
      height: 52.h,
      width: 52.h,
      radius: BorderRadius.circular(26.h),
      fit: BoxFit.cover,
    );
  }

  Widget _buildUserInfo(CustomUserItem user) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.name,
            style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          SizedBox(height: 4.h),
          Text(
            user.followersText,
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
        ],
      ),
    );
  }

  Widget _buildActionWidget(CustomUserItem user) {
    final actionTypeToUse = actionType ?? user.actionType;

    switch (actionTypeToUse) {
      case CustomUserActionType.button:
        return CustomButton(
          text: user.actionText ?? 'block',
          onPressed: () => onActionTap?.call(user),
          buttonStyle: CustomButtonStyle
              .fillDark, // Modified: Replaced unavailable style with existing one
          buttonTextStyle: CustomButtonTextStyle
              .bodyMedium, // Modified: Replaced unavailable style with existing one
          padding: EdgeInsets.symmetric(
            horizontal: 16.h,
            vertical: 12.h,
          ),
        );

      case CustomUserActionType.icon:
        return InkWell(
          onTap: () => onActionTap?.call(user),
          borderRadius: BorderRadius.circular(4.h),
          child: Padding(
            padding: EdgeInsets.all(4.h),
            child: CustomImageView(
              imagePath:
                  user.actionIconPath ?? ImageConstant.imgIconBlueGray300,
              height: 34.h,
              width: 34.h,
              fit: BoxFit.contain,
            ),
          ),
        );

      default:
        return SizedBox.shrink();
    }
  }
}

/// Data model for user list items
class CustomUserItem {
  const CustomUserItem({
    required this.name,
    required this.followersText,
    required this.profileImagePath,
    this.actionType = CustomUserActionType.button,
    this.actionText,
    this.actionIconPath,
    this.id,
    this.navigationRoute,
  });

  /// User's display name
  final String name;

  /// Followers count text (e.g., "25 followers")
  final String followersText;

  /// Path to user's profile image
  final String profileImagePath;

  /// Type of action to display
  final CustomUserActionType actionType;

  /// Text for button action
  final String? actionText;

  /// Path to action icon
  final String? actionIconPath;

  /// Unique identifier for the user
  final String? id;

  /// Navigation route for user profile
  final String? navigationRoute;
}

/// Enum defining action types for user list items
enum CustomUserActionType {
  button,
  icon,
}
