// lib/presentation/event_stories_view_screen/event_stories_view_screen.dart
// FULL COPY/PASTE FILE
//
// Fixes:
// 1) Tap zones no longer steal taps from the delete / more-options buttons (and other top/bottom UI).
// 2) Back/previous “glitching” reduced by preventing tap zone overlap with interactive UI + tighter nav/tap locks.
// 3) Keeps fast-forward long-press on RIGHT zone.
// 4) Keeps “avoid setState while deactivated” + transition queueing.

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';

import '../../services/reaction_preloader.dart';

import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../services/avatar_helper_service.dart';
import '../../services/feed_service.dart';
import '../../services/supabase_service.dart';
import '../../services/user_profile_service.dart';
import '../../utils/storage_utils.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/story_reactions.dart';
import '../qr_timeline_share_screen/qr_timeline_share_screen.dart';
import '../report_story_screen/report_story_screen.dart';

/// Enum for different haptic feedback types
enum HapticFeedbackType {
  light, // Subtle feedback for progress transitions
  medium, // Navigation feedback for swipes
  selection // Toggle feedback for button presses
}

class EventStoriesViewScreen extends ConsumerStatefulWidget {
  const EventStoriesViewScreen({Key? key}) : super(key: key);

  @override
  EventStoriesViewScreenState createState() => EventStoriesViewScreenState();
}

class EventStoriesViewScreenState extends ConsumerState<EventStoriesViewScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String? _initialStoryId;
  String? _feedType;
  List<String> _storyIds = [];
  int _currentIndex = 0;
  // ignore: unused_field
  int _startingIndex = 0;

  // DUAL MEDIA SLOTS for seamless transitions
  Map<String, dynamic>? _currentStoryData;
  Map<String, dynamic>? _nextStoryData;

  bool _isLoading = true;
  String? _errorMessage;
  final FeedService _feedService = FeedService();

  // DUAL VIDEO CONTROLLERS
  VideoPlayerController? _currentVideoController;
  VideoPlayerController? _nextVideoController;
  bool _isCurrentVideoInitialized = false;
  bool _isNextVideoInitialized = false;

  // ✅ Keep the immediate previous video controller for fast back navigation.
  // This avoids re-buffering when users go forward then quickly back.
  VideoPlayerController? _prevVideoController;
  int? _prevVideoIndex;

  PageController? _pageController;

  // Timer animation controllers
  AnimationController? _timerController;
  bool _isPaused = false;
  bool _isMuted = false;
  static const Duration _imageDuration = Duration(seconds: 5);

  bool _isDisposed = false;

  /// NEW: track whether this State is "active" in the tree.
  /// Flutter can keep `mounted == true` while the element is deactivated.
  bool _isActiveInTree = true;

  /// Only rebuild if this State is still active (not deactivated) and not disposed.
  void _safeSetState(VoidCallback fn) {
    if (_isDisposed || !_isActiveInTree || !mounted) return;
    setState(fn);
  }

  // ===== Prefetch controller ownership transfer =====
  VideoPlayerController? _takePrefetchedVideo(int index) {
    final ctrl = _prefetchVideoByIndex.remove(index);
    _prefetchInitializedVideoIndex.remove(index);
    return ctrl;
  }

  bool _isControllerUsable(VideoPlayerController? c) {
    if (c == null) return false;
    try {
      final v = c.value;
      return v.isInitialized;
    } catch (_) {
      return false;
    }
  }

  // CROSSFADE ANIMATION CONTROLLER
  AnimationController? _crossfadeController;
  Animation<double>? _crossfadeAnimation;
  bool _isTransitioning = false;

  // Swipe gesture tracking
  double _dragStartY = 0.0;
  double _dragCurrentY = 0.0;
  bool _isDragging = false;

  // Memory category data
  // ignore: unused_field
  String? _memoryCategoryName;
  String? _memoryCategoryIcon;
  String? _memoryId;
  List<String>? _memoryParticipantAvatars;
  String? _memoryState; // 'open' | 'sealed' (best-effort)

  bool get _isSealedMemory => (_memoryState ?? '').trim().toLowerCase() == 'sealed';

  // Memory membership (for action bar)
  String? _membershipMemoryId;
  bool _isCurrentUserMember = false;
  bool _isCurrentUserCreator = false;

  // Prefetching state
  // ignore: unused_field
  bool _isPrefetching = false;

  // ✅ Prevent tap-through when any modal/sheet is open
  bool _isAnyModalOpen = false;

  // ✅ NEW: For happening_now/trending, show a SINGLE timer bar (not multi-segment)
  bool get _useSingleTimerBar =>
      _feedType == 'happening_now' || _feedType == 'trending';

  // ===== Prefetch window (±3) and race protection =====
  static const int _prefetchRadius = 3;
  final Map<int, Map<String, dynamic>> _prefetchDataByIndex = {};
  final Map<int, VideoPlayerController> _prefetchVideoByIndex = {};
  final Set<int> _prefetchInitializedVideoIndex = {};
  final Set<int> _prefetchInFlight = {};
  int _loadToken = 0;

  // ===== Tap zone tuning + tap debounce =====
  static const int _tapDebounceMs = 220;
  bool _tapLocked = false;

  void _lockTapBriefly() {
    _tapLocked = true;
    Future.delayed(const Duration(milliseconds: _tapDebounceMs), () {
      if (_isDisposed) return;
      _tapLocked = false;
    });
  }

  // ===== Pause overlay visibility (show play button when paused) =====
  bool get _shouldShowPlayOverlay =>
      _isPaused &&
          !_isAnyModalOpen &&
          !_isTransitioning &&
          _currentStoryData != null;

  // ===== Prevent white screen by queueing page changes during transition =====
  int? _pendingPageIndex;
  bool _navLocked = false;

  // ===== Fast-forward (long press) =====
  bool _isFastForwarding = false;
  double _fastForwardSpeed = 2.0; // 2.0x feels good
  Duration? _baseTimerDuration;
  double _baseVideoSpeed = 1.0;

  AnimationController? _ffPulseController;
  Animation<double>? _ffPulseAnim;

  // ===== Keep a real listener reference =====
  VoidCallback? _currentVideoEndListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _timerController = AnimationController(
      vsync: this,
      duration: _imageDuration,
    );

    _crossfadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _crossfadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _crossfadeController!, curve: Curves.easeInOut),
    );

    _ffPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _ffPulseAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ffPulseController!, curve: Curves.easeInOut),
    );

    _timerController?.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          !_isPaused &&
          !_isTransitioning &&
          !_isAnyModalOpen) {
        _triggerHapticFeedback(HapticFeedbackType.light);
        _goToNextStory();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;

      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is String) {
        _initialStoryId = args;
        _feedType = 'latest_stories';
        _loadAllLatestStories();
      } else if (args is FeedStoryContext) {
        _loadStoriesFromContext(args);
      } else {
        _safeSetState(() {
          _isLoading = false;
          _errorMessage = 'Invalid story data provided';
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markStoryAsViewed();
    });
  }

  // ✅ Always stop playback when app is backgrounded
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pausePlaybackForModal();
    }
    super.didChangeAppLifecycleState(state);
  }

  // ✅ CRITICAL: stop playback when this route is covered (e.g., navigating to profile)
  @override
  void deactivate() {
    _isActiveInTree = false;
    _pausePlaybackForModal();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _isActiveInTree = true;

    if (!mounted) return;
    if (_isPaused) return;
    if (_isAnyModalOpen) return;
    if (_isTransitioning) return;
    _resumePlaybackAfterModal(wasPausedBefore: false);
  }

  // =========================
  // Fast-forward helpers
  // =========================

  void _startFastForwardHold() {
    if (_isAnyModalOpen) return;
    if (_isTransitioning) return;
    if (_currentStoryData == null) return;

    final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';

    _safeSetState(() {
      _isFastForwarding = true;
    });

    _timerController?.stop();

    if (mediaType == 'video') {
      final c = _currentVideoController;
      if (c != null && _isCurrentVideoInitialized) {
        try {
          _baseVideoSpeed = c.value.playbackSpeed;
          c.setPlaybackSpeed(_fastForwardSpeed);
          if (!c.value.isPlaying) c.play();
        } catch (_) {}
      }
      if (!_isPaused && !_isAnyModalOpen && !_isTransitioning) {
        _timerController?.forward();
      }
      return;
    }

    final timer = _timerController;
    if (timer == null) return;

    _baseTimerDuration ??= timer.duration ?? _imageDuration;

    final baseDuration = _baseTimerDuration ?? _imageDuration;
    final currentValue = timer.value.clamp(0.0, 1.0);

    timer.duration = Duration(
      milliseconds: (baseDuration.inMilliseconds / _fastForwardSpeed).round(),
    );

    timer.forward(from: currentValue);
  }

  void _stopFastForwardHold() {
    final wasFastForwarding = _isFastForwarding;

    if (wasFastForwarding) {
      _safeSetState(() {
        _isFastForwarding = false;
      });
    }

    final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';

    if (mediaType == 'video') {
      final c = _currentVideoController;
      if (c != null && _isCurrentVideoInitialized) {
        try {
          c.setPlaybackSpeed(_baseVideoSpeed <= 0 ? 1.0 : _baseVideoSpeed);
        } catch (_) {}
      }

      if (!_isPaused && !_isAnyModalOpen && !_isTransitioning) {
        _timerController?.forward();
      }
      return;
    }

    final timer = _timerController;
    if (timer == null) return;

    final currentValue = timer.value.clamp(0.0, 1.0);

    final base = _baseTimerDuration ?? _imageDuration;
    timer.duration = base;

    if (!_isPaused && !_isAnyModalOpen && !_isTransitioning) {
      timer.forward(from: currentValue);
    } else {
      timer.stop();
    }
  }

  // =========================
  // Data loading
  // =========================

  Future<void> _loadStoriesFromContext(FeedStoryContext args) async {
    try {
      _safeSetState(() => _isLoading = true);

      _feedType = args.feedType;
      _initialStoryId = args.initialStoryId;

      if (_feedType == 'happening_now') {
        _storyIds = await _feedService.fetchHappeningNowStoryIds();
      } else if (_feedType == 'trending') {
        _storyIds = args.storyIds;
      } else {
        _storyIds = args.storyIds;
      }

      if (_initialStoryId == null || _initialStoryId!.isEmpty) {
        _safeSetState(() {
          _isLoading = false;
          _errorMessage = 'No story ID provided';
        });
        return;
      }

      _currentIndex = _storyIds.indexOf(_initialStoryId!);
      if (_currentIndex == -1) _currentIndex = 0;

      _startingIndex = _currentIndex;
      _pageController = PageController(initialPage: _currentIndex);

      await _loadStoryAtIndex(_currentIndex);

      _safeSetState(() {
        _isLoading = false;
      });
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _errorMessage = 'Error loading stories: ${e.toString()}';
      });
    }
  }

  Future<void> _loadAllLatestStories() async {
    if (_initialStoryId == null) {
      _safeSetState(() {
        _isLoading = false;
        _errorMessage = 'No story ID provided';
      });
      return;
    }

    try {
      _safeSetState(() => _isLoading = true);

      _storyIds = await _feedService.fetchLatestStoryIds();

      _currentIndex = _storyIds.indexOf(_initialStoryId!);
      if (_currentIndex == -1) _currentIndex = 0;

      _startingIndex = _currentIndex;
      _pageController = PageController(initialPage: _currentIndex);

      await _loadStoryAtIndex(_currentIndex);

      _safeSetState(() => _isLoading = false);
    } catch (e) {
      _safeSetState(() {
        _isLoading = false;
        _errorMessage = 'Error loading stories: ${e.toString()}';
      });
    }
  }

  // ignore: unused_element
  Future<Map<String, dynamic>?> _getStoryWithMemoryId(String storyId) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return null;

      final response = await client
          .from('stories')
          .select('id, memory_id')
          .eq('id', storyId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // ===== Prefetch window control =====

  void _cleanupPrefetchWindow(int centerIndex) {
    final minKeep = centerIndex - _prefetchRadius;
    final maxKeep = centerIndex + _prefetchRadius;

    final indicesToRemove = <int>[];
    for (final idx in _prefetchDataByIndex.keys) {
      if (idx < minKeep || idx > maxKeep) indicesToRemove.add(idx);
    }
    for (final idx in indicesToRemove) {
      _prefetchDataByIndex.remove(idx);
    }

    final videoIndicesToRemove = <int>[];
    for (final idx in _prefetchVideoByIndex.keys) {
      if (idx < minKeep || idx > maxKeep) videoIndicesToRemove.add(idx);
    }
    for (final idx in videoIndicesToRemove) {
      final ctrl = _prefetchVideoByIndex.remove(idx);
      _prefetchInitializedVideoIndex.remove(idx);
      try {
        ctrl?.pause();
        ctrl?.dispose();
      } catch (_) {}
    }
  }

  Future<void> _prefetchWindowAround(int centerIndex) async {
    if (_storyIds.isEmpty) return;

    _cleanupPrefetchWindow(centerIndex);

    final minIndex =
    (centerIndex - _prefetchRadius).clamp(0, _storyIds.length - 1);
    final maxIndex =
    (centerIndex + _prefetchRadius).clamp(0, _storyIds.length - 1);

    for (int i = minIndex; i <= maxIndex; i++) {
      final id = _storyIds[i];
      ReactionPreloader.instance.preload(id);

      if (i == centerIndex) continue;
      _prefetchIndex(i);
    }
  }

  Future<void> _prefetchIndex(int index) async {
    if (index < 0 || index >= _storyIds.length) return;
    if (_prefetchInFlight.contains(index)) return;

    _prefetchInFlight.add(index);

    try {
      final storyId = _storyIds[index];

      ReactionPreloader.instance.preload(storyId);

      final data = _prefetchDataByIndex[index] ??
          await _feedService.fetchStoryDetails(storyId);

      if (data == null) return;

      _prefetchDataByIndex[index] = data;

      final mediaType = data['media_type'] as String? ?? 'image';
      final mediaUrl = data['media_url'] as String?;

      if (mediaType == 'video' && mediaUrl != null && mediaUrl.isNotEmpty) {
        if (!_prefetchVideoByIndex.containsKey(index)) {
          final ctrl = VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
          await ctrl.initialize();
          ctrl.setLooping(false);
          ctrl.setVolume(0.0);
          _prefetchVideoByIndex[index] = ctrl;
          _prefetchInitializedVideoIndex.add(index);
        }
      } else if (mediaType == 'image' &&
          mediaUrl != null &&
          mediaUrl.isNotEmpty) {
        if (mounted && _isActiveInTree && !_isDisposed) {
          await precacheImage(CachedNetworkImageProvider(mediaUrl), context);
        }
      }
    } catch (_) {
      // ignore
    } finally {
      _prefetchInFlight.remove(index);
    }
  }

  // ===== Main loader uses ±3 prefetch cache first =====
  Future<void> _loadStoryAtIndex(int index) async {
    if (index < 0 || index >= _storyIds.length) return;

    final int token = ++_loadToken;

    try {
      _timerController?.stop();
      _timerController?.reset();

      final storyId = _storyIds[index];

      ReactionPreloader.instance.preload(storyId);

      Map<String, dynamic>? storyData = _prefetchDataByIndex[index];

      // If we have a prefetched controller for this index, TAKE it (ownership transfer)
      VideoPlayerController? prefetchedVideo = _takePrefetchedVideo(index);
      bool prefetchedVideoInitialized = _isControllerUsable(prefetchedVideo);

      // ✅ If we cached the immediate previous controller (fast back), reuse it.
      if (prefetchedVideo == null &&
          _prevVideoIndex == index &&
          _isControllerUsable(_prevVideoController)) {
        prefetchedVideo = _prevVideoController;
        prefetchedVideoInitialized = true;
        _prevVideoController = null;
        _prevVideoIndex = null;
      }

      if (storyData == null &&
          _nextStoryData != null &&
          _nextStoryData!['id'] == storyId) {
        storyData = _nextStoryData;

        // TAKE next slot controller safely (ownership transfer to current)
        prefetchedVideo = _nextVideoController;
        prefetchedVideoInitialized = _isControllerUsable(prefetchedVideo);

        _nextStoryData = null;
        _nextVideoController = null;
        _isNextVideoInitialized = false;
      }

      // If the prefetched controller was disposed or unusable, drop it.
      if (!_isControllerUsable(prefetchedVideo)) {
        try {
          prefetchedVideo?.dispose();
        } catch (_) {}
        prefetchedVideo = null;
        prefetchedVideoInitialized = false;
      }

      storyData ??= await _feedService.fetchStoryDetails(storyId);
      if (_isDisposed || !mounted || !_isActiveInTree || token != _loadToken) {
        return;
      }

      if (storyData == null) {
        _safeSetState(() => _errorMessage = 'Story not found');
        return;
      }

      final memoryId = storyData['memory_id'] as String?;
      if (memoryId != null && memoryId.isNotEmpty) {
        // Avoid flashing stale membership actions when switching between memories.
        if (_membershipMemoryId != memoryId) {
          _safeSetState(() {
            _membershipMemoryId = null;
            _isCurrentUserMember = false;
            _isCurrentUserCreator = false;
          });
        }

        _memoryId = memoryId;
        await _fetchMemoryCategory(memoryId);
        // Determine membership for action bar (joined memories should still show actions).
        await _refreshMemoryMembership(memoryId, token: token);
        if (_isDisposed ||
            !mounted ||
            !_isActiveInTree ||
            token != _loadToken) {
          return;
        }
      } else {
        // No memory -> no membership actions
        _safeSetState(() {
          _membershipMemoryId = null;
          _isCurrentUserMember = false;
          _isCurrentUserCreator = false;
        });
      }

      if (_currentStoryData == null) {
        _currentStoryData = storyData;
        _currentVideoController = prefetchedVideo;
        _isCurrentVideoInitialized = prefetchedVideoInitialized;

        _safeSetState(() {
          _currentIndex = index;
          _isLoading = false;
          _initialStoryId = storyId;
        });

        await _markStoryAsViewed();
        await _startCurrentStoryPlaybackIfAllowed();

        _prefetchWindowAround(index);
        return;
      }

      _nextStoryData = storyData;
      _nextVideoController = prefetchedVideo;
      _isNextVideoInitialized = prefetchedVideoInitialized;

      final mediaType = storyData['media_type'] as String? ?? 'image';
      final mediaUrl = storyData['media_url'] as String?;

      if (mediaType == 'video' && mediaUrl != null && mediaUrl.isNotEmpty) {
        if (_nextVideoController == null || !_isNextVideoInitialized) {
          await _initializeVideoPlayer(mediaUrl, isCurrentSlot: false);
          if (_isDisposed ||
              !mounted ||
              !_isActiveInTree ||
              token != _loadToken) {
            return;
          }
        }
      } else if (mediaType == 'image' &&
          mediaUrl != null &&
          mediaUrl.isNotEmpty) {
        if (mounted && _isActiveInTree && !_isDisposed) {
          await precacheImage(CachedNetworkImageProvider(mediaUrl), context);
        }
        if (_isDisposed || !mounted || !_isActiveInTree || token != _loadToken) {
          return;
        }
      }

      await _performCrossfadeTransition(index, storyId);

      _prefetchWindowAround(index);
    } catch (e) {
      _safeSetState(
              () => _errorMessage = 'Error loading story: ${e.toString()}');
    }
  }

  Future<void> _startCurrentStoryPlaybackIfAllowed() async {
    if (_isDisposed || !mounted || !_isActiveInTree) return;
    if (_isPaused || _isAnyModalOpen || _isTransitioning) return;

    final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';
    final mediaUrl = _currentStoryData?['media_url'] as String?;

    if (mediaType == 'video' && mediaUrl != null && mediaUrl.isNotEmpty) {
      if (_currentVideoController == null || !_isCurrentVideoInitialized) {
        await _initializeVideoPlayer(mediaUrl, isCurrentSlot: true);
        return;
      }

      _currentVideoController!.setVolume(_isMuted ? 0.0 : 1.0);
      await _currentVideoController!.play();

      final videoDuration = _currentVideoController!.value.duration;
      _timerController?.duration = videoDuration;
      _baseTimerDuration = videoDuration;
      _timerController?.forward();
    } else {
      _timerController?.duration = _imageDuration;
      _baseTimerDuration = _imageDuration;
      _timerController?.forward();
    }
  }

  Future<void> _performCrossfadeTransition(int newIndex, String storyId) async {
    if (_isTransitioning) return;

    try {
      _isTransitioning = true;
      _timerController?.stop();
      _crossfadeController?.reset();

      if (_isFastForwarding) {
        _stopFastForwardHold();
      }

      // Remember the index we are leaving so we can keep its controller for fast back.
      final previousIndex = _currentIndex;

      _safeSetState(() {
        _currentIndex = newIndex;
        _initialStoryId = storyId;
        // Navigating between stories should resume playback.
        _isPaused = false;
      });

      await _crossfadeController?.forward();

      await _swapMediaSlots(previousIndex: previousIndex);

      _isTransitioning = false;

      await _markStoryAsViewed();
      await _startCurrentStoryPlaybackIfAllowed();

      final queued = _pendingPageIndex;
      _pendingPageIndex = null;
      if (queued != null &&
          queued != _currentIndex &&
          mounted &&
          _isActiveInTree) {
        await Future<void>.delayed(Duration.zero);
        _loadStoryAtIndex(queued);
        return;
      }
    } catch (_) {
      _isTransitioning = false;
    }
  }

  Future<void> _swapMediaSlots({required int previousIndex}) async {
    if (_currentVideoController != null) {
      // Keep the previous controller alive for instant back navigation.
      try {
        await _currentVideoController!.pause();
      } catch (_) {}

      // Cap memory: keep at most 1 previous controller.
      if (_prevVideoController != null) {
        try {
          await _prevVideoController!.dispose();
        } catch (_) {}
      }
      _prevVideoController = _currentVideoController;
      _prevVideoIndex = previousIndex;
    }

    _currentStoryData = _nextStoryData;
    _currentVideoController = _nextVideoController;
    _isCurrentVideoInitialized = _isNextVideoInitialized;

    _nextStoryData = null;
    _nextVideoController = null;
    _isNextVideoInitialized = false;

    _safeSetState(() {});
  }

  Future<void> _fetchMemoryCategory(String memoryId) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      // IMPORTANT:
      // This app uses `title` + `location_name` for memories elsewhere (timeline, feed, etc).
      // Keep this query compatible with older/newer schema variants too.
      final response = await client.from('memories').select('''
            id,
            title,
            name,
            created_at,
            location_name,
            location,
            visibility,
            state,
            creator_id,
            category_id,
            memory_categories(name, icon_name, icon_url)
          ''').eq('id', memoryId).single();

      final categoryData = (response['memory_categories'] as Map?)?.cast<String, dynamic>();
      final iconName = (categoryData?['icon_name'] as String?)?.trim();
      final iconUrl = (categoryData?['icon_url'] as String?)?.trim();

      String? resolvedCategoryIcon;
      if (iconName != null && iconName.isNotEmpty) {
        final resolved = StorageUtils.resolveMemoryCategoryIconUrl(iconName);
        if (resolved.trim().isNotEmpty) {
          resolvedCategoryIcon = resolved.trim();
        } else if (iconUrl != null && iconUrl.isNotEmpty) {
          resolvedCategoryIcon = iconUrl;
        }
      } else if (iconUrl != null && iconUrl.isNotEmpty) {
        resolvedCategoryIcon = iconUrl;
      }

      // Fallback: some memories may have no category_id join but do have category_icon set.
      if (resolvedCategoryIcon == null || resolvedCategoryIcon.trim().isEmpty) {
        final fallback = (response['category_icon'] as String?)?.trim();
        if (fallback != null &&
            (fallback.startsWith('http://') || fallback.startsWith('https://'))) {
          resolvedCategoryIcon = fallback;
        }
      }

      // Fetch participant avatars for snapshot navigation (best-effort).
      List<String> participantAvatars = [];
      try {
        final contributorsResponse = await client
            .from('memory_contributors')
            .select('user_id, user_profiles(avatar_url)')
            .eq('memory_id', memoryId);

        participantAvatars = (contributorsResponse as List?)
                ?.map((c) {
                  final profile = (c['user_profiles'] as Map?)?.cast<String, dynamic>();
                  return AvatarHelperService.getAvatarUrl(
                    profile?['avatar_url'] as String?,
                  );
                })
                .whereType<String>()
                .where((u) => u.trim().isNotEmpty)
                .toList() ??
            <String>[];
      } catch (_) {
        participantAvatars = <String>[];
      }

      // Ensure creator avatar is included (creator may not be in contributors table).
      try {
        final creatorId = (response['creator_id'] as String?)?.trim();
        if (creatorId != null && creatorId.isNotEmpty) {
          final creatorRow = await client
              .from('user_profiles')
              .select('avatar_url')
              .eq('id', creatorId)
              .maybeSingle();
          final creatorAvatar =
              AvatarHelperService.getAvatarUrl((creatorRow?['avatar_url'] as String?)?.trim());
          if (creatorAvatar.trim().isNotEmpty &&
              !participantAvatars.contains(creatorAvatar)) {
            participantAvatars = [creatorAvatar, ...participantAvatars];
          }
        }
      } catch (_) {
        // ignore
      }

      _safeSetState(() {
        _memoryId = memoryId;
        _memoryCategoryName = (categoryData?['name'] as String?)?.trim();
        _memoryCategoryIcon = (resolvedCategoryIcon != null && resolvedCategoryIcon.isNotEmpty)
            ? resolvedCategoryIcon
            : null;
        _memoryParticipantAvatars = participantAvatars.isEmpty ? null : participantAvatars;
        _memoryState = (response['state'] as String?)?.trim();
      });

      if (_currentStoryData != null) {
        _currentStoryData!['memory_title'] =
            (response['title'] as String?) ?? (response['name'] as String?);
        _currentStoryData!['memory_date'] = response['created_at'] as String?;
        _currentStoryData!['memory_location'] =
            (response['location_name'] as String?) ?? (response['location'] as String?);
        _currentStoryData!['memory_visibility'] =
        response['visibility'] as String?;
        _currentStoryData!['memory_state'] = response['state'] as String?;
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ _fetchMemoryCategory failed: $e');
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl,
      {required bool isCurrentSlot}) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();

      controller.setVolume(_isMuted ? 0.0 : 1.0);
      controller.setLooping(false);

      if (isCurrentSlot) {
        if (_currentVideoController != null && _currentVideoEndListener != null) {
          try {
            _currentVideoController!.removeListener(_currentVideoEndListener!);
          } catch (_) {}
        }

        _currentVideoController = controller;
        _isCurrentVideoInitialized = true;

        final videoDuration = controller.value.duration;
        _timerController?.duration = videoDuration;
        _baseTimerDuration = videoDuration;

        _currentVideoEndListener = () {
          final c = _currentVideoController;
          if (c == null) return;
          if (!c.value.isInitialized) return;

          final pos = c.value.position;
          final dur = c.value.duration;
          if (dur != Duration.zero && pos >= dur) {
            if (!_isPaused && !_isTransitioning && !_isAnyModalOpen) {
              _goToNextStory();
            }
          }
        };
        controller.addListener(_currentVideoEndListener!);

        if (!_isPaused && !_isAnyModalOpen && !_isTransitioning) {
          controller.play();
          _timerController?.forward();
        }
      } else {
        _nextVideoController = controller;
        _isNextVideoInitialized = true;
      }

      _safeSetState(() {});
    } catch (_) {
      _safeSetState(() => _errorMessage = 'Failed to load video');
    }
  }

  void _goToNextStory() {
    if (_isAnyModalOpen) return;
    if (_isTransitioning) return;
    if (_navLocked) return;

    _navLocked = true;

    if (_currentIndex < _storyIds.length - 1) {
      _triggerHapticFeedback(HapticFeedbackType.light);
      // ✅ Always resume on navigation (fixes "back/forward doesn't play").
      _safeSetState(() => _isPaused = false);

      _pageController?.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
    } else {
      _timerController?.stop();
      _currentVideoController?.pause();
      _safeSetState(() => _isPaused = true);
    }

    Future.delayed(const Duration(milliseconds: 320), () {
      if (_isDisposed) return;
      _navLocked = false;
    });
  }

  void _goToPreviousStory() {
    if (_isAnyModalOpen) return;
    if (_isTransitioning) return;
    if (_navLocked) return;

    _navLocked = true;

    if (_currentIndex > 0) {
      _triggerHapticFeedback(HapticFeedbackType.light);
      // ✅ Always resume on navigation (fixes "back doesn't play").
      _safeSetState(() => _isPaused = false);

      _pageController?.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
    }

    Future.delayed(const Duration(milliseconds: 320), () {
      if (_isDisposed) return;
      _navLocked = false;
    });
  }

  void _togglePauseResume() {
    _safeSetState(() {
      _isPaused = !_isPaused;

      if (_isPaused) {
        _timerController?.stop();
        _currentVideoController?.pause();
      } else {
        if (!_isAnyModalOpen && !_isTransitioning) {
          _timerController?.forward();
          final mediaType =
              _currentStoryData?['media_type'] as String? ?? 'image';
          if (mediaType == 'video' &&
              _currentVideoController != null &&
              _isCurrentVideoInitialized) {
            _currentVideoController?.play();
          }
        }
      }
    });
  }

  void _toggleMute() {
    _triggerHapticFeedback(HapticFeedbackType.selection);

    _safeSetState(() {
      _isMuted = !_isMuted;
      _currentVideoController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  Future<void> _triggerHapticFeedback(HapticFeedbackType type) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      switch (type) {
        case HapticFeedbackType.light:
          await Vibration.vibrate(duration: 10);
          break;
        case HapticFeedbackType.medium:
          await Vibration.vibrate(duration: 20);
          break;
        case HapticFeedbackType.selection:
          await Vibration.vibrate(duration: 15);
          break;
      }
    } catch (_) {}
  }

  Future<void> _shareStory() async {
    final shareCode = _currentStoryData?['share_code'] as String?;
    final storyId = _storyIds.isNotEmpty ? _storyIds[_currentIndex] : _initialStoryId;

    final shareIdentifier = shareCode ?? storyId;
    if (shareIdentifier == null || shareIdentifier.isEmpty) return;

    try {
      final shareUrl = 'https://share.capapp.co/$shareIdentifier';
      await Share.share(shareUrl);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to share story',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.whiteCustom),
          ),
          backgroundColor: appTheme.colorFF3A3A,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isActiveInTree = false;
    WidgetsBinding.instance.removeObserver(this);
    _immediateMuteAndPauseAllVideos();
    // Best-effort hard stop; dispose can't await.
    unawaited(_performHardMediaReset());
    _timerController?.dispose();
    _crossfadeController?.dispose();
    _pageController?.dispose();
    _ffPulseController?.dispose();

    for (final ctrl in _prefetchVideoByIndex.values) {
      try {
        ctrl.pause();
        ctrl.dispose();
      } catch (_) {}
    }
    _prefetchVideoByIndex.clear();
    _prefetchDataByIndex.clear();
    _prefetchInitializedVideoIndex.clear();
    _prefetchInFlight.clear();
    for (final id in _storyIds) {
      ReactionPreloader.instance.clearStory(id);
    }
    super.dispose();
  }

  void _immediateMuteAndPauseAllVideos() {
    // Do a synchronous "audio kill switch" first. This prevents intermittent
    // background playback during route pop gestures while we await disposals.
    try {
      _currentVideoController?.setVolume(0.0);
    } catch (_) {}
    try {
      _currentVideoController?.pause();
    } catch (_) {}

    try {
      _nextVideoController?.setVolume(0.0);
    } catch (_) {}
    try {
      _nextVideoController?.pause();
    } catch (_) {}

    try {
      _prevVideoController?.setVolume(0.0);
    } catch (_) {}
    try {
      _prevVideoController?.pause();
    } catch (_) {}

    for (final ctrl in _prefetchVideoByIndex.values) {
      try {
        ctrl.setVolume(0.0);
      } catch (_) {}
      try {
        ctrl.pause();
      } catch (_) {}
    }
  }

  Future<void> _performHardMediaReset() async {
    try {
      _immediateMuteAndPauseAllVideos();
      _loadToken++;
      _timerController?.stop();
      _timerController?.reset();
      _crossfadeController?.stop();
      _crossfadeController?.reset();

      _pendingPageIndex = null;
      _navLocked = false;

      if (_currentVideoController != null) {
        try {
          if (_currentVideoEndListener != null) {
            _currentVideoController!.removeListener(_currentVideoEndListener!);
          }
        } catch (_) {}
        _currentVideoEndListener = null;

        try {
          await _currentVideoController!.pause();
        } catch (_) {}
        try {
          _currentVideoController!.setVolume(0.0);
        } catch (_) {}
        // NOTE:
        // Don't call seekTo() right before dispose(). seekTo is async and may
        // continue after disposal, causing "VideoPlayerController used after being disposed".
        try {
          await _currentVideoController!.dispose();
        } catch (_) {}
        _currentVideoController = null;
        _isCurrentVideoInitialized = false;
      }

      if (_prevVideoController != null) {
        try {
          await _prevVideoController!.pause();
        } catch (_) {}
        try {
          _prevVideoController!.setVolume(0.0);
        } catch (_) {}
        try {
          await _prevVideoController!.dispose();
        } catch (_) {}
        _prevVideoController = null;
        _prevVideoIndex = null;
      }

      if (_nextVideoController != null) {
        try {
          await _nextVideoController!.pause();
        } catch (_) {}
        try {
          _nextVideoController!.setVolume(0.0);
        } catch (_) {}
        // NOTE: same reasoning as above—avoid async work right before dispose.
        try {
          await _nextVideoController!.dispose();
        } catch (_) {}
        _nextVideoController = null;
        _isNextVideoInitialized = false;
      }

      // Prefetched controllers are never supposed to play, but dispose them anyway.
      for (final ctrl in _prefetchVideoByIndex.values) {
        try {
          ctrl.setVolume(0.0);
        } catch (_) {}
        try {
          await ctrl.pause();
        } catch (_) {}
        try {
          await ctrl.dispose();
        } catch (_) {}
      }
      _prefetchVideoByIndex.clear();
      _prefetchInitializedVideoIndex.clear();
      _prefetchInFlight.clear();

      _currentStoryData = null;
      _nextStoryData = null;
      _isPrefetching = false;
      _isTransitioning = false;
      _isFastForwarding = false;

      _baseTimerDuration = _imageDuration;
      _timerController?.duration = _imageDuration;
    } catch (_) {}
  }

  Future<void> _navigateToTimeline(MemoryNavArgs navArgs) async {
    final wasPausedBefore = _isPaused;

    _pausePlaybackForModal();
    _safeSetState(() => _isAnyModalOpen = true);

    await Navigator.pushNamed(
      context,
      _isSealedMemory ? AppRoutes.appTimelineSealed : AppRoutes.appTimeline,
      arguments: navArgs,
    );

    if (_isDisposed || !mounted) return;

    _safeSetState(() => _isAnyModalOpen = false);

    _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
  }

  Future<void> _markStoryAsViewed() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final currentStoryId = _initialStoryId;
      if (currentStoryId == null) return;

      await client.from('story_views').upsert({
        'story_id': currentStoryId,
        'user_id': currentUserId,
        'viewed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'story_id,user_id');
    } catch (_) {}
  }

  // =========================
  // Modal helpers
  // =========================

  void _pausePlaybackForModal() {
    _timerController?.stop();
    _currentVideoController?.pause();

    if (_isFastForwarding) {
      _stopFastForwardHold();
    }
  }

  void _resumePlaybackAfterModal({required bool wasPausedBefore}) {
    if (_isDisposed || !mounted || !_isActiveInTree) return;
    if (wasPausedBefore) return;
    if (_isTransitioning) return;

    final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';

    _timerController?.forward();

    if (mediaType == 'video' &&
        _currentVideoController != null &&
        _isCurrentVideoInitialized) {
      _currentVideoController!.play();
    }
  }

  Future<void> _openReportStoryModal({required bool wasPausedBefore}) async {
    final storyId = _initialStoryId ?? '';
    final reportedUserName =
        _currentStoryData?['user_name'] as String? ?? 'Unknown User';
    final reportedUserId = _currentStoryData?['user_id'] as String? ?? '';
    final reportedUserAvatar = _currentStoryData?['user_avatar'] as String?;

    _pausePlaybackForModal();
    _safeSetState(() => _isAnyModalOpen = true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(180),
      builder: (sheetContext) {
        return ReportStoryScreen(
          storyId: storyId,
          reportedUserName: reportedUserName,
          reportedUserId: reportedUserId,
          reportedUserAvatar: reportedUserAvatar,
        );
      },
    );

    if (_isDisposed || !mounted) return;

    _safeSetState(() => _isAnyModalOpen = false);
    _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Account for top UI (SafeArea + timer bars + header) and bottom UI
      // so the skeleton is centered in the actual content viewing area
      final topInset = MediaQuery.of(context).padding.top;
      final bottomInset = MediaQuery.of(context).padding.bottom;
      final topOffset = topInset + 140.h; // timer bars + header
      final bottomOffset = bottomInset + 230.h; // bottom info area

      return Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Padding(
          padding: EdgeInsets.only(top: topOffset, bottom: bottomOffset),
          child: Center(
            child: CircularProgressIndicator(color: appTheme.colorFF3A3A),
          ),
        ),
      );
    }

    if (_errorMessage != null || _currentStoryData == null) {
      return Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.h,
                color: appTheme.blue_gray_300,
              ),
              SizedBox(height: 16.h),
              Text(
                _errorMessage ?? 'Story not found',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 24.h),
              CustomButton(
                text: 'Go Back',
                width: 200.h,
                onPressed: () async {
                  await _performHardMediaReset();
                  if (mounted) Navigator.pop(context);
                },
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _performHardMediaReset();
        return true;
      },
      child: Scaffold(
        backgroundColor: appTheme.blackCustom,
        extendBodyBehindAppBar: true,
        body: GestureDetector(
          onVerticalDragStart: (details) {
            if (_isAnyModalOpen) return;
            _safeSetState(() {
              _dragStartY = details.globalPosition.dy;
              _dragCurrentY = details.globalPosition.dy;
              _isDragging = true;
            });
          },
          onVerticalDragUpdate: (details) {
            if (_isAnyModalOpen) return;
            _safeSetState(() {
              _dragCurrentY = details.globalPosition.dy;
            });
          },
          onVerticalDragEnd: (details) async {
            if (_isAnyModalOpen) return;

            final dragDistance = _dragCurrentY - _dragStartY;
            final velocity = details.primaryVelocity ?? 0;

            if (dragDistance > 100 || velocity > 500) {
              _triggerHapticFeedback(HapticFeedbackType.medium);
              await _performHardMediaReset();
              if (mounted) Navigator.of(context).pop();
            }

            _safeSetState(() {
              _isDragging = false;
              _dragStartY = 0.0;
              _dragCurrentY = 0.0;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(
              0,
              _isDragging
                  ? (_dragCurrentY - _dragStartY).clamp(0, double.infinity)
                  : 0,
              0,
            ),
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _storyIds.length,
              onPageChanged: (index) {
                if (_isDisposed || !mounted || !_isActiveInTree) return;

                if (_isTransitioning) {
                  _pendingPageIndex = index;
                  return;
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_isDisposed || !mounted || !_isActiveInTree) return;

                  if (_isTransitioning) {
                    _pendingPageIndex = index;
                  } else {
                    _loadStoryAtIndex(index);
                  }
                });
              },
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildDualMediaLayers(),
                    _buildGradientOverlays(),

                    // ✅ Tap zones are now carved to NOT cover the top UI or bottom UI.
                    _buildTapZones(),

                    if (_shouldShowPlayOverlay) _buildPlayOverlay(),
                    if (_isFastForwarding) _buildFastForwardOverlay(),
                    SafeArea(
                      top: true,
                      bottom: false, // ✅ this removes the extra padding under reactions/caption
                      child: Column(
                        children: [
                          _useSingleTimerBar
                              ? _buildSingleTimerBar()
                              : _buildTimerBars(),
                          _buildTopBar(),
                          const Spacer(),
                          _buildBottomInfo(),
                        ],
                      ),
                    ),
                    _buildTappableUserProfile(),
                    _buildMediaTypeIndicator(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFastForwardOverlay() {
    return IgnorePointer(
      ignoring: true,
      child: Center(
        child: FadeTransition(
          opacity: _ffPulseAnim!,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 10.h),
            decoration: BoxDecoration(
              color: appTheme.blackCustom.withAlpha(160),
              borderRadius: BorderRadius.circular(28.h),
              border: Border.all(
                color: appTheme.whiteCustom.withAlpha(70),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fast_forward_rounded,
                    color: appTheme.whiteCustom, size: 22.h),
                SizedBox(width: 10.h),
                Text(
                  '${_fastForwardSpeed.toStringAsFixed(0)}x',
                  style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                      .copyWith(color: appTheme.whiteCustom),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayOverlay() {
    return IgnorePointer(
      ignoring: false,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_isAnyModalOpen) return;
            _triggerHapticFeedback(HapticFeedbackType.selection);
            _togglePauseResume();
          },
          child: Container(
            width: 68.h,
            height: 68.h,
            decoration: BoxDecoration(
              color: appTheme.blackCustom.withAlpha(140),
              shape: BoxShape.circle,
              border: Border.all(
                color: appTheme.whiteCustom.withAlpha(60),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: appTheme.whiteCustom,
              size: 44.h,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTypeIndicator() {
    final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';
    if (mediaType != 'image') return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 74.h,
      right: 16.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
        decoration: BoxDecoration(
          color: appTheme.blackCustom.withAlpha(140),
          borderRadius: BorderRadius.circular(16.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_outlined,
              size: 16.h,
              color: appTheme.whiteCustom.withAlpha(220),
            ),
            SizedBox(width: 6.h),
            Text(
              'Photo',
              style: TextStyleHelper.instance.body12RegularPlusJakartaSans
                  .copyWith(color: appTheme.whiteCustom.withAlpha(220)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualMediaLayers() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_currentStoryData != null)
          _buildMediaLayer(
            _currentStoryData!,
            _currentVideoController,
            _isCurrentVideoInitialized,
          ),
        if (_isTransitioning && _nextStoryData != null)
          FadeTransition(
            opacity: _crossfadeAnimation!,
            child: _buildMediaLayer(
              _nextStoryData!,
              _nextVideoController,
              _isNextVideoInitialized,
            ),
          ),
      ],
    );
  }

  Widget _buildMediaLayer(Map<String, dynamic> storyData,
      VideoPlayerController? controller, bool isInitialized) {
    final mediaUrl = storyData['media_url'] as String?;
    final mediaType = storyData['media_type'] as String? ?? 'image';

    if (mediaUrl == null || mediaUrl.isEmpty) {
      return Container(
        color: appTheme.gray_900_02,
        child: Center(
          child: Icon(Icons.image_not_supported,
              size: 64.h, color: appTheme.blue_gray_300),
        ),
      );
    }

    if (mediaType == 'video') {
      final usable = _isControllerUsable(controller);
      if (controller != null && isInitialized && usable) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        );
      } else {
        return Container(
          color: appTheme.gray_900_02,
          child: Center(
              child: CircularProgressIndicator(color: appTheme.colorFF3A3A)),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: appTheme.gray_900_02,
        child: Center(
            child: CircularProgressIndicator(color: appTheme.colorFF3A3A)),
      ),
      errorWidget: (context, url, error) => Container(
        color: appTheme.gray_900_02,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined,
                  size: 64.h, color: appTheme.blue_gray_300),
              SizedBox(height: 12.h),
              Text(
                'Failed to load image',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Tap zones (FIXED): carved out so they never cover top/bottom controls =====
  Widget _buildTapZones() {
    // Carve out:
    // - Top UI: timer bars + profile row area
    // - Bottom UI: reactions/caption + right-side buttons
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final double topBlock = topInset + 140.h; // timer + header space
    final double bottomBlock = bottomInset + 230.h; // bottom info + buttons space

    return Positioned.fill(
      child: IgnorePointer(
        // If a sheet/modal is open, tap zones must not react at all.
        ignoring: _isAnyModalOpen,
        child: Padding(
          padding: EdgeInsets.only(top: topBlock, bottom: bottomBlock),
          child: Row(
            children: [
              // Left zone: 22% (prev)
              Expanded(
                flex: 22,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isAnyModalOpen) return;
                    if (_isTransitioning) return;
                    if (_tapLocked) return;
                    _lockTapBriefly();
                    _goToPreviousStory();
                  },
                  child: const SizedBox.expand(),
                ),
              ),

              // Center zone: 56% (pause/resume)
              Expanded(
                flex: 56,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isAnyModalOpen) return;
                    if (_isTransitioning) return;
                    if (_tapLocked) return;
                    _lockTapBriefly();
                    _triggerHapticFeedback(HapticFeedbackType.selection);
                    _togglePauseResume();
                  },
                  child: const SizedBox.expand(),
                ),
              ),

              // Right zone: 22% (next + LONG PRESS = FAST FORWARD)
              Expanded(
                flex: 22,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isAnyModalOpen) return;
                    if (_isTransitioning) return;
                    if (_tapLocked) return;
                    _lockTapBriefly();
                    _goToNextStory();
                  },
                  onLongPressStart: (_) {
                    if (_isAnyModalOpen) return;
                    if (_isTransitioning) return;
                    // prevent long-press from “also” immediately allowing a tap on release
                    _tapLocked = true;
                    _startFastForwardHold();
                  },
                  onLongPressEnd: (_) {
                    _stopFastForwardHold();
                    // release lock shortly after end
                    Future.delayed(const Duration(milliseconds: 140), () {
                      if (_isDisposed) return;
                      _tapLocked = false;
                    });
                  },
                  onLongPressCancel: () {
                    _stopFastForwardHold();
                    _tapLocked = false;
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleTimerBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
      child: SizedBox(
        height: 3.h,
        child: AnimatedBuilder(
          animation: _timerController!,
          builder: (context, child) {
            final progress = _timerController?.value ?? 0.0;
            return LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: appTheme.whiteCustom.withAlpha(77),
              valueColor: AlwaysStoppedAnimation<Color>(appTheme.whiteCustom),
              minHeight: 3.h,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimerBars() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
      child: Row(
        children: List.generate(_storyIds.length, (index) {
          return Expanded(
            child: Container(
              height: 3.h,
              margin: EdgeInsets.symmetric(horizontal: 2.h),
              child: AnimatedBuilder(
                animation: _timerController!,
                builder: (context, child) {
                  double progress = 0.0;
                  if (index < _currentIndex) {
                    progress = 1.0;
                  } else if (index == _currentIndex) {
                    progress = _timerController!.value;
                  } else {
                    progress = 0.0;
                  }

                  return LinearProgressIndicator(
                    value: progress,
                    backgroundColor: appTheme.whiteCustom.withAlpha(77),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(appTheme.whiteCustom),
                    minHeight: 3.h,
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGradientOverlays() {
    return Column(
      children: [
        Container(
          height: 200.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                appTheme.blackCustom.withAlpha(179),
                appTheme.blackCustom.withAlpha(77),
                appTheme.transparentCustom,
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 150.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                appTheme.blackCustom.withAlpha(179),
                appTheme.blackCustom.withAlpha(77),
                appTheme.transparentCustom,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTappableUserProfile() {
    final userName = _currentStoryData?['user_name'] as String? ?? 'Unknown User';
    final userAvatar = _currentStoryData?['user_avatar'] as String?;
    final storyOwnerId = _currentStoryData?['user_id'] as String?;
    final memoryTitle = _currentStoryData?['memory_title'] as String?;

    Future<void> _goToStoryOwnerProfile() async {
      if (_isAnyModalOpen) return;
      if (_isTransitioning) return;
      if (storyOwnerId == null || storyOwnerId.isEmpty) return;

      final wasPausedBefore = _isPaused;

      _pausePlaybackForModal();
      _safeSetState(() => _isAnyModalOpen = true);

      await Navigator.pushNamed(
        context,
        AppRoutes.appProfileUser,
        arguments: {'userId': storyOwnerId},
      );

      if (_isDisposed || !mounted) return;

      _safeSetState(() => _isAnyModalOpen = false);
      _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20.h,
      left: 16.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.h, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _goToStoryOwnerProfile,
              child: Container(
                width: 40.h,
                height: 40.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: appTheme.whiteCustom, width: 2),
                ),
                child: ClipOval(
                  child: CustomImageView(
                    imagePath: userAvatar ?? '',
                    fit: BoxFit.cover,
                    isCircular: true,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 180.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _goToStoryOwnerProfile,
                    child: Text(
                      userName,
                      style: TextStyleHelper.instance.body16BoldPlusJakartaSans
                          .copyWith(color: appTheme.whiteCustom),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (memoryTitle != null && memoryTitle.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        if (_isAnyModalOpen) return;

                        final resolvedMemoryId =
                            _memoryId ?? (_currentStoryData?['memory_id'] as String?);

                        if (resolvedMemoryId == null || resolvedMemoryId.isEmpty) {
                          return;
                        }

                        // Ensure memory metadata (state/category/avatars) is loaded before navigation,
                        // otherwise the timeline header can end up missing category icon + member avatars
                        // when coming from this screen.
                        final needsRefresh = (_memoryId != resolvedMemoryId) ||
                            (_memoryState == null || _memoryState!.trim().isEmpty) ||
                            (_memoryCategoryIcon == null || _memoryCategoryIcon!.trim().isEmpty) ||
                            (_memoryParticipantAvatars == null || _memoryParticipantAvatars!.isEmpty);
                        if (needsRefresh) {
                          try {
                            await _fetchMemoryCategory(resolvedMemoryId);
                          } catch (_) {
                            // ignore
                          }
                        }

                        final navArgs = MemoryNavArgs(
                          memoryId: resolvedMemoryId,
                          snapshot: MemorySnapshot(
                            title: memoryTitle,
                            date: _currentStoryData?['memory_date'] as String? ??
                                _formatDate(_currentStoryData?['created_at'] as String?),
                            location: _currentStoryData?['memory_location'] as String?,
                            categoryIcon: _memoryCategoryIcon,
                            participantAvatars: _memoryParticipantAvatars,
                            isPrivate: _currentStoryData?['memory_visibility'] == 'private',
                          ),
                        );

                        await _navigateToTimeline(navArgs);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              memoryTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyleHelper.instance
                                  .body14MediumPlusJakartaSans
                                  .copyWith(
                                color: appTheme.whiteCustom.withAlpha(220),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.h),
                          Icon(
                            Icons.chevron_right,
                            size: 16.h,
                            color: appTheme.whiteCustom.withAlpha(160),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    _formatTimeAgo(_currentStoryData?['created_at'] as String? ?? ''),
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final location = _currentStoryData?['location'] as String?;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
      child: Row(
        children: [
          const Spacer(),
          if (location != null && location.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
              margin: EdgeInsets.only(right: 8.h),
              decoration: BoxDecoration(
                color: appTheme.blackCustom.withAlpha(153),
                borderRadius: BorderRadius.circular(16.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 14.h, color: Colors.white70),
                  SizedBox(width: 4.h),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 100.w),
                    child: Text(
                      location,
                      style: TextStyleHelper.instance.body12RegularPlusJakartaSans
                          .copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Timeline section actions shown under the memory title.
  /// For SEALED memories where the current user is a member but not the creator,
  /// we show Leave + Share here (instead of top-right bar).
  // ignore: unused_element
  Widget _buildTimelineSection() {
    final bool shouldShow =
        _isCurrentUserMember && !_isCurrentUserCreator && _isSealedMemory;

    if (!shouldShow) return const SizedBox.shrink();

    final memoryId = _memoryId ?? (_currentStoryData?['memory_id'] as String?);
    if (memoryId == null || memoryId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMemberActionCircle(
            icon: Icons.logout,
            iconColor: appTheme.red_500,
            onTap: () async {
              await _confirmAndLeaveMemory(memoryId);
            },
          ),
          SizedBox(width: 8.h),
          _buildMemberActionCircle(
            icon: Icons.qr_code,
            onTap: () async {
              await _openMemoryShareSheet(memoryId);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _refreshMemoryMembership(
    String memoryId, {
    required int token,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final currentUserId = client?.auth.currentUser?.id;
      final safeMemoryId = memoryId.trim();

      if (client == null ||
          currentUserId == null ||
          safeMemoryId.isEmpty ||
          _isDisposed ||
          token != _loadToken) {
        return;
      }

      // If we're already up-to-date for this memory, skip extra reads.
      if (_membershipMemoryId == safeMemoryId) return;

      bool isCreator = false;
      bool isMember = false;

      // 1) Creator check (+ state best-effort)
      final memoryRow = await client
          .from('memories')
          .select('creator_id, state')
          .eq('id', safeMemoryId)
          .maybeSingle();

      isCreator = (memoryRow?['creator_id'] as String?) == currentUserId;
      final stateRaw = (memoryRow?['state'] as String?)?.trim();
      if (stateRaw != null && stateRaw.isNotEmpty) {
        _memoryState = stateRaw;
      }
      if (isCreator) {
        isMember = true;
      } else {
        // 2) Contributor check
        final contributorRow = await client
            .from('memory_contributors')
            .select('id')
            .eq('memory_id', safeMemoryId)
            .eq('user_id', currentUserId)
            .maybeSingle();
        isMember = contributorRow != null;
      }

      if (_isDisposed || !mounted || !_isActiveInTree || token != _loadToken) {
        return;
      }

      _safeSetState(() {
        _membershipMemoryId = safeMemoryId;
        _isCurrentUserCreator = isCreator;
        _isCurrentUserMember = isMember;
      });
    } catch (_) {
      // Best-effort; don't crash the viewer
    }
  }

  Widget _buildMemberActionCircle({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (_isAnyModalOpen) return;
        if (_isTransitioning) return;
        if (_tapLocked) return;
        _lockTapBriefly();
        onTap();
      },
      child: Container(
        width: 38.h,
        height: 38.h,
        decoration: BoxDecoration(
          color: appTheme.blackCustom.withAlpha(128),
          shape: BoxShape.circle,
          border: Border.all(
            color: appTheme.whiteCustom.withAlpha(40),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor ?? appTheme.whiteCustom,
          size: 18.h,
        ),
      ),
    );
  }

  Future<void> _openMemoryShareSheet(String memoryId) async {
    final wasPausedBefore = _isPaused;
    _pausePlaybackForModal();
    _safeSetState(() => _isAnyModalOpen = true);

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => QRTimelineShareScreen(memoryId: memoryId),
      );
    } finally {
      if (_isDisposed || !mounted) return;
      _safeSetState(() => _isAnyModalOpen = false);
      _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
    }
  }

  Future<void> _confirmAndLeaveMemory(String memoryId) async {
    final client = SupabaseService.instance.client;
    final currentUserId = client?.auth.currentUser?.id;
    final safeId = memoryId.trim();
    if (client == null || currentUserId == null || safeId.isEmpty) return;

    // Creator can't "leave" their own memory
    if (_isCurrentUserCreator) return;

    final wasPausedBefore = _isPaused;
    _pausePlaybackForModal();
    _safeSetState(() => _isAnyModalOpen = true);

    try {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave memory?'),
          content: const Text('You will lose access to this memory.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await client
          .from('memory_contributors')
          .delete()
          .eq('memory_id', safeId)
          .eq('user_id', currentUserId);

      if (!mounted) return;
      await _performHardMediaReset();
      NavigatorService.popAndPushNamed(AppRoutes.appMemories);
    } finally {
      if (_isDisposed || !mounted) return;
      _safeSetState(() => _isAnyModalOpen = false);
      _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
    }
  }

  Widget _buildBottomInfo() {
    final caption = _currentStoryData?['caption'] as String?;
    final storyId = _storyIds.isNotEmpty ? _storyIds[_currentIndex] : null;
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
    final bool isDailyCapsuleViewer =
        (_feedType ?? '').trim().toLowerCase() == 'daily_capsule';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (storyId != null) _buildBottomRightControls(),
        SizedBox(height: 12.h),
        // Daily Capsule viewer is intentionally simplified: no reactions UI.
        if (!isDailyCapsuleViewer && storyId != null && isAuthenticated)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  appTheme.blackCustom.withAlpha(153),
                  appTheme.transparentCustom,
                ],
              ),
            ),
            child: StoryReactionsWidget(
              storyId: storyId,
              onReactionAdded: () {},
            ),
          ),
        if (caption != null && caption.isNotEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  appTheme.blackCustom.withAlpha(153),
                  appTheme.transparentCustom,
                ],
              ),
            ),
            child: Text(
              caption,
              style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                  .copyWith(color: appTheme.whiteCustom),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${(difference.inDays / 7).floor()}w ago';
      }
    } catch (_) {
      return '';
    }
  }

  Widget _buildBottomRightControls() {
    final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';
    final showVolumeButton = mediaType == 'video' &&
        _currentVideoController != null &&
        _isCurrentVideoInitialized;

    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    final storyOwnerId = _currentStoryData?['user_id'] as String?;
    final canDelete =
        currentUserId != null && storyOwnerId != null && currentUserId == storyOwnerId;

    Widget circleButton({
      required Future<void> Function() onTapAsync,
      required IconData icon,
      required double iconSize,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          if (_isAnyModalOpen) return;
          if (_isTransitioning) return;
          if (_tapLocked) return;

          _lockTapBriefly();

          await onTapAsync();
        },
        child: Container(
          width: 44.h,
          height: 44.h,
          decoration: BoxDecoration(
            color: appTheme.blackCustom.withAlpha(128),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: iconSize.h,
          ),
        ),
      );
    }

    Widget spacer() => SizedBox(height: 12.h);

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canDelete) ...[
              circleButton(
                onTapAsync: () async {
                  await _confirmAndDeleteCurrentStory();
                },
                icon: Icons.delete_outline,
                iconSize: 24,
              ),
              spacer(),
            ],
            if (showVolumeButton) ...[
              circleButton(
                onTapAsync: () async {
                  _toggleMute();
                },
                icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                iconSize: 24,
              ),
              spacer(),
            ],
            circleButton(
              onTapAsync: () async {
                await _showMoreOptions();
              },
              icon: Icons.more_vert,
              iconSize: 26,
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // ACTIONS (placeholders preserved, but modal gating is fixed)
  // =========================

  Future<void> _confirmAndDeleteCurrentStory() async {
    // If your real implementation shows a bottom sheet / dialog,
    // it MUST set _isAnyModalOpen while it's open, like this:
    final wasPausedBefore = _isPaused;

    _pausePlaybackForModal();
    _safeSetState(() => _isAnyModalOpen = true);

    try {
      final bool? confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withAlpha(180),
        builder: (_) {
          return Container(
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              color: appTheme.gray_900_01,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delete story?',
                    style: TextStyleHelper.instance.body16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context, false),
                          buttonStyle: CustomButtonStyle.outlineDark,
                          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                        ),
                      ),
                      SizedBox(width: 10.h),
                      Expanded(
                        child: CustomButton(
                          text: 'Delete',
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          buttonStyle: CustomButtonStyle.fillPrimary,
                          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (confirm != true) return;

      final storyId = _storyIds.isNotEmpty ? _storyIds[_currentIndex] : _initialStoryId;
      if (storyId == null || storyId.trim().isEmpty) return;

      final ok = await UserProfileService.instance.deleteStory(storyId);
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Delete failed'),
              backgroundColor: appTheme.gray_900_01,
            ),
          );
        }
        return;
      }

      // If this viewer was opened from Daily Capsule, clear the entry's story_id reference too.
      try {
        final bool isDailyCapsuleViewer =
            (_feedType ?? '').trim().toLowerCase() == 'daily_capsule';
        if (isDailyCapsuleViewer) {
          final client = SupabaseService.instance.client;
          final userId = client?.auth.currentUser?.id;
          if (client != null && userId != null) {
            await client
                .from('daily_capsule_entries')
                .update({'story_id': null, 'memory_id': null})
                .eq('user_id', userId)
                .eq('story_id', storyId);
          }
        }
      } catch (_) {
        // best-effort
      }

      // Remove story from local viewer list and navigate appropriately.
      final idx = _storyIds.indexOf(storyId);
      if (idx >= 0) {
        _storyIds.removeAt(idx);
        if (_storyIds.isEmpty) {
          await _performHardMediaReset();
          if (mounted) Navigator.pop(context);
          return;
        }

        if (_currentIndex >= _storyIds.length) {
          _currentIndex = _storyIds.length - 1;
        }
        _initialStoryId = _storyIds[_currentIndex];

        // Reset controller to keep PageView in sync with the new list.
        final old = _pageController;
        _pageController = PageController(initialPage: _currentIndex);
        try {
          old?.dispose();
        } catch (_) {}

        await _performHardMediaReset();
        await _loadStoryAtIndex(_currentIndex);
      } else {
        // Fallback: just close
        await _performHardMediaReset();
        if (mounted) Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deleted'),
            backgroundColor: appTheme.gray_900_01,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        _safeSetState(() => _isAnyModalOpen = false);
        _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
      }
    }
  }

// ✅ COPY/PASTE: Replace your existing _showMoreOptions() with this one.
// This matches the OLD bottom sheet style (radius, bg, padding, icons, spacing)
// AND guarantees playback stays paused while the sheet is open AND while Share/Report flows are active.

  Future<void> _showMoreOptions() async {
    final wasPausedBefore = _isPaused;

    _pausePlaybackForModal();
    _safeSetState(() => _isAnyModalOpen = true);

    bool actionSelected = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: appTheme.gray_900_02, // ✅ old
      barrierColor: Colors.black.withAlpha(180), // ✅ old
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)), // ✅ old
      ),
      builder: (sheetContext) {
        return Material(
          color: appTheme.gray_900_02, // ✅ ensure real surface (no "flat" look)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: EdgeInsets.all(20.h), // ✅ old
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ Share (with icon)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    minLeadingWidth: 28.h, // ✅ prevents iOS leading collapse
                    leading: Icon(
                      Icons.share_outlined,
                      color: appTheme.gray_50,
                    ),
                    title: Text(
                      'Share Story',
                      style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    onTap: () async {
                      actionSelected = true;
                      Navigator.pop(sheetContext);

                      // ✅ keep paused while share UI is happening
                      try {
                        await _shareStory();
                      } finally {
                        if (_isDisposed || !mounted) return;
                        _safeSetState(() => _isAnyModalOpen = false);
                        _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
                      }
                    },
                  ),

                  // ✅ Report (with icon)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    minLeadingWidth: 28.h,
                    leading: Icon(
                      Icons.report_outlined,
                      color: appTheme.gray_50,
                    ),
                    title: Text(
                      'Report Story',
                      style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    onTap: () async {
                      actionSelected = true;
                      Navigator.pop(sheetContext);

                      // ✅ keep paused while the report modal is open
                      try {
                        await _openReportStoryModal(wasPausedBefore: wasPausedBefore);
                      } finally {
                        if (_isDisposed || !mounted) return;
                        _safeSetState(() => _isAnyModalOpen = false);
                        _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
                      }
                    },
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      // ✅ If user dismissed the sheet (swipe down / tap outside) without choosing an action:
      if (!actionSelected && !_isDisposed && mounted) {
        _safeSetState(() => _isAnyModalOpen = false);
        _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
      }
    });
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return DateTime.now().toString().split(' ')[0];
    }

    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return DateTime.now().toString().split(' ')[0];
    }
  }
}