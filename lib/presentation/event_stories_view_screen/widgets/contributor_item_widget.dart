import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/contributor_item_model.dart';

class ContributorItemWidget extends StatelessWidget {
  final ContributorItemModel contributorItemModel;
  final VoidCallback? onTapContributor;

  ContributorItemWidget({
    Key? key,
    required this.contributorItemModel,
    this.onTapContributor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapContributor,
      child: Container(
        padding: EdgeInsets.all(8.h),
        decoration: BoxDecoration(
          color: appTheme.colorFF2A2A,
          borderRadius: BorderRadius.circular(24.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImageView(
              imagePath: contributorItemModel.contributorImage ?? '',
              height: 32.h,
              width: 32.h,
              radius: BorderRadius.circular(16.h),
            ),
            SizedBox(width: 8.h),
            Text(
              contributorItemModel.contributorName ?? '',
              style: TextStyleHelper.instance.body14MediumPlusJakartaSans,
            ),
          ],
        ),
      ),
    );
  }
}
