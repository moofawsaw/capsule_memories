import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../../../widgets/custom_story_list.dart'
    as story_list; // Modified: Added alias to resolve ambiguous import

class StoryItemWidget extends StatelessWidget {
  final story_list.CustomStoryItem
      model; // Modified: Used alias to resolve ambiguous import
  final VoidCallback? onTap;

  StoryItemWidget({
    Key? key,
    required this.model,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90.h,
        height: 120.h,
        child: Stack(
          children: [
            CustomImageView(
              imagePath: model.backgroundImage ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              padding: EdgeInsets.all(12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32.h,
                    height: 32.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: appTheme.deep_purple_A100,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16.h),
                    ),
                    child: Center(
                      child: CustomImageView(
                        imagePath: model.profileImage ?? '',
                        width: 26.h,
                        height: 26.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    model.timestamp ?? '2 mins ago',
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(color: appTheme.whiteCustom),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
