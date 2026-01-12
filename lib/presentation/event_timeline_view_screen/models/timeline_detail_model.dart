import '../../../core/app_export.dart';
import '../widgets/timeline_story_widget.dart';

/// This class is used in the [event_timeline_view_screen] screen.

// ignore_for_file: must_be_immutable
class TimelineDetailModel extends Equatable {
  TimelineDetailModel({
    this.centerLocation,
    this.centerDistance,
    this.memoryStartTime,
    this.memoryEndTime,
    this.timelineStories,
  }) {
    centerLocation = centerLocation ?? "Unknown location";
    centerDistance = centerDistance ?? "NA";
    memoryStartTime =
        memoryStartTime ?? DateTime.now().subtract(Duration(hours: 2));
    memoryEndTime = memoryEndTime ?? DateTime.now();
    timelineStories = timelineStories ?? [];
  }

  String? centerLocation;
  String? centerDistance;
  DateTime? memoryStartTime;
  DateTime? memoryEndTime;
  List<TimelineStoryItem>? timelineStories;

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
