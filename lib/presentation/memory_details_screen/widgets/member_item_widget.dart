import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/memory_details_model.dart';

class MemberItemWidget extends ConsumerWidget {
  final MemberModel member;
  final bool isCreator;
  final VoidCallback? onRemove;

  const MemberItemWidget({
    Key? key,
    required this.member,
    this.isCreator = false,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show remove icon only if current user is creator AND this member is not the creator
    final showRemoveIcon = isCreator && !(member.isCreator ?? false);

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
          ] else if (showRemoveIcon) ...[
            SizedBox(width: 8.h),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(6.h),
                decoration: BoxDecoration(
                  color: appTheme.red_500.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.h),
                ),
                child: Icon(
                  Icons.person_remove,
                  color: appTheme.red_500,
                  size: 18.h,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
