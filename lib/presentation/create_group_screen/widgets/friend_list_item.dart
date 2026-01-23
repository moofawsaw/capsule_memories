// lib/presentation/create_group_screen/widgets/friend_list_item.dart
// FULL COPY/PASTE FILE
// Matches Edit Group selection UI:
// - selected: full border + tinted background + check_circle icon
// - unselected: same row layout, subtle background

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/create_group_model.dart';

class FriendListItem extends StatelessWidget {
  final FriendModel friend;
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const FriendListItem({
    Key? key,
    required this.friend,
    this.isSelected = false,
    this.onTap,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        margin: margin,
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? appTheme.deep_purple_A100.withAlpha(26)
              : appTheme.gray_50.withAlpha(13),
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
            color: isSelected ? appTheme.deep_purple_A100 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CustomImageView(
              imagePath: friend.profileImage,
              height: 40.h,
              width: 40.h,
              fit: BoxFit.cover,
              radius: BorderRadius.circular(20.h),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: Text(
                friend.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: appTheme.deep_purple_A100,
                size: 24.h,
              ),
          ],
        ),
      ),
    );
  }
}