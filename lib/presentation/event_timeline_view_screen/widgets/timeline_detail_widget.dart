import '../../../core/app_export.dart';
import '../models/timeline_detail_model.dart';
import './timeline_story_widget.dart';

class TimelineDetailWidget extends StatelessWidget {
  final TimelineDetailModel? model;
  final Function(String storyId)? onStoryTap;

  TimelineDetailWidget({
    Key? key,
    this.model,
    this.onStoryTap,
  }) : super(key: key);

  double _calculateTimelineWidth() {
    // Calculate based on number of stories + spacing
    final storyCount = model?.timelineStories?.length ?? 1;
    return (storyCount * 80.w) + 100.w; // Card width + padding
  }

  @override
  Widget build(BuildContext context) {
    if (model == null) {
      return Container(
        height: 180.h,
        child: Center(
          child: CircularProgressIndicator(
            color: appTheme.deep_purple_A100,
          ),
        ),
      );
    }

    // Debug logging
    debugPrint('Timeline stories count: ${model!.timelineStories?.length}');
    model!.timelineStories?.forEach(
        (s) => debugPrint('Story ${s.storyId}: posted ${s.postedAt}'));

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      height: 180.h, // Enough for cards + line + avatars + labels
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _calculateTimelineWidth(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Horizontal timeline line (positioned in middle)
              Positioned(
                left: 40.w,
                right: 40.w,
                top: 85.h, // Below story cards
                child: Container(
                  height: 2.h,
                  color: Color(0xFF3A3A4A), // Dark gray line
                ),
              ),

              // Story items positioned along timeline
              if (model!.timelineStories != null)
                ...model!.timelineStories!.map((story) {
                  final leftPos = _calculatePosition(story.postedAt);
                  return Positioned(
                    left: leftPos,
                    top: 0,
                    child: TimelineStoryWidget(
                      item: story,
                      onTap: () => onStoryTap?.call(story.storyId ?? ''),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  double _calculatePosition(DateTime postedAt) {
    if (model?.timelineStories == null || model!.timelineStories!.isEmpty) {
      return 40.w;
    }

    final memoryStartTime =
        model?.memoryStartTime ?? DateTime.now().subtract(Duration(hours: 2));
    final memoryEndTime = model?.memoryEndTime ?? DateTime.now();

    final totalDuration =
        memoryEndTime.difference(memoryStartTime).inMilliseconds.toDouble();
    final elapsed =
        postedAt.difference(memoryStartTime).inMilliseconds.toDouble();

    final percentage = (elapsed / totalDuration).clamp(0.0, 1.0);
    final totalWidth = _calculateTimelineWidth();

    return (40.w + (totalWidth - 80.w) * percentage);
  }
}
