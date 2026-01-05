import '../core/app_export.dart';
import './custom_image_view.dart';

/** 
 * CustomStoryList - A horizontal scrolling story list component that displays story items
 * with background images, profile avatars, and timestamps.
 * 
 * Features:
 * - Horizontal scrolling with customizable gap between items
 * - Story items with background images and overlay content
 * - Profile avatars with read/unread ring styling (gradient for unread, gray for read)
 * - Timestamp display with consistent styling
 * - Navigation callback support for story tapping
 * - Responsive design using SizeUtils extensions
 * 
 * @param storyItems List of story data items
 * @param onStoryTap Optional callback when story is tapped
 * @param itemGap Gap between story items
 * @param margin Margin around the entire list
 */

// IMPORTANT: This widget CANNOT be const because it uses runtime values:
// - .h/.w extensions from Sizer package (runtime calculations)
// - appTheme theme values (runtime theme access)
// - TextStyleHelper.instance (runtime singleton access)
// Flutter hot reload may fail when switching between const/non-const.
// Solution: Perform Hot Restart (not Hot Reload) when you see const-related errors.

class CustomStoryList extends StatelessWidget {
  // Explicitly non-const constructor (required due to runtime values in build method)
  CustomStoryList({
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
      margin: margin,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add left padding to first item
            SizedBox(width: 20.h),
            ...List.generate(
              storyItems.length,
              (index) => Container(
                margin: EdgeInsets.only(
                  right: itemGap ?? 8.h,
                ),
                child: _buildStoryItem(context, storyItems[index], index),
              ),
            ),
            // Add right padding to last item
            SizedBox(width: 12.h),
          ],
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
                  // Profile avatar with read/unread ring
                  Container(
                    width: 32.h,
                    height: 32.h,
                    padding: EdgeInsets.all(2.h), // Gap between ring and avatar
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: item.isRead
                          ? null // No gradient for read stories
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: const [
                                Color(0xFF8B5CF6), // Purple
                                Color(0xFFF97316), // Orange
                              ],
                            ),
                      color: item.isRead
                          ? Color(0xFF9CA3AF)
                          : null, // Gray for read
                      border: item.isRead
                          ? Border.all(color: Color(0xFF9CA3AF), width: 2.h)
                          : null,
                    ),
                    child: Container(
                      width: 28.h,
                      height: 28.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            appTheme.gray_900, // Background color for padding
                      ),
                      padding: EdgeInsets.all(1.h),
                      child: ClipOval(
                        child: CustomImageView(
                          imagePath: item.profileImage,
                          width: 26.h,
                          height: 26.h,
                          fit: BoxFit.cover,
                        ),
                      ),
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
    this.storyId,
    this.isRead = false, // Default to unread (shows gradient ring)
  });

  /// Background image path for the story
  final String backgroundImage;

  /// Profile image path for the story author
  final String profileImage;

  /// Timestamp text (defaults to "2 mins ago" if null)
  final String? timestamp;

  /// Navigation destination identifier
  final String? navigateTo;

  /// Story ID for navigation and tracking
  final String? storyId;

  /// Read/unread state - true shows gray ring, false shows gradient ring
  final bool isRead;
}
