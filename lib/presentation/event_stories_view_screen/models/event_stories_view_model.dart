import '../../../core/app_export.dart';
import '../../../widgets/custom_story_list.dart';

/// This class is used in the [event_timeline_view_screen] screen.

// ignore_for_file: must_be_immutable
class EventTimelineViewModel extends Equatable {
  EventTimelineViewModel({
    this.eventTitle,
    this.eventDate,
    this.eventLocation, // ✅ add
    this.isPrivate,
    this.categoryIcon,
    this.participantImages,
    this.customStoryItems,
    this.memoryId,
  });

  String? eventTitle;
  String? eventDate;
  String? eventLocation; // ✅ add
  bool? isPrivate;
  String? categoryIcon;
  List<String>? participantImages;
  List<CustomStoryItem>? customStoryItems;
  String? memoryId;

  EventTimelineViewModel copyWith({
    String? eventTitle,
    String? eventDate,
    String? eventLocation, // ✅ add
    bool? isPrivate,
    String? categoryIcon,
    List<String>? participantImages,
    List<CustomStoryItem>? customStoryItems,
    String? memoryId,
  }) {
    return EventTimelineViewModel(
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation, // ✅ add
      isPrivate: isPrivate ?? this.isPrivate,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      participantImages: participantImages ?? this.participantImages,
      customStoryItems: customStoryItems ?? this.customStoryItems,
      memoryId: memoryId ?? this.memoryId,
    );
  }

  @override
  List<Object?> get props => [
    eventTitle,
    eventDate,
    eventLocation, // ✅ add
    isPrivate,
    categoryIcon,
    participantImages,
    customStoryItems,
    memoryId,
  ];
}