import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'custom_image_view.dart';
import 'custom_button.dart';

/** 
 * CustomGroupInvitationCard - A reusable invitation card component for group invitations
 * 
 * This component displays group information including name, member avatars, member count,
 * and provides action buttons for accepting invitations and additional options.
 * Features responsive design, customizable callbacks, and consistent dark theme styling.
 */
class CustomGroupInvitationCard extends StatelessWidget {
  const CustomGroupInvitationCard({
    Key? key,
    required this.groupName,
    required this.memberCount,
    this.memberAvatarImagePath,
    this.onAcceptTap,
    this.onActionTap,
    this.actionIconPath,
    this.isAcceptEnabled = true,
    this.margin,
    this.backgroundColor,
  }) : super(key: key);

  /// The name of the group being invited to
  final String groupName;

  /// Number of members in the group
  final int memberCount;

  /// Path to the member avatars image (stacked profile pictures)
  final String? memberAvatarImagePath;

  /// Callback when accept button is tapped
  final VoidCallback? onAcceptTap;

  /// Callback when action icon is tapped
  final VoidCallback? onActionTap;

  /// Path to the action icon (default is decline/remove icon)
  final String? actionIconPath;

  /// Whether the accept button is enabled
  final bool isAcceptEnabled;

  /// Margin around the entire card
  final EdgeInsetsGeometry? margin;

  /// Background color of the card
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 12.h, vertical: 5.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF151319),
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildGroupInfoSection(context),
          ),
          SizedBox(width: 18.h),
          _buildActionSection(context),
        ],
      ),
    );
  }

  /// Builds the group information section with name and member details
  Widget _buildGroupInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupName,
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 4.h),
        _buildMemberInfoRow(context),
      ],
    );
  }

  /// Builds the member information row with avatars and count
  Widget _buildMemberInfoRow(BuildContext context) {
    return Row(
      children: [
        if (memberAvatarImagePath != null) ...[
          CustomImageView(
            imagePath: memberAvatarImagePath!,
            width: 78.h,
            height: 32.h,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 6.h),
        ],
        Text(
          '$memberCount members',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }

  /// Builds the action section with accept button and action icon
  Widget _buildActionSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomButton(
          text: 'Accept',
          onPressed: isAcceptEnabled ? onAcceptTap : null,
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle
              .bodyMedium, // Modified: Replaced unavailable bodySmallWhite with available style
          padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.h),
        ),
        SizedBox(width: 18.h),
        GestureDetector(
          onTap: onActionTap,
          child: CustomImageView(
            imagePath: actionIconPath ?? ImageConstant.imgIconRed50026x26,
            width: 26.h,
            height: 26.h,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
