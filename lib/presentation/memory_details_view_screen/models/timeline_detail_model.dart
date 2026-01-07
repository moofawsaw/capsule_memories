import '../../../core/app_export.dart';
import '../../../widgets/timeline_widget.dart';

class TimelineDetailModel extends Equatable {
  final String centerLocation;
  final String centerDistance;
  final DateTime? memoryStartTime;
  final DateTime? memoryEndTime;
  final List<TimelineStoryItem>? timelineStories;

  const TimelineDetailModel({
    required this.centerLocation,
    required this.centerDistance,
    this.memoryStartTime,
    this.memoryEndTime,
    this.timelineStories,
  });

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
