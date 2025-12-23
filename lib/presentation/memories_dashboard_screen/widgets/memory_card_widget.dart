import '../../../core/app_export.dart';
import '../../../widgets/custom_confirmation_dialog.dart';
import '../../../widgets/custom_icon_button.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/memory_item_model.dart';

class MemoryCardWidget extends StatelessWidget {
  final MemoryItemModel memoryItem;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  MemoryCardWidget({
    Key? key,
    required this.memoryItem,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300.h,
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: Column(
          children: [
            _buildEventHeader(),
            _buildMemoryTimeline(),
            _buildEventInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: EdgeInsets.all(18.h),
      decoration: BoxDecoration(
        color: appTheme.color3BD81E,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      child: Row(
        children: [
          // Use actual category icon if available, otherwise use fallback
          CustomIconButton(
            iconPath: memoryItem.categoryIconUrl != null &&
                    memoryItem.categoryIconUrl!.isNotEmpty
                ? memoryItem.categoryIconUrl!
                : ImageConstant.imgFrame13Red600,
            backgroundColor: appTheme.color41C124,
            borderRadius: 18.h,
            height: 36.h,
            width: 36.h,
            padding: EdgeInsets.all(6.h),
            iconSize: 24.h,
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memoryItem.title ?? 'Nixon Wedding 2025',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 4.h),
                Text(
                  memoryItem.date ?? 'Dec 4, 2025',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.h),
          // Participant avatars section - using exact feed pattern
          _buildParticipantAvatarsStack(),
          if (onDelete != null) ...[
            SizedBox(width: 8.h),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () => _handleDeleteTap(context),
                child: Container(
                  padding: EdgeInsets.all(8.h),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20.h,
                    color: appTheme.gray_50,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build participant avatars using exact same pattern as feed
  Widget _buildParticipantAvatarsStack() {
    // Use actual participant avatars from cache service (already filtered)
    final avatars = memoryItem.participantAvatars ?? [];

    // Return empty container if no avatars to display
    if (avatars.isEmpty) {
      return SizedBox(width: 84.h, height: 36.h);
    }

    // Take up to 3 avatars for display
    final displayAvatars = avatars.take(3).toList();

    return Container(
      width: 84.h,
      height: 36.h,
      child: Stack(
        children: [
          // First avatar
          if (displayAvatars.isNotEmpty)
            Positioned(
              left: 0,
              child: CustomImageView(
                imagePath: displayAvatars[0],
                height: 36.h,
                width: 36.h,
                radius: BorderRadius.circular(18.h),
              ),
            ),
          // Second avatar
          if (displayAvatars.length > 1)
            Positioned(
              left: 24.h,
              child: CustomImageView(
                imagePath: displayAvatars[1],
                height: 36.h,
                width: 36.h,
                radius: BorderRadius.circular(18.h),
              ),
            ),
          // Third avatar
          if (displayAvatars.length > 2)
            Positioned(
              right: 0,
              child: CustomImageView(
                imagePath: displayAvatars[2],
                height: 36.h,
                width: 36.h,
                radius: BorderRadius.circular(18.h),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteTap(BuildContext context) async {
    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Delete Memory?',
      message:
          'Are you sure you want to delete "${memoryItem.title ?? 'this memory'}"? All stories and content will be permanently removed.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
    );

    if (confirmed == true && onDelete != null) {
      onDelete!();
    }
  }

  Widget _buildMemoryTimeline() {
    // Use actual thumbnails from database like feed does
    final thumbnails = memoryItem.memoryThumbnails ?? [];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.h),
      child: Stack(
        children: [
          Container(
            height: 112.h,
            child: Column(
              children: [
                // Show actual story thumbnails from database
                if (thumbnails.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (thumbnails.length > 1)
                        _buildMemoryThumbnail(thumbnails[1]),
                      if (thumbnails.length > 1) SizedBox(width: 8.h),
                      _buildMemoryThumbnail(thumbnails[0]),
                    ],
                  )
                else
                  // Fallback placeholder if no thumbnails
                  SizedBox(height: 56.h),
                SizedBox(height: 16.h),
                Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: appTheme.deep_purple_A100,
                    borderRadius: BorderRadius.circular(2.h),
                  ),
                ),
                SizedBox(height: 16.h),
                _buildTimelineAvatars(),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              'now',
              style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                  .copyWith(color: appTheme.transparentCustom),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryThumbnail(String imagePath) {
    // Accept any image URL from database - no hardcoded paths
    return Container(
      width: 40.h,
      height: 56.h,
      decoration: BoxDecoration(
        border: Border.all(color: appTheme.deep_purple_A200, width: 1.h),
        borderRadius: BorderRadius.circular(6.h),
        color: appTheme.gray_900_01,
      ),
      child: Stack(
        children: [
          CustomImageView(
            imagePath: imagePath, // Use actual database URL
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            radius: BorderRadius.circular(6.h),
          ),
          Positioned(
            top: 4.h,
            left: 4.h,
            child: Container(
              padding: EdgeInsets.all(4.h),
              decoration: BoxDecoration(
                color: appTheme.color3BD81E,
                borderRadius: BorderRadius.circular(6.h),
              ),
              child: Container(
                width: 16.h,
                height: 16.h,
                decoration: BoxDecoration(
                  color: appTheme.color3BD81E,
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: CustomImageView(
                  imagePath: ImageConstant.imgPlayCircle,
                  height: 12.h,
                  width: 12.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineAvatars() {
    // Use actual contributor avatars (excluding current user, already filtered in notifier)
    final avatars = memoryItem.participantAvatars ?? [];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 50.h),
        // Show actual contributor avatars on timeline
        if (avatars.isNotEmpty)
          Column(
            children: [
              Container(
                width: 2.h,
                height: 16.h,
                color: appTheme.deep_purple_A100,
              ),
              SizedBox(height: 4.h),
              CustomImageView(
                imagePath: avatars[0], // Use actual database avatar URL
                height: 28.h,
                width: 28.h,
                radius: BorderRadius.circular(14.h),
              ),
            ],
          ),
        if (avatars.length > 1)
          Column(
            children: [
              Container(
                width: 2.h,
                height: 16.h,
                color: appTheme.deep_purple_A100,
              ),
              SizedBox(height: 4.h),
              CustomImageView(
                imagePath: avatars[1], // Use actual database avatar URL
                height: 28.h,
                width: 28.h,
                radius: BorderRadius.circular(14.h),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Container(
      padding: EdgeInsets.all(12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memoryItem.eventDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
              SizedBox(height: 6.h),
              Text(
                memoryItem.eventTime ?? '3:18pm',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                memoryItem.location ?? 'Tillsonburg, ON',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 4.h),
              Text(
                memoryItem.distance ?? '21km',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memoryItem.endDate ?? 'Dec 4',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
              SizedBox(height: 6.h),
              Text(
                memoryItem.endTime ?? '3:18am',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
