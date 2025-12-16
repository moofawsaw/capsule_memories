part of 'event_timeline_view_notifier.dart';

class EventTimelineViewState extends Equatable {
  final EventTimelineViewModel? eventTimelineViewModel;
  final bool? isLoading;
  final bool? isSuccess;

  EventTimelineViewState({
    this.eventTimelineViewModel,
    this.isLoading = false,
    this.isSuccess = false,
  });

  @override
  List<Object?> get props => [
        eventTimelineViewModel,
        isLoading,
        isSuccess,
      ];

  EventTimelineViewState copyWith({
    EventTimelineViewModel? eventTimelineViewModel,
    bool? isLoading,
    bool? isSuccess,
  }) {
    return EventTimelineViewState(
      eventTimelineViewModel:
          eventTimelineViewModel ?? this.eventTimelineViewModel,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
