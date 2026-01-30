// lib/presentation/memory_timeline_playback_screen/notifier/memory_timeline_playback_notifier.dart
import 'dart:async';

import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../services/memory_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/chromecast_service.dart';
import '../models/memory_timeline_playback_model.dart';
import './memory_timeline_playback_state.dart';

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
  final ChromecastService _chromecastService = ChromecastService();

  VideoPlayerController? currentVideoController;

  // Keep listener reference so we can remove it safely
  VoidCallback? _currentControllerListener;

  // Image auto-advance
  Timer? _imageAutoAdvanceTimer;
  static const Duration _imageDisplayDuration = Duration(seconds: 4);

  // Prevent async races
  int _loadToken = 0;

  // Prefetch next TWO videos
  VideoPlayerController? _nextVideoController1;
  String? _nextVideoStoryId1;

  VideoPlayerController? _nextVideoController2;
  String? _nextVideoStoryId2;

  // ✅ Progress ticker (drives countdown + progress bar)
  Timer? _progressTimer;
  static const Duration _progressTick = Duration(milliseconds: 50);

  // Chromecast status polling (keeps overlay in sync with receiver)
  Timer? _castStatusTimer;
  static const Duration _castPoll = Duration(milliseconds: 500);

  // For images, track elapsed across pause/resume
  int _imageElapsedMs = 0;
  DateTime? _imageStartAt;

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
    storyProgress: 0.0,
    storyRemaining: Duration.zero,
    storyTotal: Duration.zero,
  )) {
    _initializeChromecast();
  }

  Future<void> _initializeChromecast() async {
    _chromecastService.onConnectionStateChanged = (isConnected) {
      state = state.copyWith(isChromecastConnected: isConnected);

      if (isConnected) {
        // When casting starts, stop local playback and cast the full playlist.
        unawaited(_disposeVideoControllerSafely());
        _stopImageAutoAdvance();
        _stopProgressTicker();
        // Receiver autoplay is expected; reflect play state.
        state = state.copyWith(isPlaying: true);
        unawaited(_castPlaylistQueue(startIndex: state.currentStoryIndex ?? 0));
        _startCastStatusPolling();
      } else {
        _stopCastStatusPolling();
      }
    };

    _chromecastService.onError = (error) {
      state = state.copyWith(errorMessage: 'Chromecast: $error');
    };

    await _chromecastService.initialize();
  }

  void _stopCastStatusPolling() {
    _castStatusTimer?.cancel();
    _castStatusTimer = null;
  }

  void _startCastStatusPolling() {
    _stopCastStatusPolling();
    _castStatusTimer = Timer.periodic(_castPoll, (_) async {
      if (!_chromecastService.isConnected) return;
      final status = await _chromecastService.getPlaybackStatus();
      if (status == null) return;

      final bool isConnected = status['isConnected'] == true;
      if (!isConnected) return;

      final bool isPlaying = status['isPlaying'] == true;
      final int positionMs =
          (status['positionMs'] is num) ? (status['positionMs'] as num).toInt() : 0;
      final int durationMs =
          (status['durationMs'] is num) ? (status['durationMs'] as num).toInt() : 0;

      final int? idx = (status['index'] is num) ? (status['index'] as num).toInt() : null;

      PlaybackStoryModel? currentStory = state.currentStory;
      int? nextIndex = state.currentStoryIndex;

      final stories = state.stories;
      if (idx != null &&
          stories != null &&
          idx >= 0 &&
          idx < stories.length &&
          (state.currentStoryIndex ?? 0) != idx) {
        nextIndex = idx;
        currentStory = stories[idx];
      }

      final total = Duration(milliseconds: durationMs.clamp(0, 24 * 60 * 60 * 1000));
      final remaining = Duration(
        milliseconds: (durationMs - positionMs).clamp(0, durationMs),
      );
      final progress =
          durationMs <= 0 ? 0.0 : (positionMs / durationMs).clamp(0.0, 1.0);

      state = state.copyWith(
        isPlaying: isPlaying,
        currentStoryIndex: nextIndex,
        currentStory: currentStory,
        storyTotal: total,
        storyRemaining: remaining,
        storyProgress: progress,
      );
    });
  }

  // ------------------------
  // Progress helpers
  // ------------------------
  void _stopProgressTicker() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _pauseImageProgressTicker() {
    final start = _imageStartAt;
    if (start != null) {
      _imageElapsedMs += DateTime.now().difference(start).inMilliseconds;
      _imageStartAt = null;
    }
    _stopProgressTicker();
  }

  void _resetStoryProgressForNewStory({required bool isVideo}) {
    _stopProgressTicker();
    _imageElapsedMs = 0;
    _imageStartAt = null;

    if (isVideo) {
      state = state.copyWith(
        storyProgress: 0.0,
        storyRemaining: Duration.zero,
        storyTotal: Duration.zero,
      );
    } else {
      state = state.copyWith(
        storyProgress: 0.0,
        storyRemaining: _imageDisplayDuration,
        storyTotal: _imageDisplayDuration,
      );
    }
  }

  void _startImageProgressTickerIfPlaying() {
    _stopProgressTicker();
    if (!(state.isPlaying ?? false)) return;

    _imageStartAt ??= DateTime.now();

    _progressTimer = Timer.periodic(_progressTick, (_) {
      if (!(state.isPlaying ?? false)) return;

      final start = _imageStartAt;
      if (start == null) return;

      final now = DateTime.now();
      final elapsedMs = _imageElapsedMs + now.difference(start).inMilliseconds;
      final totalMs = _imageDisplayDuration.inMilliseconds;

      final clampedElapsed = elapsedMs.clamp(0, totalMs);
      final remainingMs = (totalMs - clampedElapsed).clamp(0, totalMs);

      final progress = totalMs == 0 ? 0.0 : (clampedElapsed / totalMs);

      state = state.copyWith(
        storyProgress: progress.clamp(0.0, 1.0),
        storyRemaining: Duration(milliseconds: remainingMs),
        storyTotal: _imageDisplayDuration,
      );
    });
  }

  void _startVideoProgressTickerIfPlaying(VideoPlayerController controller) {
    _stopProgressTicker();
    if (!(state.isPlaying ?? false)) return;

    _progressTimer = Timer.periodic(_progressTick, (_) {
      final v = controller.value;
      if (!v.isInitialized) return;

      final dur = v.duration;
      final pos = v.position;

      final totalMs = dur.inMilliseconds;
      final posMs = pos.inMilliseconds.clamp(0, totalMs);

      final progress = totalMs == 0 ? 0.0 : (posMs / totalMs);
      final remaining = dur - Duration(milliseconds: posMs);

      state = state.copyWith(
        storyProgress: progress.clamp(0.0, 1.0),
        storyRemaining: remaining.isNegative ? Duration.zero : remaining,
        storyTotal: dur,
      );
    });
  }

  // ------------------------
  // Data loading
  // ------------------------
  Future<void> loadMemoryPlayback(String memoryId) async {
    try {
      state = state.copyWith(isLoading: true);

      final memoryResponse = await SupabaseService.instance.clientOrThrow
          .from('memories')
          .select('id, title')
          .eq('id', memoryId)
          .single();

      final storiesResponse = await SupabaseService.instance.clientOrThrow
          .from('stories')
          .select(
          'id, contributor_id, created_at, media_type, image_url, video_url, thumbnail_url, capture_timestamp, user_profiles!contributor_id(display_name, avatar_url)')
          .eq('memory_id', memoryId)
          .eq('is_disabled', false)
          .order('capture_timestamp', ascending: true);

      final stories = (storiesResponse as List).map((storyData) {
        final contributor =
            (storyData['user_profiles_public'] as Map<String, dynamic>?) ??
                (storyData['user_profiles'] as Map<String, dynamic>?);


        final rawVideoUrl = storyData['video_url'] as String?;
        final rawImageUrl = storyData['image_url'] as String?;
        final rawThumbnailUrl = storyData['thumbnail_url'] as String?;

        final resolvedVideoUrl = StoryService.resolveStoryMediaUrl(rawVideoUrl);
        final resolvedImageUrl = StoryService.resolveStoryMediaUrl(rawImageUrl);
        final resolvedThumbnailUrl =
        StoryService.resolveStoryMediaUrl(rawThumbnailUrl);

        final rawAvatar = contributor?['avatar_url'] as String?;
        final resolvedAvatar = _resolveAvatarUrl(rawAvatar);

        debugPrint('👤 AVATAR DEBUG');
        debugPrint('   raw avatar_url: $rawAvatar');
        debugPrint('   resolved avatar_url: $resolvedAvatar');

        return PlaybackStoryModel(
          storyId: storyData['id'],
          contributorId: storyData['contributor_id'],
          contributorName: contributor?['display_name'] ?? 'Unknown',
          contributorAvatar: resolvedAvatar,
          mediaType: storyData['media_type'],
          imageUrl: resolvedImageUrl,
          videoUrl: resolvedVideoUrl,
          thumbnailUrl: resolvedThumbnailUrl ?? resolvedImageUrl,
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

      state = state.copyWith(
        isLoading: false,
        memoryTitle: memoryResponse['title'],
        stories: stories,
        totalStories: stories.length,
        currentStoryIndex: 0,
        currentStory: stories.isNotEmpty ? stories[0] : null,
        errorMessage: null,
      );

      if (stories.isNotEmpty) {
        await _loadStory(0);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load playback: ${e.toString()}',
      );
    }
  }

  // ------------------------
  // Media helpers
  // ------------------------
  bool _isVideoStory(PlaybackStoryModel story) {
    return story.mediaType == 'video' &&
        story.videoUrl != null &&
        story.videoUrl!.isNotEmpty;
  }

  bool _isValidHttpUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  void _stopImageAutoAdvance() {
    _imageAutoAdvanceTimer?.cancel();
    _imageAutoAdvanceTimer = null;
  }

  void _startImageAutoAdvanceIfNeeded(PlaybackStoryModel story) {
    _stopImageAutoAdvance();
    if (_isVideoStory(story)) return;
    if (!(state.isPlaying ?? false)) return;

    _imageAutoAdvanceTimer = Timer(_imageDisplayDuration, () async {
      if (!(state.isPlaying ?? false)) return;
      await skipForward();
    });
  }

  // ✅ CRITICAL FIX: dispose AFTER next frame so UI detaches VideoPlayer first
  Future<void> _disposeVideoControllerSafely() async {
    final old = currentVideoController;
    if (old == null) return;

    final listener = _currentControllerListener;
    if (listener != null) {
      try {
        old.removeListener(listener);
      } catch (_) {}
    }
    _currentControllerListener = null;

    try {
      await old.pause();
    } catch (_) {}

    // Drop reference first
    currentVideoController = null;

    // Stop progress ticker (old controller)
    _stopProgressTicker();

    // Force rebuild to detach VideoPlayer from old controller
    state = state.copyWith(currentStory: state.currentStory);

    // Dispose after next frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await old.dispose();
      } catch (_) {}
    });
  }

  Future<void> _disposePrefetchController1() async {
    final c = _nextVideoController1;
    if (c != null) {
      try {
        await c.pause();
      } catch (_) {}
      try {
        await c.dispose();
      } catch (_) {}
    }
    _nextVideoController1 = null;
    _nextVideoStoryId1 = null;
  }

  Future<void> _disposePrefetchController2() async {
    final c = _nextVideoController2;
    if (c != null) {
      try {
        await c.pause();
      } catch (_) {}
      try {
        await c.dispose();
      } catch (_) {}
    }
    _nextVideoController2 = null;
    _nextVideoStoryId2 = null;
  }

  Future<VideoPlayerController?> _buildInitializedController(
      String url, double speed, int token) async {
    if (!_isValidHttpUrl(url)) return null;

    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();

      if (token != _loadToken) {
        try {
          await c.dispose();
        } catch (_) {}
        return null;
      }

      try {
        await c.setPlaybackSpeed(speed);
      } catch (_) {}

      return c;
    } catch (_) {
      return null;
    }
  }

  // Prefetch next two videos (call after each story loads)
  Future<void> prefetchNextTwoVideos() async {
    final stories = state.stories;
    if (stories == null || stories.isEmpty) return;

    final currentIndex = state.currentStoryIndex ?? 0;
    final token = _loadToken;
    final speed = state.playbackSpeed ?? 1.0;

    // +1
    final i1 = currentIndex + 1;
    if (i1 < stories.length && _isVideoStory(stories[i1])) {
      final story = stories[i1];
      final id = story.storyId;
      final url = story.videoUrl;

      if (id != null &&
          url != null &&
          _nextVideoStoryId1 == id &&
          _nextVideoController1 != null &&
          _nextVideoController1!.value.isInitialized) {
        // already prefetched
      } else {
        await _disposePrefetchController1();
        final c = await _buildInitializedController(url!, speed, token);
        if (c != null && token == _loadToken) {
          _nextVideoController1 = c;
          _nextVideoStoryId1 = id;
        } else {
          await _disposePrefetchController1();
        }
      }
    } else {
      await _disposePrefetchController1();
    }

    // +2
    final i2 = currentIndex + 2;
    if (i2 < stories.length && _isVideoStory(stories[i2])) {
      final story = stories[i2];
      final id = story.storyId;
      final url = story.videoUrl;

      if (id != null &&
          url != null &&
          _nextVideoStoryId2 == id &&
          _nextVideoController2 != null &&
          _nextVideoController2!.value.isInitialized) {
        // already prefetched
      } else {
        await _disposePrefetchController2();
        final c = await _buildInitializedController(url!, speed, token);
        if (c != null && token == _loadToken) {
          _nextVideoController2 = c;
          _nextVideoStoryId2 = id;
        } else {
          await _disposePrefetchController2();
        }
      }
    } else {
      await _disposePrefetchController2();
    }
  }

  VideoPlayerController? _takePrefetchedIfMatches(PlaybackStoryModel story) {
    if (!_isVideoStory(story)) return null;
    final id = story.storyId;
    if (id == null) return null;

    if (_nextVideoStoryId1 == id &&
        _nextVideoController1 != null &&
        _nextVideoController1!.value.isInitialized) {
      final c = _nextVideoController1!;
      _nextVideoController1 = null;
      _nextVideoStoryId1 = null;
      return c;
    }

    if (_nextVideoStoryId2 == id &&
        _nextVideoController2 != null &&
        _nextVideoController2!.value.isInitialized) {
      final c = _nextVideoController2!;
      _nextVideoController2 = null;
      _nextVideoStoryId2 = null;
      return c;
    }

    return null;
  }

  // ------------------------
  // Story loading / playback
  // ------------------------
  Future<void> _loadStory(int index) async {
    final stories = state.stories;
    if (stories == null || index < 0 || index >= stories.length) return;

    _loadToken++;
    final token = _loadToken;

    final story = stories[index];

    _stopImageAutoAdvance();
    _stopProgressTicker();

    state = state.copyWith(
      currentStoryIndex: index,
      currentStory: story,
      errorMessage: null,
    );

    _resetStoryProgressForNewStory(isVideo: _isVideoStory(story));

    // Dispose current controller safely
    await _disposeVideoControllerSafely();

    // Casting mode: don't play locally (receiver handles playback).
    if (_chromecastService.isConnected) {
      return;
    }

    // IMAGE
    if (!_isVideoStory(story)) {
      _startImageAutoAdvanceIfNeeded(story);
      _startImageProgressTickerIfPlaying();
      unawaited(prefetchNextTwoVideos());
      return;
    }

    // VIDEO
    final url = story.videoUrl!;
    if (!_isValidHttpUrl(url)) {
      state = state.copyWith(errorMessage: 'Invalid video URL format');
      unawaited(prefetchNextTwoVideos());
      return;
    }

    try {
      final speed = state.playbackSpeed ?? 1.0;

      final prefetched = _takePrefetchedIfMatches(story);
      final controller =
          prefetched ?? VideoPlayerController.networkUrl(Uri.parse(url));

      currentVideoController = controller;

      if (prefetched == null) {
        await controller.initialize();
      }

      if (token != _loadToken) {
        try {
          await controller.dispose();
        } catch (_) {}
        return;
      }

      try {
        await controller.setPlaybackSpeed(speed);
      } catch (_) {}

      if (state.isPlaying ?? false) {
        await controller.play();
      } else {
        await controller.pause();
      }

      // Start countdown/progress ticker for video
      _startVideoProgressTickerIfPlaying(controller);

      // Completion listener
      _currentControllerListener = () {
        if (token != _loadToken) return;
        final v = controller.value;
        if (!v.isInitialized) return;

        final ended = v.duration.inMilliseconds > 0 &&
            v.position >= v.duration &&
            !v.isPlaying;

        if (ended) {
          skipForward();
        }
      };
      controller.addListener(_currentControllerListener!);

      // Force rebuild after controller swap
      state = state.copyWith(currentStory: story);

      unawaited(prefetchNextTwoVideos());
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load video: $e');
      unawaited(prefetchNextTwoVideos());
    }
  }

  void togglePlayPause() {
    final isPlaying = !(state.isPlaying ?? false);

    if (_chromecastService.isConnected) {
      // In casting mode, only control the receiver (no local playback/progress).
      if (isPlaying) {
        _chromecastService.play();
      } else {
        _chromecastService.pause();
      }
      state = state.copyWith(isPlaying: isPlaying);
      return;
    }

    final c = currentVideoController;
    if (c != null) {
      if (isPlaying) {
        c.play();
      } else {
        c.pause();
      }
    }

    state = state.copyWith(isPlaying: isPlaying);

    final story = state.currentStory;
    if (story == null) return;

    if (_isVideoStory(story)) {
      final vc = currentVideoController;
      if (vc != null) {
        if (isPlaying) {
          _startVideoProgressTickerIfPlaying(vc);
        } else {
          _stopProgressTicker();
        }
      }
    } else {
      if (isPlaying) {
        _startImageAutoAdvanceIfNeeded(story);
        _startImageProgressTickerIfPlaying();
      } else {
        _stopImageAutoAdvance();
        _pauseImageProgressTicker();
      }
    }
  }

  Future<void> skipForward() async {
    final nextIndex = (state.currentStoryIndex ?? 0) + 1;

    if (nextIndex < (state.totalStories ?? 0)) {
      if (_chromecastService.isConnected) {
        await _chromecastService.queueNext();
      }
      await _loadStory(nextIndex);
    } else {
      _stopImageAutoAdvance();
      _stopProgressTicker();
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> skipBackward() async {
    final prevIndex = (state.currentStoryIndex ?? 0) - 1;
    if (prevIndex >= 0) {
      if (_chromecastService.isConnected) {
        await _chromecastService.queuePrev();
      }
      await _loadStory(prevIndex);
    }
  }

  Future<void> jumpToStory(int index) async {
    if (index >= 0 && index < (state.totalStories ?? 0)) {
      if (_chromecastService.isConnected) {
        // Queue item IDs are receiver-assigned; simplest way is to reload the queue
        // starting from the desired index.
        await _castPlaylistQueue(startIndex: index);
      }
      await _loadStory(index);
    }
  }

  void toggleTimelineScrubber() {
    state = state.copyWith(
      isTimelineScrubberExpanded: !(state.isTimelineScrubberExpanded ?? false),
    );
  }

  Future<void> toggleChromecast() async {
    if (_chromecastService.isConnected) {
      await _chromecastService.disconnect();
      state = state.copyWith(isChromecastConnected: false);
      _stopCastStatusPolling();
    } else {
      await _chromecastService.showCastDialog();
    }
  }

  String _guessContentType({required PlaybackStoryModel story, required String url}) {
    final lower = url.toLowerCase();
    if (story.mediaType == 'video') {
      if (lower.endsWith('.mp4')) return 'video/mp4';
      if (lower.endsWith('.m3u8')) return 'application/x-mpegURL';
      if (lower.endsWith('.mov')) return 'video/quicktime';
      return 'video/mp4';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _castPlaylistQueue({required int startIndex}) async {
    final stories = state.stories;
    if (stories == null || stories.isEmpty) return;

    final memTitle = state.memoryTitle ?? 'Memory';
    final total = stories.length;

    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < stories.length; i++) {
      final s = stories[i];
      final mediaUrl = (s.mediaType == 'video') ? s.videoUrl : s.imageUrl;
      if (mediaUrl == null || mediaUrl.trim().isEmpty) continue;

      final url = mediaUrl.trim();
      final contentType = _guessContentType(story: s, url: url);
      final subtitle = '${s.contributorName ?? 'Unknown'} • ${(s.timestamp ?? '').trim()}'.trim();
      final thumb = (s.thumbnailUrl ?? s.imageUrl ?? '').trim();

      items.add({
        'mediaUrl': url,
        'mediaType': (s.mediaType ?? 'image'),
        'contentType': contentType,
        'title': memTitle,
        'subtitle': subtitle,
        'thumbnailUrl': thumb,
        // Forward-looking: used by a future custom receiver UI.
        'customData': <String, dynamic>{
          'index': i,
          'total': total,
          'contributorName': s.contributorName,
          'timestamp': s.timestamp,
          'imageDurationSeconds': _imageDisplayDuration.inSeconds,
          'storyId': s.storyId,
        },
      });
    }

    if (items.isEmpty) return;

    await _chromecastService.castQueue(
      items: items,
      startIndex: startIndex.clamp(0, items.length - 1),
    );
  }

  void toggleFavorite(int index) {
    final stories = state.stories;
    if (stories == null || index < 0 || index >= stories.length) return;

    final updated = List<PlaybackStoryModel>.from(stories);
    updated[index] = updated[index].copyWith(
      isFavorite: !(updated[index].isFavorite ?? false),
    );

    state = state.copyWith(stories: updated);
  }

  void applyFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void replayAll() {
    state = state.copyWith(currentStoryIndex: 0, isPlaying: true);
    if (state.stories != null && state.stories!.isNotEmpty) {
      _loadStory(0);
    }
  }

  String? _resolveAvatarUrl(String? rawAvatar) {
    if (rawAvatar == null) return null;
    final trimmed = rawAvatar.trim();
    if (trimmed.isEmpty) return null;

    // Already a full URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Treat it as a Supabase Storage path
    // IMPORTANT: set this to your actual avatar bucket name
    const avatarBucket = 'avatars';

    try {
      // public URL (works only if bucket is public)
      final url = SupabaseService.instance.clientOrThrow.storage
          .from(avatarBucket)
          .getPublicUrl(trimmed);

      return url;
    } catch (_) {
      return null;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final storyDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (storyDate == today) {
      return 'Today at ${DateFormat.jm().format(timestamp)}';
    } else if (storyDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${DateFormat.jm().format(timestamp)}';
    } else {
      return DateFormat('MMM d at h:mm a').format(timestamp);
    }
  }

  @override
  void dispose() {
    _stopCastStatusPolling();
    _stopImageAutoAdvance();
    _stopProgressTicker();
    _pauseImageProgressTicker();

    unawaited(_disposeVideoControllerSafely());
    unawaited(_disposePrefetchController1());
    unawaited(_disposePrefetchController2());

    _chromecastService.dispose();
    super.dispose();
  }
}
