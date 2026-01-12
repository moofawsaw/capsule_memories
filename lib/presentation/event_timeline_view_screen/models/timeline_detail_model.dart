import '../../../core/app_export.dart';
import '../widgets/timeline_story_widget.dart';
import '../../event_timeline_view_screen/widgets/timeline_story_widget.dart';

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
    // Keep only string defaults. Do NOT default timestamps.
    centerLocation = centerLocation ?? "Unknown location";
    centerDistance = centerDistance ?? "NA";

    // IMPORTANT:
    // Do NOT do:
    // memoryStartTime = memoryStartTime ?? DateTime.now().subtract(...)
    // memoryEndTime   = memoryEndTime ?? DateTime.now()
    //
    // Because your UI intentionally treats null as "still loading / not ready".
    timelineStories = timelineStories ?? [];
  }

  String? centerLocation;
  String? centerDistance;

  /// Keep these nullable until real DB values are loaded.
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
