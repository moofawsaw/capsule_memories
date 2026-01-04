import '../../../core/app_export.dart';

/// Timeline Story Widget - Individual story card with vertical layout
class TimelineStoryWidget extends StatelessWidget {
  final TimelineStoryItem item;
  final VoidCallback? onTap;

  const TimelineStoryWidget({
    Key? key,
    required this.item,
    this.onTap,
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
            // Story Card (phone-shaped)
            _buildStoryCard(),

            // Vertical connector line
            Container(
              width: 4.w,
              height: 19.h,
              color: const Color(0xFF3A3A4A),
            ),

            // User Avatar with gradient ring
            _buildAvatarWithRing(),

            SizedBox(height: 4.h),

            // Time/Location label
            Text(
              item.timeLabel ?? _formatTime(item.postedAt),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    return Container(
      width: 40.w,
      height: 60.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: const Color(0xFF8B5CF6), // Purple border
          width: 2,
        ),
        image: DecorationImage(
          image: NetworkImage(item.backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        // Play icon overlay for videos
        child: Container(
          padding: EdgeInsets.all(6.h),
          decoration: const BoxDecoration(
            color: Colors.black38,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWithRing() {
    return Container(
      width: 32.h,
      height: 32.h,
      padding: EdgeInsets.all(2.h), // Ring thickness
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(item.userAvatar),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class TimelineStoryItem {
  const TimelineStoryItem({
    required this.backgroundImage,
    required this.userAvatar,
    required this.postedAt,
    this.timeLabel,
    this.storyId,
    @Deprecated('Use storyId with onStoryTap callback instead') this.onTap,
  });

  final String backgroundImage;
  final String userAvatar;
  final DateTime postedAt;
  final String? timeLabel;
  final String? storyId;
  @Deprecated('Use storyId with onStoryTap callback instead')
  final VoidCallback? onTap;
}
