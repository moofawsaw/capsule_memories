import '../models/event_stories_view_model.dart';
import '../models/contributor_item_model.dart';
import '../models/story_item_model.dart';
import '../../../core/app_export.dart';
import '../../../services/feed_service.dart';

part 'event_stories_view_state.dart';

final eventStoriesViewNotifier = StateNotifierProvider.autoDispose<
    EventStoriesViewNotifier, EventStoriesViewState>(
  (ref) => EventStoriesViewNotifier(
    EventStoriesViewState(
      eventStoriesViewModel: EventStoriesViewModel(
        eventTitle: '',
        eventDate: '',
        eventLocation: '',
        viewCount: '0',
        contributorsList: [],
        storiesList: [],
      ),
    ),
  ),
);

class EventStoriesViewNotifier extends StateNotifier<EventStoriesViewState> {
  final FeedService _feedService = FeedService();

  EventStoriesViewNotifier(EventStoriesViewState state) : super(state);

  /// Initialize with memory ID from navigation arguments
  Future<void> initialize(String? memoryId) async {
    if (memoryId == null || memoryId.isEmpty) {
      print('❌ ERROR: No memory ID provided to event stories view');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Memory not found',
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    await _loadMemoryData(memoryId);
  }

  /// Load memory data from database
  Future<void> _loadMemoryData(String memoryId) async {
    try {
      final memoryData = await _feedService.fetchMemoryDetails(memoryId);

      if (memoryData == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load memory data',
        );
        return;
      }

      final contributorsList = (memoryData['contributorsList'] as List)
          .map((c) => ContributorItemModel(
                contributorId: c['contributorId'] ?? '',
                contributorName: c['contributorName'] ?? 'Unknown User',
                contributorImage: c['contributorImage'] ?? '',
              ))
          .toList();

      final storiesList = (memoryData['storiesList'] as List)
          .map((s) => StoryItemModel(
                storyId: s['storyId'] ?? '',
                storyImage: s['storyImage'] ?? '',
                timeAgo: s['timeAgo'] ?? '',
              ))
          .toList();

      state = state.copyWith(
        eventStoriesViewModel: EventStoriesViewModel(
          eventTitle: memoryData['eventTitle'] ?? '',
          eventDate: memoryData['eventDate'] ?? '',
          eventLocation: memoryData['eventLocation'] ?? '',
          viewCount: memoryData['viewCount'] ?? '0',
          contributorsList: contributorsList,
          storiesList: storiesList,
        ),
        isLoading: false,
      );
    } catch (e) {
      print('❌ ERROR loading memory data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading memory: ${e.toString()}',
      );
    }
  }
}