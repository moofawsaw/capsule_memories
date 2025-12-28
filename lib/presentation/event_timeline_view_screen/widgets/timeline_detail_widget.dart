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

  @override
  Widget build(BuildContext context) {
    // CRITICAL DEBUG: Log what data widget receives for rendering
    print('🚨 TIMELINE WIDGET DEBUG: TimelineDetailWidget.build() called');
    print('   - model is null: ${model == null}');
    if (model != null) {
      print('   - centerLocation: "${model?.centerLocation}"');
      print('   - centerDistance: "${model?.centerDistance}"');
      print(
          '   - timelineStories count: ${model?.timelineStories?.length ?? 0}');
      print(
          '   - Using fallback location: ${model?.centerLocation == "Tillsonburg, ON"}');
      print('   - Using fallback distance: ${model?.centerDistance == "21km"}');
    }

    return Container(
      child: Column(
        children: [
          // Location and distance info
          Text(
            model?.centerLocation ?? "Tillsonburg, ON",
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
          SizedBox(height: 4.h),
          Text(
            model?.centerDistance ?? "21km",
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),

          SizedBox(height: 24.h),

          // Timeline with positioned story cards
          if (model?.timelineStories != null &&
              model!.timelineStories!.isNotEmpty)
            TimelineStoryWidget(
              stories: model!.timelineStories!,
              memoryStartTime: model?.memoryStartTime ??
                  DateTime.now().subtract(Duration(hours: 2)),
              memoryEndTime: model?.memoryEndTime ?? DateTime.now(),
              timelineHeight: 200,
              onStoryTap: onStoryTap,
            ),
        ],
      ),
    );
  }
}
