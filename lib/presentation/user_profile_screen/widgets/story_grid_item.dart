import '../../../core/app_export.dart';
import '../../../core/utils/memory_categories.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/story_item_model.dart';

class StoryGridItem extends StatelessWidget {
  final StoryItemModel? model;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  StoryGridItem({
    Key? key,
    this.model,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get category emoji from MemoryCategories
    String categoryEmoji = '';
    if (model?.categoryText != null) {
      final category = MemoryCategories.getByName(model!.categoryText!);
      categoryEmoji = category.emoji;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? 116.h,
        height: height ?? 250.h,
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          borderRadius: BorderRadius.circular(1.h),
          border: Border.all(color: appTheme.gray_900_02, width: 1.h),
        ),
        child: Stack(
          children: [
            CustomImageView(
              imagePath: model?.backgroundImage ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    margin: EdgeInsets.only(left: 4.h),
                    child: Container(
                      width: 32.h,
                      height: 32.h,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: appTheme.deep_purple_A100, width: 2.h),
                        borderRadius: BorderRadius.circular(16.h),
                      ),
                      child: Center(
                        child: CustomImageView(
                          imagePath: model?.userAvatar ?? '',
                          width: 26.h,
                          height: 26.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    model?.userName ?? '',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.white_A700),
                  ),
                  SizedBox(height: 18.h),
                  if (model?.categoryText != null && categoryEmoji.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6.h, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: appTheme.gray_900_02,
                        borderRadius: BorderRadius.circular(12.h),
                      ),
                      child: Row(
                        spacing: 6.h,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            categoryEmoji,
                            style: TextStyle(fontSize: 18.h),
                          ),
                          Text(
                            model?.categoryText ?? '',
                            style: TextStyleHelper
                                .instance.body12BoldPlusJakartaSans
                                .copyWith(color: appTheme.gray_50),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 4.h),
                  Text(
                    model?.timestamp ?? '',
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(color: appTheme.white_A700),
                  ),
                  SizedBox(height: 27.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
