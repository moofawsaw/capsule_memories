import '../../../core/app_export.dart';
import '../models/timeline_detail_model.dart';
import './timeline_story_widget.dart';

class TimelineDetailWidget extends StatelessWidget {
  final TimelineDetailModel? model;
  final Function(String)? onStoryTap;

  const TimelineDetailWidget({
    Key? key,
    this.model,
    this.onStoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (model == null) {
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Text(
          'Loading timeline...',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (model!.timelineStories != null &&
              model!.timelineStories!.isNotEmpty)
            ...model!.timelineStories!.map(
              (story) => TimelineStoryWidget(
                item: story as TimelineStoryItem,
                onTap: () {
                  if (onStoryTap != null && story.storyId != null) {
                    onStoryTap!(story.storyId!);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}