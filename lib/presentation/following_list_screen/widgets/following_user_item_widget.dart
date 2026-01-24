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
          ClipOval(
            child: CustomImageView(
              imagePath: user?.profileImagePath ?? '',
              height: 48.h,
              width: 48.h,
              isCircular: true,
              fit: BoxFit.cover,
            ),
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
            child: Icon(
              Icons.person_remove_outlined,
              size: 28.h,
              color: appTheme.blue_gray_300,
            ),
          ),
        ],
      ),
    );
  }
}
