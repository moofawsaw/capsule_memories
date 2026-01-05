part of 'event_timeline_view_notifier.dart';

class EventTimelineViewState extends Equatable {
  final EventTimelineViewModel? eventTimelineViewModel;
  final bool? isLoading;
  final bool? isSuccess;
  final String? errorMessage;
  final bool? isCurrentUserMember;
  final bool? isCurrentUserCreator;

  // CRITICAL FIX: Add state properties for timeline widget
  final List<TimelineStoryItem> timelineStories;
  final DateTime? memoryStartTime;
  final DateTime? memoryEndTime;
  final String? memoryId;

  EventTimelineViewState({
    this.eventTimelineViewModel,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.isCurrentUserMember = false,
    this.isCurrentUserCreator = false,
    this.timelineStories = const [],
    this.memoryStartTime,
    this.memoryEndTime,
    this.memoryId,
  });

  @override
  List<Object?> get props => [
        eventTimelineViewModel,
        isLoading,
        isSuccess,
        errorMessage,
        isCurrentUserMember,
        isCurrentUserCreator,
        timelineStories,
        memoryStartTime,
        memoryEndTime,
        memoryId,
      ];

  EventTimelineViewState copyWith({
    EventTimelineViewModel? eventTimelineViewModel,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool? isCurrentUserMember,
    bool? isCurrentUserCreator,
    List<TimelineStoryItem>? timelineStories,
    DateTime? memoryStartTime,
    DateTime? memoryEndTime,
    String? memoryId,
  }) {
    return EventTimelineViewState(
      eventTimelineViewModel:
          eventTimelineViewModel ?? this.eventTimelineViewModel,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      isCurrentUserMember: isCurrentUserMember ?? this.isCurrentUserMember,
      isCurrentUserCreator: isCurrentUserCreator ?? this.isCurrentUserCreator,
      timelineStories: timelineStories ?? this.timelineStories,
      memoryStartTime: memoryStartTime ?? this.memoryStartTime,
      memoryEndTime: memoryEndTime ?? this.memoryEndTime,
      memoryId: memoryId ?? this.memoryId,
    );
  }
}
