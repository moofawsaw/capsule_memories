import '../../../core/app_export.dart';
import '../../../widgets/custom_story_list.dart'
    as story_list; // Modified: Added alias to resolve ambiguous import
import 'timeline_detail_model.dart';

/// This class is used in the [event_timeline_view_screen] screen.

// ignore_for_file: must_be_immutable
class EventTimelineViewModel extends Equatable {
  EventTimelineViewModel({
    this.eventTitle,
    this.eventDate,
    this.isPrivate,
    this.participantImages,
    this.storyItems,
    this.timelineDetail,
    this.storiesCount,
  }) {
    eventTitle = eventTitle ?? "Nixon Wedding 2025";
    eventDate = eventDate ?? "Dec 4, 2025";
    isPrivate = isPrivate ?? true;
    participantImages = participantImages ?? [];
    storyItems = storyItems ?? [];
    storiesCount = storiesCount ?? 6;
  }

  String? eventTitle;
  String? eventDate;
  bool? isPrivate;
  List<String>? participantImages;
  List<story_list.CustomStoryItem>?
      storyItems; // Modified: Used alias to resolve ambiguous import
  TimelineDetailModel? timelineDetail;
  int? storiesCount;

  EventTimelineViewModel copyWith({
    String? eventTitle,
    String? eventDate,
    bool? isPrivate,
    List<String>? participantImages,
    List<story_list.CustomStoryItem>?
        storyItems, // Modified: Used alias to resolve ambiguous import
    TimelineDetailModel? timelineDetail,
    int? storiesCount,
  }) {
    return EventTimelineViewModel(
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      isPrivate: isPrivate ?? this.isPrivate,
      participantImages: participantImages ?? this.participantImages,
      storyItems: storyItems ?? this.storyItems,
      timelineDetail: timelineDetail ?? this.timelineDetail,
      storiesCount: storiesCount ?? this.storiesCount,
    );
  }

  @override
  List<Object?> get props => [
        eventTitle,
        eventDate,
        isPrivate,
        participantImages,
        storyItems,
        timelineDetail,
        storiesCount,
      ];
}
