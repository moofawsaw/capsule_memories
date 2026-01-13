import '../../../services/feed_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventStoriesViewModel {
  final bool isLoading;
  final String? errorMessage;

  EventStoriesViewModel({
    required this.isLoading,
    this.errorMessage,
  });

  EventStoriesViewModel copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return EventStoriesViewModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final eventStoriesViewNotifier = StateNotifierProvider.autoDispose<
    EventStoriesViewNotifier, EventStoriesViewModel>(
  (ref) => EventStoriesViewNotifier(
    EventStoriesViewModel(
      isLoading: false,
      errorMessage: null,
    ),
  ),
);

class EventStoriesViewNotifier extends StateNotifier<EventStoriesViewModel> {
  final FeedService _feedService = FeedService();

  EventStoriesViewNotifier(EventStoriesViewModel initialState) : super(initialState);

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