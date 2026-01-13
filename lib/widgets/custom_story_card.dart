import '../core/app_export.dart';
import '../core/utils/memory_categories.dart';
import './custom_image_view.dart';

class CustomStoryCard extends StatelessWidget {
  CustomStoryCard({
    Key? key,
    required this.userName,
    required this.userAvatar,
    required this.backgroundImage,
    this.categoryText,
    this.categoryIcon,
    this.timestamp,
    this.onTap,
    this.width,
    this.height,
    this.margin,
    this.showDelete = false,
    this.onDelete,
  }) : super(key: key);

  final String userName;
  final String userAvatar;
  final String backgroundImage;

  final String? categoryText;
  final String? categoryIcon;
  final String? timestamp;

  final VoidCallback? onTap;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  // ✅ Delete support (UI only)
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final category = categoryText != null && (categoryIcon == null)
        ? MemoryCategories.getByName(categoryText!)
        : MemoryCategories.custom;

    return Container(
      width: width ?? 116.h,
      height: height ?? 202.h,
      margin: margin,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            border: Border.all(
              color: appTheme.gray_900_02,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Stack(
            children: [
// Background story image (FULL CARD)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.h),
                  child: CustomImageView(
                    imagePath: backgroundImage,
                    fit: BoxFit.cover,
                    // ✅ do NOT pass infinity; Positioned.fill gives size via constraints
                    // width/height intentionally omitted
                  ),
                ),
              ),

              // ✅ Delete button overlay (top-right)
              if (showDelete)
                Positioned(
                  top: 8.h,
                  right: 8.h,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: EdgeInsets.all(6.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18.h,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Overlay content
              Positioned(
                left: 6.h,
                right: 6.h,
                top: 12.h,
                bottom: 12.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileAvatar(context),
                    Spacer(),
                    _buildUserInfo(context, category),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return Container(
      width: 32.h,
      height: 32.h,
      margin: EdgeInsets.only(left: 4.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: appTheme.deep_purple_A100,
          width: 2,
        ),
        shape: BoxShape.circle, // ✅ circle border
      ),
      child: ClipOval( // ✅ actually clips the image
        child: CustomImageView(
          imagePath: userAvatar,
          width: 32.h,
          height: 32.h,
          fit: BoxFit.cover,
        ),
      ),
    );
  }


  Widget _buildUserInfo(BuildContext context, MemoryCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          userName,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.white_A700, height: 1.29),
        ),
        if (categoryText != null) ...[
          SizedBox(height: 18.h),
          _buildCategoryBadge(context, category),
        ],
        if (timestamp != null) ...[
          SizedBox(height: 4.h),
          Text(
            timestamp!,
            style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                .copyWith(color: appTheme.white_A700, height: 1.33),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context, MemoryCategory category) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.h, vertical: 2.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (categoryIcon != null && categoryIcon!.isNotEmpty)
            CustomImageView(
              imagePath: categoryIcon!,
              width: 20.h,
              height: 20.h,
              fit: BoxFit.contain,
            )
          else
            Text(
              category.emoji,
              style: TextStyle(fontSize: 20.h),
            ),
          SizedBox(width: 8.h),
          Text(
            categoryText ?? '',
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50, height: 1.33),
          ),
        ],
      ),
    );
  }
}
