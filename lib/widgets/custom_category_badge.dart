import '../core/app_export.dart';
import './custom_image_view.dart';

class CustomCategoryBadge extends StatelessWidget {
  final String iconUrl;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const CustomCategoryBadge({
    Key? key,
    required this.iconUrl,
    required this.title,
    required this.description,
    this.onTap,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160.w,
        margin: EdgeInsets.only(right: 12.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: backgroundColor ?? appTheme.blue_gray_900_01,
          borderRadius: BorderRadius.circular(16.h),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomImageView(
              imagePath: iconUrl,
              width: 32.h,
              height: 32.h,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
