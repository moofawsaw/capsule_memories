import '../models/event_stories_view_model.dart';
import '../models/contributor_item_model.dart';
import '../models/story_item_model.dart';
import '../../../core/app_export.dart';

part 'event_stories_view_state.dart';

final eventStoriesViewNotifier = StateNotifierProvider.autoDispose<
    EventStoriesViewNotifier, EventStoriesViewState>(
  (ref) => EventStoriesViewNotifier(
    EventStoriesViewState(
      eventStoriesViewModel: EventStoriesViewModel(),
    ),
  ),
);

class EventStoriesViewNotifier extends StateNotifier<EventStoriesViewState> {
  EventStoriesViewNotifier(EventStoriesViewState state) : super(state) {
    initialize();
  }

  void initialize() {
    _loadEventData();
  }

  void _loadEventData() {
    final contributorsList = [
      ContributorItemModel(
        contributorId: '1',
        contributorName: 'Jane Doe',
        contributorImage: ImageConstant.imgJaneDoe,
      ),
      ContributorItemModel(
        contributorId: '2',
        contributorName: 'Cassy Downs',
        contributorImage: ImageConstant.imgCassyDowns,
      ),
      ContributorItemModel(
        contributorId: '3',
        contributorName: 'Lily Phillips',
        contributorImage: ImageConstant.imgLilyPhillips,
      ),
    ];

    final storiesList = [
      StoryItemModel(
        storyId: '1',
        storyImage: ImageConstant.imgStory1,
        timeAgo: '2 mins ago',
      ),
      StoryItemModel(
        storyId: '2',
        storyImage: ImageConstant.imgStory2,
        timeAgo: '2 mins ago',
      ),
      StoryItemModel(
        storyId: '3',
        storyImage: ImageConstant.imgStory3,
        timeAgo: '2 mins ago',
      ),
      StoryItemModel(
        storyId: '4',
        storyImage: ImageConstant.imgStory4,
        timeAgo: '3 mins ago',
      ),
      StoryItemModel(
        storyId: '5',
        storyImage: ImageConstant.imgStory5,
        timeAgo: '3 mins ago',
      ),
      StoryItemModel(
        storyId: '6',
        storyImage: ImageConstant.imgStory6,
        timeAgo: '3 mins ago',
      ),
    ];

    state = state.copyWith(
      eventStoriesViewModel: state.eventStoriesViewModel?.copyWith(
        eventTitle: 'Nixon Wedding 2025',
        eventDate: 'Dec 4, 2025',
        eventLocation: 'Tillsonburg, ON',
        viewCount: '19',
        contributorsList: contributorsList,
        storiesList: storiesList,
      ),
      isLoading: false,
    );
  }
}
