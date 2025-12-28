part of 'event_timeline_view_notifier.dart';

class EventTimelineViewState extends Equatable {
  final EventTimelineViewModel? eventTimelineViewModel;
  final bool? isLoading;
  final bool? isSuccess;
  final String? errorMessage;

  EventTimelineViewState({
    this.eventTimelineViewModel,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        eventTimelineViewModel,
        isLoading,
        isSuccess,
        errorMessage,
      ];

  EventTimelineViewState copyWith({
    EventTimelineViewModel? eventTimelineViewModel,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return EventTimelineViewState(
      eventTimelineViewModel:
          eventTimelineViewModel ?? this.eventTimelineViewModel,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}
