import '../../../core/app_export.dart';
import '../../../widgets/timeline_widget.dart';

class TimelineStoryWidget extends StatelessWidget {
  final TimelineStoryItem item;
  final DateTime? memoryStartTime;
  final DateTime? memoryEndTime;
  final VoidCallback? onTap;

  const TimelineStoryWidget({
    Key? key,
    required this.item,
    this.memoryStartTime,
    this.memoryEndTime,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final position = _calculatePosition();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: position, bottom: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48.h,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.h),
                image: DecorationImage(
                  image: NetworkImage(item.backgroundImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32.h,
                  height: 32.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(item.userAvatar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.timeLabel ?? '',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePosition() {
    if (memoryStartTime == null || memoryEndTime == null) {
      return 20.w;
    }

    final totalDuration = memoryEndTime!.difference(memoryStartTime!);
    final storyDuration = item.postedAt.difference(memoryStartTime!);

    if (totalDuration.inSeconds <= 0) return 20.w;

    final ratio = storyDuration.inSeconds / totalDuration.inSeconds;
    final clampedRatio = ratio.clamp(0.0, 1.0);

    return (clampedRatio * 300.w) + 20.w;
  }
}
