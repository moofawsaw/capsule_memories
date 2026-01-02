import '../core/app_export.dart';
import './custom_image_view.dart';

/** CustomEventCard - A reusable component for displaying event information with a profile image, story count, participant list, and configurable action buttons. Supports flexible styling and interactive elements for event management interfaces. */
class CustomEventCard extends StatelessWidget {
  const CustomEventCard({
    Key? key,
    required this.eventData,
    this.onActionTap,
    this.onMemoryTap,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
  }) : super(key: key);

  /// Event data containing title, story count, and profile images
  final CustomEventData eventData;

  /// Callback for the action button
  final VoidCallback? onActionTap;

  /// Callback when tapping on the memory/event itself
  final VoidCallback? onMemoryTap;

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
              imagePath: eventData.profileImage ?? '',
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
          eventData.title ?? '',
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
        if (eventData.participantImages?.isNotEmpty == true) ...[
          _buildParticipantImages(context),
          SizedBox(width: 6.h),
        ],
        Text(
          eventData.storyCountText ?? '',
          style: TextStyleHelper.instance.bodyTextRegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }

  Widget _buildParticipantImages(BuildContext context) {
    final images = eventData.participantImages ?? [];
    final participantIds = eventData.participantIds ?? [];

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
