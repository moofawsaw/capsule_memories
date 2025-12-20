import '../core/app_export.dart';
import 'custom_image_view.dart';

/** CustomGroupCard - A reusable group card component that displays group information with member avatars and action buttons. Supports flexible member avatar stacking and customizable styling for group management interfaces. */
class CustomGroupCard extends StatelessWidget {
  CustomGroupCard({
    Key? key,
    required this.groupData,
    this.onActionTap,
    this.onDeleteTap,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  /// Group data containing title, member count, and profile images
  final CustomGroupData groupData;

  /// Callback for the primary action button
  final VoidCallback? onActionTap;

  /// Callback for the delete/remove action button
  final VoidCallback? onDeleteTap;

  /// Background color of the card
  final Color? backgroundColor;

  /// Border radius of the card
  final double? borderRadius;

  /// Internal padding of the card
  final EdgeInsetsGeometry? padding;

  /// External margin of the card
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF151319),
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
        Text(
          groupData.title ?? '',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(
            height: groupData.memberImages?.isNotEmpty == true ? 6.h : 4.h),
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
    final images = groupData.memberImages ?? [];
    if (images.isEmpty) return SizedBox.shrink();

    if (images.length == 1) {
      return CustomImageView(
        imagePath: images[0],
        height: 32.h,
        width: 32.h,
        fit: BoxFit.cover,
      );
    }

    // Calculate stack width based on number of images
    final stackWidth = (32 + (images.length - 1) * 23).h;

    return SizedBox(
      width: stackWidth,
      height: 32.h,
      child: Stack(
        children: images.asMap().entries.map((entry) {
          final index = entry.key;
          final imagePath = entry.value;
          final leftPosition = (index * 23).h;

          return Positioned(
            left: leftPosition,
            child: CustomImageView(
              imagePath: imagePath,
              height: 32.h,
              width: 32.h,
              fit: BoxFit.cover,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onActionTap,
          child: CustomImageView(
            imagePath: ImageConstant.imgButtons,
            height: 26.h,
            width: 26.h,
          ),
        ),
        SizedBox(width: 19.h),
        GestureDetector(
          onTap: onDeleteTap,
          child: CustomImageView(
            imagePath: ImageConstant.imgIconRed50026x26,
            height: 26.h,
            width: 26.h,
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
  });

  /// The group title/name
  final String? title;

  /// Text describing member count (e.g., "2 members", "1 member")
  final String? memberCountText;

  /// List of profile image paths for group members
  final List<String>? memberImages;
}
