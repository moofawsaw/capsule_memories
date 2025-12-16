part of 'event_stories_view_notifier.dart';

class EventStoriesViewState extends Equatable {
  final EventStoriesViewModel? eventStoriesViewModel;
  final bool? isLoading;

  EventStoriesViewState({
    this.eventStoriesViewModel,
    this.isLoading = true,
  });

  @override
  List<Object?> get props => [
        eventStoriesViewModel,
        isLoading,
      ];

  EventStoriesViewState copyWith({
    EventStoriesViewModel? eventStoriesViewModel,
    bool? isLoading,
  }) {
    return EventStoriesViewState(
      eventStoriesViewModel:
          eventStoriesViewModel ?? this.eventStoriesViewModel,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
