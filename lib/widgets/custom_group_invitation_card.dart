import '../core/app_export.dart';
import './custom_button.dart';
import './custom_image_view.dart';

/**
 * CustomGroupInvitationCard - A reusable invitation card component for group invitations
 *
 * Fix:
 * - If a group has 0 members (creator-only group), show "1 member" and display the creator avatar.
 */
class CustomGroupInvitationCard extends StatelessWidget {
  const CustomGroupInvitationCard({
    Key? key,
    required this.groupName,
    required this.memberCount,
    this.memberAvatarImagePath,

    // ✅ NEW: Used when memberCount is 0 (creator-only group)
    this.creatorAvatarImagePath,
    this.showCreatorAvatarWhenEmpty = true,

    this.onAcceptTap,
    this.onActionTap,
    this.actionIconPath,
    this.isAcceptEnabled = true,
    this.margin,
    this.backgroundColor,
  }) : super(key: key);

  /// The name of the group being invited to
  final String groupName;

  /// Number of members in the group (may be 0 from backend)
  final int memberCount;

  /// Path to the member avatars image (stacked profile pictures)
  final String? memberAvatarImagePath;

  /// ✅ NEW: Creator avatar to show when the group has 0 members
  /// (Pass the current user's avatar path here from the caller.)
  final String? creatorAvatarImagePath;

  /// ✅ NEW: When true, a 0-member group displays creator avatar + "1 member"
  final bool showCreatorAvatarWhenEmpty;

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

  int get _effectiveMemberCount {
    // If backend returns 0, treat it as creator-only group => 1 member
    if (memberCount <= 0) return 1;
    return memberCount;
  }

  bool get _shouldShowCreatorFallbackAvatar {
    return showCreatorAvatarWhenEmpty &&
        memberCount <= 0 &&
        creatorAvatarImagePath != null &&
        (memberAvatarImagePath == null);
  }

  String get _memberCountLabel {
    final count = _effectiveMemberCount;
    return count == 1 ? '1 member' : '$count members';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 12.h, vertical: 5.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF151319),
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
        // ✅ Normal case: show stacked avatar image if provided
        if (memberAvatarImagePath != null) ...[
          CustomImageView(
            imagePath: memberAvatarImagePath!,
            width: 78.h,
            height: 32.h,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 6.h),
        ]

        // ✅ Fallback case: backend says 0 members => show creator avatar (single)
        else if (_shouldShowCreatorFallbackAvatar) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16.h),
            child: CustomImageView(
              imagePath: creatorAvatarImagePath!,
              width: 32.h,
              height: 32.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 6.h),
        ],

        Text(
          _memberCountLabel,
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
          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
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