part of 'event_stories_view_notifier.dart';

class EventStoriesViewState extends Equatable {
  EventStoriesViewState({
    this.eventStoriesViewModel,
    this.isLoading = false,
    this.errorMessage,
  });

  final Map<String, dynamic>? eventStoriesViewModel;
  final bool isLoading;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        eventStoriesViewModel,
        isLoading,
        errorMessage,
      ];

  EventStoriesViewState copyWith({
    Map<String, dynamic>? eventStoriesViewModel,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EventStoriesViewState(
      eventStoriesViewModel:
          eventStoriesViewModel ?? this.eventStoriesViewModel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}