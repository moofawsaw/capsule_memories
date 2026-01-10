import '../../../core/app_export.dart';
import '../../../services/memory_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../models/memory_timeline_playback_model.dart';
import './memory_timeline_playback_state.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

final memoryServiceProvider = Provider<MemoryService>((ref) => MemoryService());
final storyServiceProvider = Provider<StoryService>((ref) => StoryService());

final memoryTimelinePlaybackNotifier = StateNotifierProvider<
    MemoryTimelinePlaybackNotifier, MemoryTimelinePlaybackState>(
  (ref) => MemoryTimelinePlaybackNotifier(
    ref.read(memoryServiceProvider),
    ref.read(storyServiceProvider),
  ),
);

class MemoryTimelinePlaybackNotifier
    extends StateNotifier<MemoryTimelinePlaybackState> {
  final MemoryService _memoryService;
  final StoryService _storyService;
  VideoPlayerController? currentVideoController;

  MemoryTimelinePlaybackNotifier(
    this._memoryService,
    this._storyService,
  ) : super(const MemoryTimelinePlaybackState(
          isLoading: false,
          currentStoryIndex: 0,
          totalStories: 0,
          isPlaying: false,
          isTimelineScrubberExpanded: false,
          isChromecastConnected: false,
          playbackSpeed: 1.0,
        ));

  /// Load memory playback data from database
  Future<void> loadMemoryPlayback(String memoryId) async {
    try {
      state = state.copyWith(isLoading: true);

      // Fetch memory details
      final memoryResponse = await SupabaseService.instance.clientOrThrow
          .from('memories')
          .select('id, title')
          .eq('id', memoryId)
          .single();

      // Fetch all stories for this memory, ordered chronologically
      final storiesResponse = await SupabaseService.instance.clientOrThrow
          .from('stories')
          .select(
              'id, contributor_id, created_at, media_type, image_url, video_url, thumbnail_url, capture_timestamp, user_profiles!contributor_id(display_name, avatar_url)')
          .eq('memory_id', memoryId)
          .eq('is_disabled', false)
          .order('capture_timestamp', ascending: true);

      // Transform stories into playback models
      final stories = (storiesResponse as List).map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;

        return PlaybackStoryModel(
          storyId: storyData['id'],
          contributorId: storyData['contributor_id'],
          contributorName: contributor?['display_name'] ?? 'Unknown',
          contributorAvatar: contributor?['avatar_url'],
          mediaType: storyData['media_type'],
          imageUrl: storyData['image_url'],
          videoUrl: storyData['video_url'],
          thumbnailUrl: storyData['thumbnail_url'] ?? storyData['image_url'],
          captureTimestamp: storyData['capture_timestamp'] != null
              ? DateTime.parse(storyData['capture_timestamp'])
              : null,
          timestamp: storyData['capture_timestamp'] != null
              ? _formatTimestamp(DateTime.parse(storyData['capture_timestamp']))
              : null,
          isFavorite: false,
          reactionCount: 0,
        );
      }).toList();

      // Update state with playback data
      state = state.copyWith(
        isLoading: false,
        memoryTitle: memoryResponse['title'],
        stories: stories,
        totalStories: stories.length,
        currentStoryIndex: 0,
        currentStory: stories.isNotEmpty ? stories[0] : null,
      );

      // Initialize first story
      if (stories.isNotEmpty) {
        await _loadStory(0);
      }
    } catch (e) {
      debugPrint('Error loading memory playback: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load playback: ${e.toString()}',
      );
    }
  }

  /// Load specific story for playback
  Future<void> _loadStory(int index) async {
    if (state.stories == null || index >= state.stories!.length) return;

    final story = state.stories![index];

    // Dispose previous video controller if exists
    await currentVideoController?.dispose();
    currentVideoController = null;

    // Initialize video player if story is video
    if (story.mediaType == 'video' && story.videoUrl != null) {
      currentVideoController = VideoPlayerController.network(story.videoUrl!);

      await currentVideoController!.initialize();

      // Auto-play video
      if (state.isPlaying ?? false) {
        await currentVideoController!.play();
      }

      // Listen for video completion to auto-advance
      currentVideoController!.addListener(() {
        if (currentVideoController!.value.position ==
            currentVideoController!.value.duration) {
          skipForward();
        }
      });
    }

    state = state.copyWith(
      currentStoryIndex: index,
      currentStory: story,
    );
  }

  /// Toggle play/pause
  void togglePlayPause() {
    final isPlaying = !(state.isPlaying ?? false);

    if (currentVideoController != null) {
      if (isPlaying) {
        currentVideoController!.play();
      } else {
        currentVideoController!.pause();
      }
    }

    state = state.copyWith(isPlaying: isPlaying);
  }

  /// Skip to next story
  void skipForward() {
    final nextIndex = (state.currentStoryIndex ?? 0) + 1;

    if (nextIndex < (state.totalStories ?? 0)) {
      _loadStory(nextIndex);
    }
  }

  /// Skip to previous story
  void skipBackward() {
    final prevIndex = (state.currentStoryIndex ?? 0) - 1;

    if (prevIndex >= 0) {
      _loadStory(prevIndex);
    }
  }

  /// Jump to specific story
  void jumpToStory(int index) {
    if (index >= 0 && index < (state.totalStories ?? 0)) {
      _loadStory(index);
    }
  }

  /// Toggle timeline scrubber visibility
  void toggleTimelineScrubber() {
    state = state.copyWith(
      isTimelineScrubberExpanded: !(state.isTimelineScrubberExpanded ?? false),
    );
  }

  /// Toggle Chromecast connection
  void toggleChromecast() {
    final isConnected = !(state.isChromecastConnected ?? false);

    // In production, implement actual Chromecast SDK integration here
    // For now, just toggle the state

    state = state.copyWith(isChromecastConnected: isConnected);

    debugPrint('Chromecast ${isConnected ? 'connected' : 'disconnected'}');
  }

  /// Toggle favorite status
  void toggleFavorite(int index) {
    if (state.stories == null || index >= state.stories!.length) return;

    final updatedStories = List<PlaybackStoryModel>.from(state.stories!);
    updatedStories[index] = updatedStories[index].copyWith(
      isFavorite: !(updatedStories[index].isFavorite ?? false),
    );

    state = state.copyWith(stories: updatedStories);
  }

  /// Apply filter to stories
  void applyFilter(String filter) {
    // Implement filtering logic based on filter type
    // For now, just store the active filter
    state = state.copyWith(activeFilter: filter);
    debugPrint('Applied filter: $filter');
  }

  /// Replay all stories from the beginning
  void replayAll() {
    state = state.copyWith(
      currentStoryIndex: 0,
      isPlaying: true,
    );

    // Load the first story
    if (state.stories != null && state.stories!.isNotEmpty) {
      _loadStory(0);
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final storyDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (storyDate == today) {
      return 'Today at ${DateFormat.jm().format(timestamp)}';
    } else if (storyDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday at ${DateFormat.jm().format(timestamp)}';
    } else {
      return DateFormat('MMM d at h:mm a').format(timestamp);
    }
  }

  /// Export memory compilation
  Future<void> exportMemoryCompilation() async {
    // Implement export functionality
    debugPrint('Exporting memory compilation...');
  }

  @override
  void dispose() {
    currentVideoController?.dispose();
    super.dispose();
  }
}