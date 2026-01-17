import '../core/app_export.dart';
import './custom_image_view.dart';

/** CustomGroupCard - A reusable group card component that displays group information with member avatars and action buttons. Supports flexible member avatar stacking and customizable styling for group management interfaces. */
class CustomGroupCard extends StatelessWidget {
  CustomGroupCard({
    Key? key,
    required this.groupData,
    this.onActionTap,
    this.onDeleteTap,
    this.onLeaveTap,
    this.onEditTap,
    this.onInfoTap,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  /// Group data containing title, member count, and profile images
  final CustomGroupData groupData;

  /// Callback for the primary action button
  final VoidCallback? onActionTap;

  /// Callback for the delete action button (creators only)
  final VoidCallback? onDeleteTap;

  /// Callback for the leave action button (non-creators only)
  final VoidCallback? onLeaveTap;

  /// Callback for the edit action button (for creators)
  final VoidCallback? onEditTap;

  /// Callback for the info action button (for non-creators)
  final VoidCallback? onInfoTap;

  /// Background color of the card
  final Color? backgroundColor;

  /// Border radius of the card
  final double? borderRadius;

  /// Internal padding of the card
  final EdgeInsetsGeometry? padding;

  /// External margin of the card
  final EdgeInsetsGeometry? margin;

  // ========= AVATAR LAYOUT CONSTANTS (RAW PX) =========
  static const double _avatarSizePx = 32.0;
  static const double _avatarOffsetPx = 23.0; // overlap spacing
  static const int _maxAvatars = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(borderRadius ?? 12.h),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildGroupInfo(context),
          ),
          SizedBox(width: 18.h),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildGroupInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                groupData.title ?? '',
                style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (groupData.isCreator == true) ...[
              SizedBox(width: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
                decoration: BoxDecoration(
                  color: appTheme.deep_purple_A100,
                  borderRadius: BorderRadius.circular(6.h),
                ),
                child: Text(
                  'Creator',
                  style: TextStyleHelper.instance.bodyTextRegularPlusJakartaSans.copyWith(
                    color: appTheme.gray_50,
                    fontSize: 10.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: groupData.memberImages?.isNotEmpty == true ? 6.h : 4.h),
        _buildMemberInfo(context),
      ],
    );
  }

  Widget _buildMemberInfo(BuildContext context) {
    return Row(
      children: [
        if (groupData.memberImages?.isNotEmpty == true) ...[
          _buildProfileImages(context),
          SizedBox(width: 6.h),
        ],
        Text(
          groupData.memberCountText ?? '',
          style: TextStyleHelper.instance.bodyTextRegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }

  Widget _buildProfileImages(BuildContext context) {
    final List<String> images = groupData.memberImages ?? <String>[];
    final List<String?> memberIds = groupData.memberIds ?? <String?>[];

    if (images.isEmpty) return const SizedBox.shrink();

    final int count = images.length > _maxAvatars ? _maxAvatars : images.length;

    final double size = _avatarSizePx.h;
    final double stackWidth = (_avatarSizePx + (count - 1) * _avatarOffsetPx).h;

    Widget buildAvatar(String imagePath, String? memberId) {
      return GestureDetector(
        onTap: memberId != null
            ? () {
          Navigator.pushNamed(
            context,
            AppRoutes.appProfileUser,
            arguments: memberId,
          );
        }
            : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF222D3E),
              border: Border.all(
                color: appTheme.gray_900_02,
                width: 1,
              ),
            ),
            child: ClipOval(
              child: _GroupAvatarImage(
                imagePath: imagePath,
                size: size,
              ),
            ),
          ),
        ),
      );
    }

    if (count == 1) {
      final String? memberId = memberIds.isNotEmpty ? memberIds[0] : null;
      return buildAvatar(images[0], memberId);
    }

    // ✅ Multiple (stack) — reverse paint order so you can see more than 1
    return SizedBox(
      width: stackWidth,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: List<Widget>.generate(count, (i) {
          final int index = (count - 1) - i; // reverse paint order

          final String imagePath = images[index];
          final String? memberId = index < memberIds.length ? memberIds[index] : null;

          return Positioned(
            left: (index * _avatarOffsetPx).h,
            child: buildAvatar(imagePath, memberId),
          );
        }),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✏️ Edit (creator only)
        if (groupData.isCreator == true && onEditTap != null) ...[
          GestureDetector(
            onTap: onEditTap,
            child: Icon(
              Icons.edit,
              size: 26.h,
              color: appTheme.gray_50,
            ),
          ),
          SizedBox(width: 12.h),
        ],

        // ℹ️ Info (non-creator only)
        if (groupData.isCreator != true && onInfoTap != null) ...[
          GestureDetector(
            onTap: onInfoTap,
            child: Icon(
              Icons.info_outline,
              size: 26.h,
              color: appTheme.gray_50,
            ),
          ),
          SizedBox(width: 12.h),
        ],

        // 🔗 QR / primary action (always)
        GestureDetector(
          onTap: onActionTap,
          child: Icon(
            Icons.qr_code_2,
            size: 26.h,
            color: appTheme.gray_50,
          ),
        ),

        SizedBox(width: 19.h),

        // 🗑 Delete (creator) OR 🚪 Leave (non-creator)
        if (groupData.isCreator == true)
          GestureDetector(
            onTap: onDeleteTap,
            child: Icon(
              Icons.delete_outline,
              size: 26.h,
              color: appTheme.red_500,
            ),
          )
        else
          GestureDetector(
            onTap: onLeaveTap,
            child: Icon(
              Icons.logout,
              size: 26.h,
              color: appTheme.gray_50,
            ),
          ),
      ],
    );
  }
}

/// Data model for group card information
class CustomGroupData {
  CustomGroupData({
    this.title,
    this.memberCountText,
    this.memberImages,
    this.memberIds,
    this.isCreator = false,
  });

  /// The group title/name
  final String? title;

  /// Text describing member count (e.g., "2 members", "1 member")
  final String? memberCountText;

  /// List of profile image paths for group members
  final List<String>? memberImages;

  /// List of user IDs corresponding to member images for navigation
  final List<String?>? memberIds;

  /// Whether the current user is the creator of this group
  final bool? isCreator;
}

/// Forces true cover behavior for group member avatars (prevents stretching + ensures circular crop).
class _GroupAvatarImage extends StatelessWidget {
  final String imagePath;
  final double size;

  const _GroupAvatarImage({
    Key? key,
    required this.imagePath,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isNetwork = imagePath.startsWith('http');

    if (isNetwork) {
      return Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: appTheme.gray_900_02,
          alignment: Alignment.center,
          child: Icon(
            Icons.person,
            size: (size * 0.55),
            color: appTheme.blue_gray_300,
          ),
        ),
      );
    }

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
  }
}
