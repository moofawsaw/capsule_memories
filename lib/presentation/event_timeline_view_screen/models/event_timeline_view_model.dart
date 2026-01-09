import '../../../core/app_export.dart';
import '../../../widgets/custom_story_list.dart';
import 'timeline_detail_model.dart';

/// This class is used in the [event_timeline_view_screen] screen.

// ignore_for_file: must_be_immutable
class EventTimelineViewModel extends Equatable {
  EventTimelineViewModel({
    this.eventTitle,
    this.eventDate,
    this.isPrivate,
    this.categoryIcon,
    this.participantImages,
    this.customStoryItems,
    this.timelineDetail,
    this.memoryId,
  });

  String? eventTitle;
  String? eventDate;
  bool? isPrivate;
  String? categoryIcon;
  List<String>? participantImages;
  List<CustomStoryItem>? customStoryItems;
  TimelineDetailModel? timelineDetail;
  String? memoryId;

  EventTimelineViewModel copyWith({
    String? eventTitle,
    String? eventDate,
    bool? isPrivate,
    String? categoryIcon,
    List<String>? participantImages,
    List<CustomStoryItem>? customStoryItems,
    TimelineDetailModel? timelineDetail,
    String? memoryId,
  }) {
    return EventTimelineViewModel(
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      isPrivate: isPrivate ?? this.isPrivate,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      participantImages: participantImages ?? this.participantImages,
      customStoryItems: customStoryItems ?? this.customStoryItems,
      timelineDetail: timelineDetail ?? this.timelineDetail,
      memoryId: memoryId ?? this.memoryId,
    );
  }

  @override
  List<Object?> get props => [
        eventTitle,
        eventDate,
        isPrivate,
        categoryIcon,
        participantImages,
        customStoryItems,
        timelineDetail,
        memoryId,
      ];
}
