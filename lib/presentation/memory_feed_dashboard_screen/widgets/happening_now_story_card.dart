import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../model/memory_feed_dashboard_model.dart';

class HappeningNowStoryCard extends StatelessWidget {
  final HappeningNowStoryData story;
  final VoidCallback? onTap;

  const HappeningNowStoryCard({
    Key? key,
    required this.story,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug: Log what the widget receives
    print(
        '🔍 DEBUG: Widget rendering story by "${story.userName}" with categoryIcon: "${story.categoryIcon}"');

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
              Positioned.fill(
                child: CustomImageView(
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
                      stops: [0.0, 0.4, 1.0],
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
                    // Profile avatar
                    Container(
                      width: 42.h,
                      height: 42.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: appTheme.gray_50,
                          width: 2.0,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImageView(
                          imagePath: story.profileImage ?? '',
                          height: 42.h,
                          width: 42.h,
                          fit: BoxFit.cover,
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
                            Builder(
                              builder: (context) {
                                print(
                                    '🔍 DEBUG: Displaying category icon: "${story.categoryIcon}"');
                                return CustomImageView(
                                  imagePath: story.categoryIcon,
                                  height: 14.h,
                                  width: 14.h,
                                );
                              },
                            ),
                          if (story.categoryIcon.isEmpty)
                            Builder(
                              builder: (context) {
                                print(
                                    '⚠️ WARNING: No category icon, showing camera fallback');
                                return Text(
                                  '📸',
                                  style: TextStyle(fontSize: 14.h),
                                );
                              },
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
