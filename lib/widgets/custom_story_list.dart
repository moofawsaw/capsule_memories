import '../core/app_export.dart';
import 'custom_image_view.dart';

/** 
 * CustomStoryList - A horizontal scrolling story list component that displays story items
 * with background images, profile avatars, and timestamps.
 * 
 * Features:
 * - Horizontal scrolling with customizable gap between items
 * - Story items with background images and overlay content
 * - Profile avatars with purple border styling
 * - Timestamp display with consistent styling
 * - Navigation callback support for story tapping
 * - Responsive design using SizeUtils extensions
 * 
 * @param storyItems List of story data items
 * @param onStoryTap Optional callback when story is tapped
 * @param itemGap Gap between story items
 * @param margin Margin around the entire list
 */
class CustomStoryList extends StatelessWidget {
  const CustomStoryList({
    Key? key,
    required this.storyItems,
    this.onStoryTap,
    this.itemGap,
    this.margin,
  }) : super(key: key);

  /// List of story items to display
  final List<CustomStoryItem> storyItems;

  /// Callback when a story is tapped, receives story index
  final Function(int index)? onStoryTap;

  /// Gap between story items
  final double? itemGap;

  /// Margin around the entire story list
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(top: 18.h, left: 20.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            storyItems.length,
            (index) => Container(
              margin: EdgeInsets.only(
                right: index < storyItems.length - 1 ? (itemGap ?? 8.h) : 0,
              ),
              child: _buildStoryItem(context, storyItems[index], index),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds individual story item widget
  Widget _buildStoryItem(
      BuildContext context, CustomStoryItem item, int index) {
    return GestureDetector(
      onTap: () => onStoryTap?.call(index),
      child: SizedBox(
        width: 90.h,
        height: 120.h,
        child: Stack(
          children: [
            // Background image
            CustomImageView(
              imagePath: item.backgroundImage,
              width: 90.h,
              height: 120.h,
              fit: BoxFit.cover,
              radius: BorderRadius.circular(12.h),
            ),

            // Overlay content
            Positioned(
              left: 12.h,
              top: 12.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile avatar with border
                  Container(
                    width: 32.h,
                    height: 32.h,
                    padding: EdgeInsets.all(3.h),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: appTheme.deep_purple_A100,
                        width: 2.h,
                      ),
                      borderRadius: BorderRadius.circular(16.h),
                    ),
                    child: CustomImageView(
                      imagePath: item.profileImage,
                      width: 26.h,
                      height: 26.h,
                      fit: BoxFit.cover,
                      radius: BorderRadius.circular(13.h),
                    ),
                  ),

                  SizedBox(height: 50.h),

                  // Timestamp
                  Text(
                    item.timestamp ?? '2 mins ago',
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(color: appTheme.white_A700, height: 1.33),
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

/// Data model for individual story items
class CustomStoryItem {
  const CustomStoryItem({
    required this.backgroundImage,
    required this.profileImage,
    this.timestamp,
    this.navigateTo,
  });

  /// Background image path for the story
  final String backgroundImage;

  /// Profile image path for the story author
  final String profileImage;

  /// Timestamp text (defaults to "2 mins ago" if null)
  final String? timestamp;

  /// Navigation destination identifier
  final String? navigateTo;
}
