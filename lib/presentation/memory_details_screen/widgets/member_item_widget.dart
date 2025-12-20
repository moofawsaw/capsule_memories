import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/memory_details_model.dart';

class MemberItemWidget extends StatelessWidget {
  final MemberModel member;
  final VoidCallback? onTap;

  MemberItemWidget({
    Key? key,
    required this.member,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.h,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(6.h),
      ),
      child: Row(
        children: [
          CustomImageView(
            imagePath:
                member.profileImagePath ?? ImageConstant.imgEllipse826x26,
            height: 36.h,
            width: 36.h,
            radius: BorderRadius.circular(18.h),
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: Text(
              member.name ?? '',
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50, height: 1.29),
            ),
          ),
          if (member.isCreator ?? false) ...[
            SizedBox(width: 8.h),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.h,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: appTheme.gray_900_03,
                borderRadius: BorderRadius.circular(6.h),
              ),
              child: Text(
                'Creator',
                style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                    .copyWith(color: appTheme.deep_purple_A100, height: 1.33),
              ),
            ),
          ] else ...[
            Spacer(),
            GestureDetector(
              onTap: onTap,
              child: Container(
                margin: EdgeInsets.only(right: 10.h),
                child: CustomImageView(
                  imagePath: ImageConstant.imgIconBlueGray300,
                  height: 28.h,
                  width: 28.h,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
