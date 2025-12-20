import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/story_item_model.dart';

class StoryItemWidget extends StatelessWidget {
  final StoryItemModel storyItemModel;
  final VoidCallback? onTapStory;

  StoryItemWidget({
    Key? key,
    required this.storyItemModel,
    this.onTapStory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapStory,
      child: Container(
        width: 80.h,
        height: 120.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
            color: appTheme.colorFF52D1,
            width: 2.h,
          ),
        ),
        child: Stack(
          children: [
            CustomImageView(
              imagePath: storyItemModel.storyImage ?? '',
              height: 120.h,
              width: 80.h,
              radius: BorderRadius.circular(10.h),
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 6.h,
              left: 6.h,
              right: 6.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.h, vertical: 2.h),
                decoration: BoxDecoration(
                  color: appTheme.color800000,
                  borderRadius: BorderRadius.circular(4.h),
                ),
                child: Text(
                  storyItemModel.timeAgo ?? '',
                  style: TextStyleHelper.instance.label10RegularPlusJakartaSans,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
