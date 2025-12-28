import '../core/app_export.dart';
import './custom_image_view.dart';

/**
 * CustomUserProfileItem - A reusable user profile list item component with avatar and name display.
 * 
 * This component provides a consistent interface for displaying user profiles in lists with:
 * - Profile avatar image display
 * - User name text with consistent styling
 * - Dark theme background with rounded corners
 * - Tap interaction support for navigation/selection
 * - Responsive design using SizeUtils extensions
 * - Optional selection state visualization
 * 
 * @param profileImagePath - Path to the user's profile image (required)
 * @param userName - Display name of the user (required)  
 * @param onTap - Callback function when item is tapped
 * @param isSelected - Whether this item is currently selected
 * @param margin - External margin around the component
 */
class CustomUserProfileItem extends StatelessWidget {
  const CustomUserProfileItem({
    Key? key,
    required this.profileImagePath,
    required this.userName,
    this.onTap,
    this.isSelected,
    this.margin,
  }) : super(key: key);

  /// Path to the user's profile image
  final String profileImagePath;

  /// Display name of the user
  final String userName;

  /// Callback function when item is tapped
  final VoidCallback? onTap;

  /// Whether this item is currently selected
  final bool? isSelected;

  /// External margin around the component
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final bool itemSelected = isSelected ?? false;

    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: Material(
        color: appTheme.transparentCustom,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6.h),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 6.h,
              horizontal: 8.h,
            ),
            decoration: BoxDecoration(
              color: itemSelected ? Color(0xFF221730) : appTheme.gray_900_01,
              borderRadius: BorderRadius.circular(6.h),
              border: itemSelected
                  ? Border.all(
                      color: appTheme.colorFF52D1,
                      width: 1.h,
                    )
                  : null,
            ),
            child: Row(
              children: [
                _buildProfileImage(),
                SizedBox(width: 8.h),
                _buildUserName(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the profile image widget
  Widget _buildProfileImage() {
    return CustomImageView(
      imagePath: profileImagePath,
      height: 36.h,
      width: 36.h,
      fit: BoxFit.cover,
    );
  }

  /// Builds the user name text widget
  Widget _buildUserName(BuildContext context) {
    return Expanded(
      child: Text(
        userName,
        style: TextStyleHelper.instance.body14BoldPlusJakartaSans
            .copyWith(color: appTheme.gray_50, height: 1.29),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
