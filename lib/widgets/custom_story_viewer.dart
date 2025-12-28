import '../core/app_export.dart';
import './custom_icon_button.dart';
import './custom_image_view.dart';

/** 
 * CustomStoryViewer - A reusable story viewer component that displays multiple story items with play buttons, 
 * profile images, and timeline indicators. Supports customizable story items, interactive play buttons, 
 * profile image display, and responsive design with proper spacing and alignment.
 */
class CustomStoryViewer extends StatelessWidget {
  CustomStoryViewer({
    Key? key,
    this.storyItems,
    this.profileImages,
    this.onStoryTap,
    this.onPlayButtonTap,
    this.onProfileTap,
    this.showTimestamp = true,
    this.timestampText,
    this.margin,
    this.spacing,
  }) : super(key: key);

  /// List of story items to display
  final List<CustomStoryItem>? storyItems;

  /// List of profile images to show at bottom
  final List<String>? profileImages;

  /// Callback when story item is tapped
  final Function(int index)? onStoryTap;

  /// Callback when play button is tapped
  final Function(int index)? onPlayButtonTap;

  /// Callback when profile image is tapped
  final Function(int index)? onProfileTap;

  /// Whether to show timestamp
  final bool showTimestamp;

  /// Custom timestamp text
  final String? timestampText;

  /// Margin around the entire component
  final EdgeInsetsGeometry? margin;

  /// Spacing between story items
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final items = storyItems ?? [];
    final profiles = profileImages ?? [];
    final itemSpacing = spacing ?? 6.h;
    final timestamp = timestampText ?? 'now';

    return Container(
      margin: margin,
      width: 238.h,
      height: 112.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Story items row
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Container(
                  margin: EdgeInsets.only(left: index > 0 ? itemSpacing : 0),
                  child: _buildStoryItem(context, item, index),
                );
              }),
            ),
          ),

          // Bottom section with timestamp and profiles
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSection(context, timestamp, profiles),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryItem(
      BuildContext context, CustomStoryItem item, int index) {
    return GestureDetector(
      onTap: () => onStoryTap?.call(index),
      child: Container(
        width: 40.h,
        height: 56.h,
        decoration: BoxDecoration(
          border: Border.all(
            color: appTheme.deep_purple_A200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6.h),
          color: appTheme.gray_900_01,
        ),
        child: Stack(
          children: [
            // Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(6.h),
              child: CustomImageView(
                imagePath: item.imagePath,
                width: 40.h,
                height: 56.h,
                fit: BoxFit.cover,
              ),
            ),

            // Play button overlay
            if (item.showPlayButton)
              Positioned(
                top: 4.h,
                left: 4.h,
                child: CustomIconButton(
                  iconPath: item.playIconPath ?? ImageConstant.imgPlayCircle,
                  height: 24.h,
                  width: 24.h,
                  backgroundColor: appTheme.color3BD81E,
                  borderRadius: 6.h,
                  padding: EdgeInsets.all(4.h),
                  onTap: () => onPlayButtonTap?.call(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(
      BuildContext context, String timestamp, List<String> profiles) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Spacer and profiles section
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.h),
            margin: EdgeInsets.only(top: 36.h),
            child: Column(
              children: [
                // Purple divider lines
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 2.h,
                        height: 16.h,
                        color: appTheme.deep_purple_A100,
                      ),
                      SizedBox(width: 46.h),
                      Container(
                        width: 2.h,
                        height: 16.h,
                        color: appTheme.deep_purple_A100,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 1.h),

                // Profile images
                if (profiles.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: List.generate(profiles.length, (index) {
                      return GestureDetector(
                        onTap: () => onProfileTap?.call(index),
                        child: Container(
                          margin: EdgeInsets.only(left: index > 0 ? 18.h : 0),
                          child: CustomImageView(
                            imagePath: profiles[index],
                            width: 28.h,
                            height: 28.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Data model for story items
class CustomStoryItem {
  CustomStoryItem({
    required this.imagePath,
    this.showPlayButton = true,
    this.playIconPath,
  });

  /// Path to the story image
  final String imagePath;

  /// Whether to show play button overlay
  final bool showPlayButton;

  /// Custom play icon path (optional)
  final String? playIconPath;
}
