import '../core/app_export.dart';
import './custom_icon_button.dart';
import './custom_image_view.dart';

/** CustomEventCard - A reusable component for displaying event information with a profile image, story count, participant list, and configurable action buttons. Supports flexible styling and interactive elements for event management interfaces. */
class CustomEventCard extends StatelessWidget {
  const CustomEventCard({
    Key? key,
    this.eventData,
    this.eventTitle,
    this.eventDate,
    this.isPrivate,
    this.iconButtonImagePath,
    this.participantImages,
    this.onBackTap,
    this.onIconButtonTap,
    this.onAvatarTap,
    this.onActionTap,
    this.onMemoryTap,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  // Legacy API parameters
  final String? eventTitle;
  final String? eventDate;
  final bool? isPrivate;
  final String? iconButtonImagePath;
  final List<String>? participantImages;
  final VoidCallback? onBackTap;
  final VoidCallback? onIconButtonTap;
  final VoidCallback? onAvatarTap;

  // New API parameters
  final CustomEventData? eventData;
  final VoidCallback? onActionTap;
  final VoidCallback? onMemoryTap;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  bool get _isLegacyMode => eventTitle != null || eventDate != null;

  @override
  Widget build(BuildContext context) {
    if (_isLegacyMode) {
      return _buildLegacyLayout(context);
    }
    return _buildNewLayout(context);
  }

  Widget _buildLegacyLayout(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.fromLTRB(12.h, 14.h, 16.h, 14.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? appTheme.gray_900_02,
        border: Border(
          bottom: BorderSide(
            color: appTheme.blue_gray_900,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button on the left
          CustomIconButton(
            iconPath: ImageConstant.imgArrowLeft,
            height: 48.h,
            width: 48.h,
            padding: EdgeInsets.all(12.h),
            backgroundColor: appTheme.gray_900_03,
            borderRadius: 24.h,
            onTap: onBackTap,
          ),
          SizedBox(width: 12.h),
          // Memory title and date in center
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eventTitle ?? '',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      eventDate ?? '',
                      style: TextStyleHelper
                          .instance.bodyTextRegularPlusJakartaSans
                          .copyWith(color: appTheme.blue_gray_300),
                    ),
                    SizedBox(width: 8.h),
                    // Private/Public button
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.h,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isPrivate == true
                            ? appTheme.red_500.withAlpha(51)
                            : appTheme.green_500.withAlpha(51),
                        borderRadius: BorderRadius.circular(4.h),
                      ),
                      child: Text(
                        isPrivate == true ? 'Private' : 'Public',
                        style: TextStyleHelper
                            .instance.bodyTextRegularPlusJakartaSans
                            .copyWith(
                          color: isPrivate == true
                              ? appTheme.red_500
                              : appTheme.green_500,
                          fontSize: 12.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.h),
          // Members on the right
          GestureDetector(
            onTap: onAvatarTap,
            child: _buildLegacyMemberAvatars(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyMemberAvatars(BuildContext context) {
    final images = participantImages ?? [];

    if (images.isEmpty) {
      return CustomImageView(
        imagePath: iconButtonImagePath ?? ImageConstant.imgFrame13,
        height: 48.h,
        width: 48.h,
        fit: BoxFit.cover,
      );
    }

    if (images.length == 1) {
      return CustomImageView(
        imagePath: images[0],
        height: 48.h,
        width: 48.h,
        fit: BoxFit.cover,
      );
    }

    // Calculate stack width for multiple avatars
    final stackWidth = (48 + (images.length - 1) * 32).h;

    return SizedBox(
      width: stackWidth,
      height: 48.h,
      child: Stack(
        children: images.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final imagePath = entry.value;
          final leftPosition = (index * 32).h;

          return Positioned(
            left: leftPosition,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: appTheme.gray_900_02,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(24.h),
              ),
              child: CustomImageView(
                imagePath: imagePath,
                height: 48.h,
                width: 48.h,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewLayout(BuildContext context) {
    return GestureDetector(
      onTap: onMemoryTap,
      child: Container(
        margin: margin,
        padding: padding ?? EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF151319),
          borderRadius: BorderRadius.circular(borderRadius ?? 12.h),
        ),
        child: Row(
          children: [
            CustomImageView(
              imagePath: eventData?.profileImage ?? '',
              height: 48.h,
              width: 48.h,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: _buildEventInfo(context),
            ),
            SizedBox(width: 18.h),
            if (onActionTap != null)
              GestureDetector(
                onTap: onActionTap,
                child: CustomImageView(
                  imagePath: ImageConstant.imgButtons,
                  height: 26.h,
                  width: 26.h,
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eventData?.title ?? '',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        _buildParticipantsInfo(context),
      ],
    );
  }

  Widget _buildParticipantsInfo(BuildContext context) {
    return Row(
      children: [
        if (eventData?.participantImages?.isNotEmpty == true) ...[
          _buildParticipantImages(context),
          SizedBox(width: 6.h),
        ],
        Text(
          eventData?.storyCountText ?? '',
          style: TextStyleHelper.instance.bodyTextRegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }

  Widget _buildParticipantImages(BuildContext context) {
    final images = eventData?.participantImages ?? [];
    final participantIds = eventData?.participantIds ?? [];

    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return GestureDetector(
        onTap: participantIds.isNotEmpty && participantIds[0] != null
            ? () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.appProfileUser,
                  arguments: participantIds[0],
                );
              }
            : null,
        child: CustomImageView(
          imagePath: images[0],
          height: 32.h,
          width: 32.h,
          fit: BoxFit.cover,
        ),
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
          final participantId =
              index < participantIds.length ? participantIds[index] : null;

          return Positioned(
            left: leftPosition,
            child: GestureDetector(
              onTap: participantId != null
                  ? () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.appProfileUser,
                        arguments: participantId,
                      );
                    }
                  : null,
              child: CustomImageView(
                imagePath: imagePath,
                height: 32.h,
                width: 32.h,
                fit: BoxFit.cover,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Data model for event card information
class CustomEventData {
  CustomEventData({
    this.title,
    this.storyCountText,
    this.profileImage,
    this.participantImages,
    this.participantIds,
  });

  /// The event title/name
  final String? title;

  /// Text describing story count (e.g., "2 stories", "1 story")
  final String? storyCountText;

  /// Primary profile image for the event
  final String? profileImage;

  /// List of profile images for event participants
  final List<String>? participantImages;

  /// List of user IDs corresponding to participant images for navigation
  final List<String?>? participantIds;
}
