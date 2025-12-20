
import '../core/app_export.dart';
import './custom_icon_button.dart';
import './custom_image_view.dart';

/** 
 * CustomEventCard - A reusable event card component that displays event information
 * including title, date, privacy status, and participant avatars with navigation controls.
 * 
 * Features:
 * - Event title and date display
 * - Privacy status indicator (Private/Public)
 * - Participant avatar stack with overlapping layout
 * - Interactive back navigation and icon button
 * - Responsive design with consistent styling
 * - Flexible content configuration
 */
class CustomEventCard extends StatelessWidget {
  const CustomEventCard({
    Key? key,
    this.eventTitle,
    this.eventDate,
    this.isPrivate,
    this.iconButtonImagePath,
    this.participantImages,
    this.onBackTap,
    this.onIconButtonTap,
    this.onCardTap,
    this.onAvatarTap,
  }) : super(key: key);

  /// The main title text for the event
  final String? eventTitle;

  /// The date text for the event
  final String? eventDate;

  /// Whether the event is private or public
  final bool? isPrivate;

  /// Image path for the variable icon button
  final String? iconButtonImagePath;

  /// List of participant avatar image paths (up to 3)
  final List<String>? participantImages;

  /// Callback for back arrow tap
  final VoidCallback? onBackTap;

  /// Callback for icon button tap
  final VoidCallback? onIconButtonTap;

  /// Callback for card tap
  final VoidCallback? onCardTap;

  /// Callback for avatar cluster tap
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          border: Border(
            bottom: BorderSide(
              color: appTheme.blue_gray_900,
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(12.h, 12.h, 12.h, 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackButton(),
            SizedBox(width: 16.h),
            _buildIconButton(),
            SizedBox(width: 16.h),
            _buildEventDetails(context),
            SizedBox(width: 16.h),
            _buildAvatarStack(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: GestureDetector(
        onTap: onBackTap,
        child: CustomImageView(
          imagePath: ImageConstant.imgArrowLeft,
          width: 24.h,
          height: 24.h,
        ),
      ),
    );
  }

  Widget _buildIconButton() {
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: CustomIconButton(
        iconPath: iconButtonImagePath ?? ImageConstant.imgFrame13,
        height: 36.h,
        width: 36.h,
        backgroundColor: appTheme.color41C124,
        borderRadius: 18.h,
        padding: EdgeInsets.all(6.h),
        onTap: onIconButtonTap,
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(top: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventTitle ?? 'Event Title',
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50, height: 1.22),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  eventDate ?? 'Event Date',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(height: 1.33),
                ),
                SizedBox(width: 6.h),
                _buildPrivacyButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyButton() {
    final bool isEventPrivate = isPrivate ?? true;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.h,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: appTheme.gray_900_03,
        borderRadius: BorderRadius.circular(6.h),
      ),
      child: Row(
        spacing: 4.h,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImageView(
            imagePath: isEventPrivate
                ? ImageConstant.imgIconDeepPurpleA10014x14
                : ImageConstant.imgIcon14x14,
            height: 14.h,
            width: 14.h,
          ),
          Text(
            isEventPrivate ? 'PRIVATE' : 'PUBLIC',
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                .copyWith(color: appTheme.deep_purple_A100),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    final List<String> avatars = participantImages ??
        [
          ImageConstant.imgFrame2,
          ImageConstant.imgFrame1,
          ImageConstant.imgEllipse81,
        ];

    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: GestureDetector(
        onTap: onAvatarTap,
        child: SizedBox(
          width: 84.h,
          height: 36.h,
          child: Stack(
            children: [
              if (avatars.isNotEmpty)
                Positioned(
                  left: 0,
                  child: CustomImageView(
                    imagePath: avatars[0],
                    width: 36.h,
                    height: 36.h,
                    radius: BorderRadius.circular(18.h),
                  ),
                ),
              if (avatars.length > 1)
                Positioned(
                  left: 24.h,
                  child: CustomImageView(
                    imagePath: avatars[1],
                    width: 36.h,
                    height: 36.h,
                    radius: BorderRadius.circular(18.h),
                  ),
                ),
              if (avatars.length > 2)
                Positioned(
                  left: 48.h,
                  child: CustomImageView(
                    imagePath: avatars[2],
                    width: 36.h,
                    height: 36.h,
                    radius: BorderRadius.circular(18.h),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
