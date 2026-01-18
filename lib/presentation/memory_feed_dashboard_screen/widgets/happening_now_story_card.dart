import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../model/memory_feed_dashboard_model.dart';

class HappeningNowStoryCard extends StatelessWidget {
  final HappeningNowStoryData story;
  final VoidCallback? onTap;

  HappeningNowStoryCard({
    Key? key,
    required this.story,
    this.onTap,
  }) : super(key: key);

  bool _isNetwork(String? s) {
    if (s == null) return false;
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v == 'null' || v == 'undefined') return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // ✅ FIX: width should be .w, not .h
        width: 160.w,
        height: 240.h,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.0),
          child: Stack(
            children: [
              // ✅ Background image (use Image.network directly - no CustomImageView)
              Positioned.fill(
                child: _isNetwork(story.backgroundImage)
                    ? Image.network(
                  story.backgroundImage ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: appTheme.gray_900_02,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: appTheme.blue_gray_300,
                    ),
                  ),
                )
                    : Container(
                  color: appTheme.gray_900_02,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: appTheme.blue_gray_300,
                  ),
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
                      padding: EdgeInsets.all(2.h),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: story.isRead
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF8B5CF6),
                        border: story.isRead
                            ? Border.all(
                          color: const Color(0xFF9CA3AF),
                          width: 2.h,
                        )
                            : null,
                      ),
                      child: Container(
                        width: 38.h,
                        height: 38.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appTheme.gray_900,
                        ),
                        padding: EdgeInsets.all(2.h),
                        child: ClipOval(
                          child: _CoverAvatar(
                            imagePath: story.profileImage ?? '',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
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
                              fit: BoxFit.contain,
                            )
                          else
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

/// Forces true cover behavior for avatars (prevents stretching).
class _CoverAvatar extends StatelessWidget {
  final String imagePath;

  const _CoverAvatar({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  bool _isNetwork(String s) {
    final v = s.trim();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final String path = imagePath.trim();

    if (path.isEmpty || path == 'null' || path == 'undefined') {
      return Container(
        color: appTheme.gray_900_02,
        alignment: Alignment.center,
        child: Icon(
          Icons.person,
          color: appTheme.blue_gray_300,
          size: 18.h,
        ),
      );
    }

    if (_isNetwork(path)) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: appTheme.gray_900_02,
          alignment: Alignment.center,
          child: Icon(
            Icons.person,
            color: appTheme.blue_gray_300,
            size: 18.h,
          ),
        ),
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
