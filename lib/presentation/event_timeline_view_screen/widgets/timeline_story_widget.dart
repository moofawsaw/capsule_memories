import '../../../core/app_export.dart';

/// Data model for timeline story items
class TimelineStoryItem {
  const TimelineStoryItem({
    required this.backgroundImage,
    required this.userAvatar,
    required this.postedAt,
    this.timeLabel,
    this.storyId,
    this.isVideo = true,
  });

  final String backgroundImage;
  final String userAvatar;
  final DateTime postedAt;
  final String? timeLabel;
  final String? storyId;
  final bool isVideo;
}

/// Individual timeline story widget with vertical layout
/// Card at top, connector, avatar at bottom
class TimelineStoryWidget extends StatelessWidget {
  final TimelineStoryItem item;
  final VoidCallback? onTap;
  final double barPosition; // Y position of the horizontal bar

  const TimelineStoryWidget({
    Key? key,
    required this.item,
    this.onTap,
    this.barPosition = 85.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story Card (phone-shaped) - ABOVE THE BAR
            _buildStoryCard(),

            // Vertical connector from card to bar
            Container(
              width: 3.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4A),
                borderRadius: BorderRadius.circular(1.5.w),
              ),
            ),

            // Space for the horizontal bar (handled by parent Stack)
            SizedBox(height: 4.h),

            // Vertical connector from bar to avatar
            Container(
              width: 3.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4A),
                borderRadius: BorderRadius.circular(1.5.w),
              ),
            ),

            // User Avatar with gradient ring - BELOW THE BAR
            _buildAvatarWithRing(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      width: 48.w,
      height: 68.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.h),
        border: Border.all(
          color: const Color(0xFF8B5CF6), // Purple border
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(102),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.h),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              item.backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF2A2A3A),
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.white38,
                  size: 20.h,
                ),
              ),
            ),

            // Play icon overlay (for videos)
            if (item.isVideo)
              Center(
                child: Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18.h,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithRing() {
    return Container(
      width: 40.h,
      height: 40.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Solid primary purple color instead of gradient
        color: const Color(0xFF8B5CF6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withAlpha(102),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(2.5.h), // Ring thickness
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A1A2E), // Dark background fallback
        ),
        child: ClipOval(
          child: Image.network(
            item.userAvatar,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF2A2A3A),
              child: Icon(
                Icons.person,
                color: Colors.white38,
                size: 20.h,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
