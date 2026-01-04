import '../core/app_export.dart';
import '../core/utils/memory_categories.dart';
import './custom_image_view.dart';

/**
 * CustomStoryCard - A story card component that displays user stories with background images,
 * profile avatars, usernames, category badges, and timestamps in a social media story format.
 * 
 * Features:
 * - Background story image with overlay content
 * - Circular profile avatar with decorative border
 * - Category badge with emoji icon from database
 * - Responsive design with consistent styling
 * - Optional navigation callback support
 * - Dark theme optimized design
 */
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
  }) : super(key: key);

  /// The name of the story creator
  final String userName;

  /// Path to the user's profile avatar image
  final String userAvatar;

  /// Path to the background story image
  final String backgroundImage;

  /// Text label for the category badge
  final String? categoryText;

  /// Icon path for the category badge (will be resolved from MemoryCategories)
  final String? categoryIcon;

  /// Timestamp text (e.g., "2 mins ago")
  final String? timestamp;

  /// Callback function when the story card is tapped
  final VoidCallback? onTap;

  /// Width of the story card
  final double? width;

  /// Height of the story card
  final double? height;

  /// External margin for the card
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    // CRITICAL FIX: Only use MemoryCategories as fallback when NO database icon is available
    // If categoryIcon is provided from database, use it directly
    final category = categoryText != null && categoryIcon == null
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
              // Background story image
              CustomImageView(
                imagePath: backgroundImage,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
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

  /// Builds the circular profile avatar with decorative border
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
        borderRadius: BorderRadius.circular(16.h),
      ),
      child: Center(
        child: CustomImageView(
          imagePath: userAvatar,
          width: 26.h,
          height: 26.h,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Builds the user information section (name, category, timestamp)
  Widget _buildUserInfo(BuildContext context, MemoryCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Username
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

  /// Builds the category badge with emoji icon and text
  Widget _buildCategoryBadge(BuildContext context, MemoryCategory category) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 2.h,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // CRITICAL FIX: Use database icon URL first, fallback to emoji from MemoryCategories
          if (categoryIcon != null && categoryIcon!.isNotEmpty)
            // Database icon URL exists - display it
            CustomImageView(
              imagePath: categoryIcon!,
              width: 20.h,
              height: 20.h,
              fit: BoxFit.contain,
            )
          else
            // No database icon - fallback to static emoji from MemoryCategories
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
