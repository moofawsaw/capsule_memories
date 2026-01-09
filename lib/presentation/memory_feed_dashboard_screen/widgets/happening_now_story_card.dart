import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../model/memory_feed_dashboard_model.dart';

// IMPORTANT: This widget CANNOT be const because it uses runtime values:
// - .h/.w extensions from Sizer package (runtime calculations)
// - appTheme theme values (runtime theme access)
// - TextStyleHelper.instance (runtime singleton access)
// Flutter hot reload may fail when switching between const/non-const.
// Solution: Perform Hot Restart (not Hot Reload) when you see const-related errors.

class HappeningNowStoryCard extends StatelessWidget {
  final HappeningNowStoryData story;
  final VoidCallback? onTap;

  // Explicitly non-const constructor (required due to runtime values in build method)
  HappeningNowStoryCard({
    Key? key,
    required this.story,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🎨 DEBUG: Log widget build with isRead status
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎨 WIDGET BUILD: HappeningNowStoryCard');
    print('   Story ID: "${story.storyId}"');
    print('   User Name: "${story.userName}"');
    print('   isRead Status: ${story.isRead}');
    print(
        '   Ring Display: ${story.isRead ? 'GRAY (read)' : 'GRADIENT (unread)'}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160.h,
        height: 240.h,
        margin: EdgeInsets.only(right: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.0),
          child: Stack(
            children: [
              // Background image filling the entire card
              // CRITICAL FIX: Use ValueKey to preserve CustomImageView animation state across rebuilds
              // This prevents thumbnail animation from retriggering when story viewer closes
              Positioned.fill(
                child: CustomImageView(
                  key: ValueKey(story
                      .backgroundImage), // Preserve state for this specific URL
                  imagePath: story.backgroundImage ?? '',
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient overlay for better text visibility
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(153),
                        Colors.transparent,
                        Colors.black.withAlpha(102),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Content overlay
              Positioned(
                top: 12.h,
                left: 12.h,
                right: 12.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile avatar with read/unread ring
                    Container(
                      width: 46.h,
                      height: 46.h,
                      padding:
                          EdgeInsets.all(2.h), // Gap between ring and avatar
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Solid primary color for unread, gray for read
                        color: story.isRead
                            ? Color(0xFF9CA3AF) // Gray for read
                            : Color(0xFF8B5CF6), // Primary purple for unread
                        border: story.isRead
                            ? Border.all(color: Color(0xFF9CA3AF), width: 2.h)
                            : null,
                      ),
                      child: Container(
                        width: 38.h,
                        height: 38.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              appTheme.gray_900, // Background color for padding
                        ),
                        padding: EdgeInsets.all(2.h),
                        child: ClipOval(
                          child: CustomImageView(
                            imagePath: story.profileImage ?? '',
                            height: 38.h,
                            width: 38.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // User name
                    Text(
                      story.userName ?? '',
                      style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                          .copyWith(
                        color: appTheme.gray_50,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Category badge and timestamp at bottom
              Positioned(
                bottom: 12.h,
                left: 12.h,
                right: 12.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge with icon and name from database
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.h,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: appTheme.gray_900.withAlpha(230),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (story.categoryIcon.isNotEmpty)
                            CustomImageView(
                              imagePath: story.categoryIcon,
                              height: 14.h,
                              width: 14.h,
                            ),
                          if (story.categoryIcon.isEmpty)
                            Text(
                              '📸',
                              style: TextStyle(fontSize: 14.h),
                            ),
                          SizedBox(width: 4.h),
                          Text(
                            story.categoryName ?? 'Custom',
                            style: TextStyleHelper
                                .instance.body12MediumPlusJakartaSans
                                .copyWith(
                              color: appTheme.gray_50,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Timestamp
                    Text(
                      story.timestamp ?? '',
                      style: TextStyleHelper
                          .instance.body12MediumPlusJakartaSans
                          .copyWith(
                        color: appTheme.gray_50.withAlpha(230),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
