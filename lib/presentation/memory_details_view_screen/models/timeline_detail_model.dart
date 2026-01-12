import '../../../core/app_export.dart';

// IMPORTANT: TimelineStoryItem is defined in this file.
import '../../event_timeline_view_screen/widgets/timeline_story_widget.dart';

// ignore_for_file: must_be_immutable

class TimelineDetailModel extends Equatable {
  TimelineDetailModel({
    this.centerLocation,
    this.centerDistance,
    this.memoryStartTime,
    this.memoryEndTime,
    this.timelineStories,
  });

  final String? centerLocation;
  final String? centerDistance;

  // Memory window (used by TimelineWidget)
  final DateTime? memoryStartTime;
  final DateTime? memoryEndTime;

  // Stories rendered on the timeline
  final List<TimelineStoryItem>? timelineStories;

  TimelineDetailModel copyWith({
    String? centerLocation,
    String? centerDistance,
    DateTime? memoryStartTime,
    DateTime? memoryEndTime,
    List<TimelineStoryItem>? timelineStories,
  }) {
    return TimelineDetailModel(
      centerLocation: centerLocation ?? this.centerLocation,
      centerDistance: centerDistance ?? this.centerDistance,
      memoryStartTime: memoryStartTime ?? this.memoryStartTime,
      memoryEndTime: memoryEndTime ?? this.memoryEndTime,
      timelineStories: timelineStories ?? this.timelineStories,
    );
  }

  @override
  List<Object?> get props => [
    centerLocation,
    centerDistance,
    memoryStartTime,
    memoryEndTime,
    timelineStories,
  ];
}
