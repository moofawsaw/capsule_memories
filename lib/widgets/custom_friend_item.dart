import '../core/app_export.dart';
import './custom_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

import './custom_image_view.dart';

/** 
 * CustomFriendItem - A reusable component for displaying user/friend information in a list format.
 * 
 * Features a profile image, user name, status button, and action button in a horizontal layout.
 * Supports customizable status text, profile images, and action callbacks with consistent styling.
 */
class CustomFriendItem extends StatelessWidget {
  const CustomFriendItem({
    Key? key,
    required this.profileImagePath,
    required this.userName,
    this.statusText,
    this.onActionTap,
    this.onProfileTap,
    this.onTap,
    this.backgroundColor,
    this.margin,
  }) : super(key: key);

  /// Path to the user's profile image
  final String profileImagePath;

  /// Display name of the user
  final String userName;

  /// Status text to display (e.g., "Pending", "Friend", etc.)
  final String? statusText;

  /// Callback function when action icon is tapped
  final VoidCallback? onActionTap;

  /// Callback function when profile image is tapped
  final VoidCallback? onProfileTap;

  /// Callback function when the entire item is tapped
  final VoidCallback? onTap;

  /// Background color of the item container
  final Color? backgroundColor;

  /// External margin for the item
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: backgroundColor ?? appTheme.gray_900_01,
          borderRadius: BorderRadius.circular(12.h),
        ),
        child: Row(
          children: [
            // Profile Image with proper circular clipping
// Profile Image (Friends list) - single clip only (perfect circle)
            GestureDetector(
              onTap: onProfileTap ?? onTap,
              child: Container(
                margin: EdgeInsets.only(left: 16.h),
                child: SizedBox.square(
                  dimension: 48.h,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profileImagePath.isNotEmpty
                          ? profileImagePath
                          : '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: appTheme.gray_900_02,
                        child: Center(
                          child: SizedBox(
                            width: 18.h,
                            height: 18.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: appTheme.gray_50.withAlpha(140),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: appTheme.gray_900_03,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person_outline,
                          size: 20.h,
                          color: appTheme.blue_gray_300,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),



            // User Name
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 16.h),
                child: Text(
                  userName,
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),
            ),

            // Status Button (if status text is provided)
            if (statusText != null) ...[
              CustomButton(
                text: statusText!,
                buttonStyle: CustomButtonStyle.fillDark,
                buttonTextStyle: CustomButtonTextStyle.bodySmallPrimary,
                padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 2.h),
              ),
            ],

            // Action Icon Button
            Container(
              margin: EdgeInsets.only(left: 16.h, right: 14.h),
              child: CustomIconButton(
                icon: Icons.person_remove_outlined,
                iconColor: appTheme.blue_gray_300,
                height: 28.h,
                width: 28.h,
                padding: EdgeInsets.all(2.h),
                backgroundColor: appTheme.transparentCustom,
                onTap: onActionTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
