import '../../../widgets/custom_story_list.dart'
    as story_list; // Modified: Added alias to resolve ambiguous import
import '../models/event_timeline_view_model.dart';
import '../models/timeline_detail_model.dart';
import '../../../core/app_export.dart';

part 'event_timeline_view_state.dart';

final eventTimelineViewNotifier = StateNotifierProvider.autoDispose<
    EventTimelineViewNotifier, EventTimelineViewState>(
  (ref) => EventTimelineViewNotifier(
    EventTimelineViewState(
      eventTimelineViewModel: EventTimelineViewModel(),
    ),
  ),
);

class EventTimelineViewNotifier extends StateNotifier<EventTimelineViewState> {
  EventTimelineViewNotifier(EventTimelineViewState state) : super(state) {
    initialize();
  }

  void initialize() {
    // Initialize story items
    List<story_list.CustomStoryItem> storyItems = [
      // Modified: Used alias to resolve ambiguous import
      story_list.CustomStoryItem(
        // Modified: Used alias and fixed constructor call
        backgroundImage: ImageConstant.imgImage8202x116,
        profileImage: ImageConstant.imgFrame2,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
      story_list.CustomStoryItem(
        // Modified: Used alias and fixed constructor call
        backgroundImage: ImageConstant.imgImage8120x90,
        profileImage: ImageConstant.imgFrame1,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
      story_list.CustomStoryItem(
        // Modified: Used alias and fixed constructor call
        backgroundImage: ImageConstant.imgImage8,
        profileImage: ImageConstant.imgFrame48x48,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
      story_list.CustomStoryItem(
        // Modified: Used alias and fixed constructor call
        backgroundImage: ImageConstant.imgImg,
        profileImage: ImageConstant.imgEllipse842x42,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
      story_list.CustomStoryItem(
        // Modified: Used alias and fixed constructor call
        backgroundImage: ImageConstant.imgImage81,
        profileImage: ImageConstant.imgEllipse81,
        timestamp: '2 mins ago',
        navigateTo: '1398:6774',
      ),
    ];

    // Initialize timeline detail
    TimelineDetailModel timelineDetail = TimelineDetailModel(
      leftDate: 'Dec 4',
      leftTime: '3:18pm',
      centerLocation: 'Tillsonburg, ON',
      centerDistance: '21km',
      rightDate: 'Dec 4',
      rightTime: '3:18am',
    );

    // Initialize participant images
    List<String> participantImages = [
      ImageConstant.imgFrame2,
      ImageConstant.imgFrame1,
      ImageConstant.imgEllipse81,
    ];

    state = state.copyWith(
      eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
        eventTitle: 'Nixon Wedding 2025',
        eventDate: 'Dec 4, 2025',
        isPrivate: true,
        participantImages: participantImages,
        storyItems: storyItems,
        timelineDetail: timelineDetail,
        storiesCount: 6,
      ),
      isLoading: false,
    );
  }

  void updateStoriesCount(int count) {
    state = state.copyWith(
      eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
        storiesCount: count,
      ),
    );
  }

  void refreshData() {
    state = state.copyWith(isLoading: true);
    initialize();
  }
}
