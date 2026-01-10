import '../../../core/app_export.dart';
import '../models/memory_timeline_playback_model.dart';

@immutable
class MemoryTimelinePlaybackState {
  final bool? isLoading;
  final String? errorMessage;
  final MemoryTimelinePlaybackModel? playbackModel;
  final String? memoryTitle;
  final List<PlaybackStoryModel>? stories;
  final int? currentStoryIndex;
  final int? totalStories;
  final bool? isPlaying;
  final bool? isTimelineScrubberExpanded;
  final bool? isChromecastConnected;
  final PlaybackStoryModel? currentStory;
  final double? playbackSpeed;
  final String? activeFilter;

  const MemoryTimelinePlaybackState({
    this.isLoading,
    this.errorMessage,
    this.playbackModel,
    this.memoryTitle,
    this.stories,
    this.currentStoryIndex,
    this.totalStories,
    this.isPlaying,
    this.isTimelineScrubberExpanded,
    this.isChromecastConnected,
    this.currentStory,
    this.playbackSpeed,
    this.activeFilter,
  });

  MemoryTimelinePlaybackState copyWith({
    bool? isLoading,
    String? errorMessage,
    MemoryTimelinePlaybackModel? playbackModel,
    String? memoryTitle,
    List<PlaybackStoryModel>? stories,
    int? currentStoryIndex,
    int? totalStories,
    bool? isPlaying,
    bool? isTimelineScrubberExpanded,
    bool? isChromecastConnected,
    PlaybackStoryModel? currentStory,
    double? playbackSpeed,
    String? activeFilter,
  }) {
    return MemoryTimelinePlaybackState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      playbackModel: playbackModel ?? this.playbackModel,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      stories: stories ?? this.stories,
      currentStoryIndex: currentStoryIndex ?? this.currentStoryIndex,
      totalStories: totalStories ?? this.totalStories,
      isPlaying: isPlaying ?? this.isPlaying,
      isTimelineScrubberExpanded:
          isTimelineScrubberExpanded ?? this.isTimelineScrubberExpanded,
      isChromecastConnected:
          isChromecastConnected ?? this.isChromecastConnected,
      currentStory: currentStory ?? this.currentStory,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}
