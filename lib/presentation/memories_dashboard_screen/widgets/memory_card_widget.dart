import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../../../widgets/custom_icon_button.dart';
import '../models/memory_item_model.dart';

class MemoryCardWidget extends StatelessWidget {
  final MemoryItemModel memoryItem;
  final VoidCallback? onTap;

  MemoryCardWidget({
    Key? key,
    required this.memoryItem,
    this.onTap,
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
          CustomIconButton(
            iconPath: ImageConstant.imgFrame13Red600,
            backgroundColor: appTheme.color41C124,
            borderRadius: 18.h,
            height: 36.h,
            width: 36.h,
            padding: EdgeInsets.all(6.h),
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
          _buildParticipantAvatars(),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatars() {
    return Container(
      width: 84.h,
      height: 36.h,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: CustomImageView(
              imagePath: (memoryItem.participantAvatars?.isNotEmpty ??
                      false) // Modified: Added null safety check
                  ? memoryItem.participantAvatars![0]
                  : ImageConstant.imgFrame2,
              height: 36.h,
              width: 36.h,
              radius: BorderRadius.circular(18.h),
            ),
          ),
          Positioned(
            left: 24.h,
            child: CustomImageView(
              imagePath: ((memoryItem.participantAvatars?.length ?? 0) >
                      1) // Modified: Added null safety check
                  ? memoryItem.participantAvatars![1]
                  : ImageConstant.imgFrame1,
              height: 36.h,
              width: 36.h,
              radius: BorderRadius.circular(18.h),
            ),
          ),
          Positioned(
            right: 0,
            child: CustomImageView(
              imagePath: ((memoryItem.participantAvatars?.length ?? 0) >
                      2) // Modified: Added null safety check
                  ? memoryItem.participantAvatars![2]
                  : ImageConstant.imgEllipse81,
              height: 36.h,
              width: 36.h,
              radius: BorderRadius.circular(18.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryTimeline() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.h),
      child: Stack(
        children: [
          Container(
            height: 112.h,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMemoryThumbnail(ImageConstant.imgImage9),
                    SizedBox(width: 8.h),
                    _buildMemoryThumbnail(ImageConstant.imgImage8),
                  ],
                ),
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
            imagePath: imagePath,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 50.h),
        Column(
          children: [
            Container(
              width: 2.h,
              height: 16.h,
              color: appTheme.deep_purple_A100,
            ),
            SizedBox(height: 4.h),
            CustomImageView(
              imagePath: ImageConstant.imgEllipse826x26,
              height: 28.h,
              width: 28.h,
              radius: BorderRadius.circular(14.h),
            ),
          ],
        ),
        Column(
          children: [
            Container(
              width: 2.h,
              height: 16.h,
              color: appTheme.deep_purple_A100,
            ),
            SizedBox(height: 4.h),
            CustomImageView(
              imagePath: ImageConstant.imgFrame2,
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
