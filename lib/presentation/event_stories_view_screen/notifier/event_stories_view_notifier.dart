import '../models/event_stories_view_model.dart';
import '../../../services/feed_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        contributorsList: const [],
        storiesList: const [],
      ),
    ),
  ),
);

class EventStoriesViewNotifier extends StateNotifier<EventStoriesViewState> {
  final FeedService _feedService = FeedService();

  EventStoriesViewNotifier(EventStoriesViewState initialState) : super(initialState);

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

      final contributorsList = (memoryData['contributorsList'] as List?)
          ?.map((c) => {
                'contributorId': c['contributorId'] ?? '',
                'contributorName': c['contributorName'] ?? 'Unknown User',
                'contributorImage': c['contributorImage'] ?? '',
              })
          .toList() ?? [];

      final storiesList = (memoryData['storiesList'] as List)
          .map((s) => {
                'storyId': s['storyId'] ?? '',
                'storyImage': s['storyImage'] ?? '',
                'timeAgo': s['timeAgo'] ?? '',
              })
          .toList();

      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      print('❌ ERROR loading memory data: \$e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading memory: \${e.toString()}',
      );
    }
  }
}