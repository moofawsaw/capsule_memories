part of 'event_timeline_view_notifier.dart';

class EventTimelineViewState extends Equatable {
  final EventTimelineViewModel? eventTimelineViewModel;
  final bool? isLoading;
  final bool? isSuccess;
  final String? errorMessage;
  final bool isCurrentUserMember;

  EventTimelineViewState({
    this.eventTimelineViewModel,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.isCurrentUserMember = false,
  });

  @override
  List<Object?> get props => [
        eventTimelineViewModel,
        isLoading,
        isSuccess,
        errorMessage,
        isCurrentUserMember,
      ];

  EventTimelineViewState copyWith({
    EventTimelineViewModel? eventTimelineViewModel,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool? isCurrentUserMember,
  }) {
    return EventTimelineViewState(
      eventTimelineViewModel:
          eventTimelineViewModel ?? this.eventTimelineViewModel,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      isCurrentUserMember: isCurrentUserMember ?? this.isCurrentUserMember,
    );
  }
}
