import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/following_list_model.dart';

class FollowingUserItemWidget extends StatelessWidget {
  final FollowingUserModel? user;
  final VoidCallback? onUserTap;
  final VoidCallback? onActionTap;

  FollowingUserItemWidget({
    Key? key,
    required this.user,
    this.onUserTap,
    this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUserTap,
      child: Row(
        spacing: 12.h,
        children: [
          CustomImageView(
            imagePath: user?.profileImagePath ?? '',
            height: 52.h,
            width: 52.h,
            radius: BorderRadius.circular(26.h),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '',
                  style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50, height: 1.28),
                ),
                Text(
                  user?.followersText ?? '',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.29),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: CustomImageView(
              imagePath: ImageConstant.imgIconBlueGray300,
              height: 34.h,
              width: 34.h,
            ),
          ),
        ],
      ),
    );
  }
}
