import '../../../core/app_export.dart';
import 'contributor_item_model.dart';
import 'story_item_model.dart';

/// This class is used in the [event_stories_view_screen] screen.

// ignore_for_file: must_be_immutable
class EventStoriesViewModel extends Equatable {
  EventStoriesViewModel({
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.viewCount,
    this.contributorsList,
    this.storiesList,
  }) {
    eventTitle = eventTitle ?? "Nixon Wedding 2025";
    eventDate = eventDate ?? "Dec 4, 2025";
    eventLocation = eventLocation ?? "Tillsonburg, ON";
    viewCount = viewCount ?? "19";
    contributorsList = contributorsList ?? [];
    storiesList = storiesList ?? [];
  }

  String? eventTitle;
  String? eventDate;
  String? eventLocation;
  String? viewCount;
  List<ContributorItemModel>? contributorsList;
  List<StoryItemModel>? storiesList;

  EventStoriesViewModel copyWith({
    String? eventTitle,
    String? eventDate,
    String? eventLocation,
    String? viewCount,
    List<ContributorItemModel>? contributorsList,
    List<StoryItemModel>? storiesList,
  }) {
    return EventStoriesViewModel(
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      eventLocation: eventLocation ?? this.eventLocation,
      viewCount: viewCount ?? this.viewCount,
      contributorsList: contributorsList ?? this.contributorsList,
      storiesList: storiesList ?? this.storiesList,
    );
  }

  @override
  List<Object?> get props => [
        eventTitle,
        eventDate,
        eventLocation,
        viewCount,
        contributorsList,
        storiesList,
      ];
}
