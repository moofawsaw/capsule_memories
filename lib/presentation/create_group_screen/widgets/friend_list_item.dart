import 'package:flutter/material.dart';
import '../../../widgets/custom_image_view.dart';
import '../../../core/app_export.dart';
import '../models/create_group_model.dart';

class FriendListItem extends StatelessWidget {
  final FriendModel friend;
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  FriendListItem({
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
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 6.h),
        margin: margin,
        decoration: BoxDecoration(
          color: appTheme.gray_900_01,
          borderRadius: BorderRadius.circular(6.h),
        ),
        child: Row(
          children: [
            CustomImageView(
              imagePath: friend.profileImage,
              height: 36.h,
              width: 36.h,
              fit: BoxFit.cover,
              radius: BorderRadius.circular(18.h),
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: Text(
                friend.name ?? '',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ),
            if (isSelected)
              Container(
                width: 20.h,
                height: 20.h,
                decoration: BoxDecoration(
                  color: appTheme.colorFF52D1,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 14.h,
                  color: appTheme.whiteCustom,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
