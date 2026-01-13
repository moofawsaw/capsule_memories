// lib/presentation/event_stories_view_screen/event_stories_view_screen.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/feed_story_context.dart';
import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../services/feed_service.dart';
import '../../services/supabase_service.dart';
import '../../utils/storage_utils.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/story_reactions.dart';
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
    with TickerProviderStateMixin {
  String? _initialStoryId;
  String? _feedType;
  List<String> _storyIds = [];
  int _currentIndex = 0;
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

  PageController? _pageController;

  // Timer animation controllers
  AnimationController? _timerController;
  bool _isPaused = false;
  bool _isMuted = false;
  static const Duration _imageDuration = Duration(seconds: 5);

  // CROSSFADE ANIMATION CONTROLLER
  AnimationController? _crossfadeController;
  Animation<double>? _crossfadeAnimation;
  bool _isTransitioning = false;

  // Swipe gesture tracking
  double _dragStartY = 0.0;
  double _dragCurrentY = 0.0;
  bool _isDragging = false;

  // Memory category data
  String? _memoryCategoryName;
  String? _memoryCategoryIcon;
  String? _memoryId;

  // Prefetching state
  bool _isPrefetching = false;

  // ✅ Prevent tap-through when any modal/sheet is open
  bool _isAnyModalOpen = false;

  @override
  void initState() {
    super.initState();

    // Initialize timer controller
    _timerController = AnimationController(
      vsync: this,
      duration: _imageDuration,
    );

    // Initialize crossfade controller (100-150ms as per requirements)
    _crossfadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120), // 120ms for smooth crossfade
    );

    _crossfadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _crossfadeController!, curve: Curves.easeInOut),
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
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is String) {
        print('🔍 DEBUG: Received story ID from memories feed: $args');
        _initialStoryId = args;
        _feedType = 'latest_stories';
        _loadAllLatestStories();
      } else if (args is FeedStoryContext) {
        print('🔍 DEBUG: Received FeedStoryContext');
        _feedType = args.feedType;
        _initialStoryId = args.initialStoryId;
        _storyIds = args.storyIds;
        _currentIndex = _storyIds.indexOf(args.initialStoryId);

        if (_currentIndex == -1) {
          _currentIndex = 0;
        }

        _startingIndex = _currentIndex;
        _pageController = PageController(initialPage: _currentIndex);
        _loadStoryAtIndex(_currentIndex);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid story data provided';
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markStoryAsViewed();
    });
  }

  /// NEW METHOD: Load all latest stories from feed (not grouped by memory)
  Future<void> _loadAllLatestStories() async {
    if (_initialStoryId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No story ID provided';
      });
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Fetch ALL latest stories from database (chronological order, not memory-grouped)
      _storyIds = await _feedService.fetchLatestStoryIds();

      print('🔍 DEBUG: Fetched ${_storyIds.length} stories from latest feed');
      print('🔍 DEBUG: Story IDs: $_storyIds');
      print('🔍 DEBUG: Initial story ID: $_initialStoryId');

      // Find the index of the initial story in the FULL feed array
      _currentIndex = _storyIds.indexOf(_initialStoryId!);

      print('🔍 DEBUG: Initial story index in full feed: $_currentIndex');

      if (_currentIndex == -1) {
        print(
            '⚠️ WARNING: Initial story not found in feed, defaulting to index 0');
        _currentIndex = 0;
      }

      // Store starting index for progress bar calculation
      _startingIndex = _currentIndex;

      // Initialize PageController with the current index
      _pageController = PageController(initialPage: _currentIndex);

      // Load the initial story
      await _loadStoryAtIndex(_currentIndex);

      print(
          '✅ DEBUG: Initial story loaded at index $_currentIndex (starting from $_startingIndex) with ${_storyIds.length} total stories');
    } catch (e) {
      print('❌ ERROR loading latest stories: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading stories: ${e.toString()}';
      });
    }
  }

  // Keep existing _loadStoriesForMemory for backward compatibility but not used for /memories feed
  Future<void> _loadStoriesForMemory() async {
    if (_initialStoryId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No story ID provided';
      });
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Get memory_id from the initial story
      final storyWithMemory = await _getStoryWithMemoryId(_initialStoryId!);
      final memoryId = storyWithMemory?['memory_id'] as String?;

      if (memoryId == null) {
        // Fallback to single story if memory_id not available
        _storyIds = [_initialStoryId!];
        _currentIndex = 0;
        _startingIndex = 0;
      } else {
        // Fetch all stories from this memory
        _storyIds = await _feedService.fetchMemoryStoryIds(memoryId);

        print(
            '🔍 DEBUG: Fetched ${_storyIds.length} stories for memory $memoryId');
        print('🔍 DEBUG: Story IDs: $_storyIds');
        print('🔍 DEBUG: Initial story ID: $_initialStoryId');

        // Find the index of the initial story
        _currentIndex = _storyIds.indexOf(_initialStoryId!);

        print('🔍 DEBUG: Initial story index: $_currentIndex');

        if (_currentIndex == -1) {
          print(
              '⚠️ WARNING: Initial story not found in list, defaulting to index 0');
          _currentIndex = 0;
        }

        // Store starting index for progress bar calculation
        _startingIndex = _currentIndex;
      }

      // Initialize PageController with the current index
      _pageController = PageController(initialPage: _currentIndex);

      // Load the initial story
      await _loadStoryAtIndex(_currentIndex);

      print(
          '✅ DEBUG: Initial story loaded at index $_currentIndex (starting from $_startingIndex)');
    } catch (e) {
      print('❌ ERROR loading stories for memory: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading stories: ${e.toString()}';
      });
    }
  }

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
      print('Error fetching story memory_id: $e');
      return null;
    }
  }

  Future<void> _loadStoryAtIndex(int index) async {
    if (index < 0 || index >= _storyIds.length) {
      print(
          '⚠️ WARNING: Invalid story index $index (total: ${_storyIds.length})');
      return;
    }

    try {
      print(
          '🔄 DEBUG: Loading story at index $index (ID: ${_storyIds[index]})');

      // Reset timer
      _timerController?.stop();
      _timerController?.reset();

      final storyId = _storyIds[index];

      // Check if we have prefetched next story data
      Map<String, dynamic>? storyData;
      VideoPlayerController? videoController;
      bool isVideoInitialized = false;

      if (_nextStoryData != null && _nextStoryData!['id'] == storyId) {
        print('✅ DEBUG: Using prefetched data for story $storyId');
        storyData = _nextStoryData;
        videoController = _nextVideoController;
        isVideoInitialized = _isNextVideoInitialized;

        // Clear next slot
        _nextStoryData = null;
        _nextVideoController = null;
        _isNextVideoInitialized = false;
      } else {
        print('🔄 DEBUG: Fetching story data from service');
        storyData = await _feedService.fetchStoryDetails(storyId);
      }

      if (storyData == null) {
        print('❌ ERROR: Story data is null for ID $storyId');
        setState(() {
          _errorMessage = 'Story not found';
        });
        return;
      }

      // Fetch memory category information
      final memoryId = storyData['memory_id'] as String?;
      if (memoryId != null) {
        await _fetchMemoryCategory(memoryId);
      }

      // CRITICAL: If this is first load, set as current directly
      if (_currentStoryData == null) {
        _currentStoryData = storyData;
        _currentVideoController = videoController;
        _isCurrentVideoInitialized = isVideoInitialized;

        setState(() {
          _currentIndex = index;
          _isLoading = false;
          _isPaused = false;
          _initialStoryId = storyId;
        });

        await _markStoryAsViewed();

        // Initialize video if needed
        final mediaType = storyData['media_type'] as String? ?? 'image';
        final mediaUrl = storyData['media_url'] as String?;

        if (mediaType == 'video' && mediaUrl != null && mediaUrl.isNotEmpty) {
          if (_currentVideoController == null || !_isCurrentVideoInitialized) {
            await _initializeVideoPlayer(mediaUrl, isCurrentSlot: true);
          } else {
            _currentVideoController!.setVolume(_isMuted ? 0.0 : 1.0);
            _currentVideoController!.play();

            final videoDuration = _currentVideoController!.value.duration;
            _timerController?.duration = videoDuration;
            _timerController?.forward();
          }
        } else {
          _timerController?.duration = _imageDuration;
          _timerController?.forward();
        }

        // Prefetch next story
        _prefetchNextStory(index);
        return;
      }

      // DUAL-SLOT CROSSFADE TRANSITION
      _nextStoryData = storyData;
      _nextVideoController = videoController;
      _isNextVideoInitialized = isVideoInitialized;

      // Initialize video in next slot if needed and not prefetched
      final mediaType = storyData['media_type'] as String? ?? 'image';
      final mediaUrl = storyData['media_url'] as String?;

      if (mediaType == 'video' && mediaUrl != null && mediaUrl.isNotEmpty) {
        if (_nextVideoController == null || !_isNextVideoInitialized) {
          await _initializeVideoPlayer(mediaUrl, isCurrentSlot: false);
        }
      } else if (mediaType == 'image' &&
          mediaUrl != null &&
          mediaUrl.isNotEmpty) {
        // Ensure image is precached before transition
        await precacheImage(CachedNetworkImageProvider(mediaUrl), context);
      }

      // Perform crossfade transition
      await _performCrossfadeTransition(index, storyId);

      print('✅ DEBUG: Successfully transitioned to story at index $index');
    } catch (e) {
      print('❌ ERROR loading story at index $index: $e');
      setState(() {
        _errorMessage = 'Error loading story: ${e.toString()}';
      });
    }
  }

  /// CRITICAL: Performs Instagram Reels-style crossfade transition
  Future<void> _performCrossfadeTransition(int newIndex, String storyId) async {
    if (_isTransitioning) {
      print('⚠️ WARNING: Already transitioning, skipping');
      return;
    }

    try {
      _isTransitioning = true;

      _crossfadeController?.reset();

      setState(() {
        _currentIndex = newIndex;
        _initialStoryId = storyId;
      });

      await _crossfadeController?.forward();

      await _swapMediaSlots();

      _isTransitioning = false;

      await _markStoryAsViewed();

      // Start playback on new current story
      final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';

      if (mediaType == 'video' &&
          _currentVideoController != null &&
          _isCurrentVideoInitialized) {
        _currentVideoController!.setVolume(_isMuted ? 0.0 : 1.0);
        _currentVideoController!.play();

        final videoDuration = _currentVideoController!.value.duration;
        _timerController?.duration = videoDuration;
        _timerController?.forward();
      } else {
        _timerController?.duration = _imageDuration;
        _timerController?.forward();
      }

      _prefetchNextStory(newIndex);

      print('✅ DEBUG: Crossfade transition completed');
    } catch (e) {
      print('❌ ERROR during crossfade transition: $e');
      _isTransitioning = false;
    }
  }

  /// Swaps next media slot to current and disposes old current
  Future<void> _swapMediaSlots() async {
    if (_currentVideoController != null) {
      await _currentVideoController!.pause();
      await _currentVideoController!.dispose();
    }

    _currentStoryData = _nextStoryData;
    _currentVideoController = _nextVideoController;
    _isCurrentVideoInitialized = _isNextVideoInitialized;

    _nextStoryData = null;
    _nextVideoController = null;
    _isNextVideoInitialized = false;

    setState(() {});

    print('✅ DEBUG: Media slots swapped, old media disposed');
  }

  /// Prefetch next story media in background
  Future<void> _prefetchNextStory(int currentIndex) async {
    if (_isPrefetching || currentIndex >= _storyIds.length - 1) {
      return;
    }

    try {
      _isPrefetching = true;
      final nextIndex = currentIndex + 1;
      final nextStoryId = _storyIds[nextIndex];

      print(
          '🔄 DEBUG: Prefetching next story at index $nextIndex (ID: $nextStoryId)');

      final nextStoryData = await _feedService.fetchStoryDetails(nextStoryId);

      if (nextStoryData == null) {
        print('⚠️ WARNING: Failed to prefetch story $nextStoryId');
        _isPrefetching = false;
        return;
      }

      final mediaType = nextStoryData['media_type'] as String? ?? 'image';
      final mediaUrl = nextStoryData['media_url'] as String?;

      if (mediaType == 'video' && mediaUrl != null && mediaUrl.isNotEmpty) {
        print('📹 DEBUG: Prefetching video controller');
        final prefetchController =
        VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
        await prefetchController.initialize();
        prefetchController.setLooping(false);

        _nextVideoController = prefetchController;
        _isNextVideoInitialized = true;

        print('✅ DEBUG: Video prefetched successfully');
      } else if (mediaType == 'image' &&
          mediaUrl != null &&
          mediaUrl.isNotEmpty) {
        print('🖼️ DEBUG: Prefetching image');
        await precacheImage(CachedNetworkImageProvider(mediaUrl), context);
        print('✅ DEBUG: Image prefetched successfully');
      }

      _nextStoryData = nextStoryData;
      _isPrefetching = false;

      print('✅ DEBUG: Story $nextStoryId prefetched successfully');
    } catch (e) {
      print('⚠️ WARNING: Error prefetching next story: $e');
      _isPrefetching = false;
    }
  }

  /// NEW METHOD: Fetch memory category data
  Future<void> _fetchMemoryCategory(String memoryId) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final response = await client.from('memories').select('''
            id, 
            name,
            created_at,
            location,
            visibility,
            category_id, 
            memory_categories(name, icon_name)
          ''').eq('id', memoryId).single();

      final categoryData = response['memory_categories'];
      final iconName = categoryData?['icon_name'] as String?;

      setState(() {
        _memoryId = memoryId;
        _memoryCategoryName = categoryData?['name'] as String?;
        _memoryCategoryIcon = iconName != null
            ? StorageUtils.resolveMemoryCategoryIconUrl(iconName)
            : null;
      });

      if (_currentStoryData != null) {
        _currentStoryData!['memory_title'] = response['name'] as String?;
        _currentStoryData!['memory_date'] = response['created_at'] as String?;
        _currentStoryData!['memory_location'] = response['location'] as String?;
        _currentStoryData!['memory_visibility'] =
        response['visibility'] as String?;
      }

      print('✅ DEBUG: Fetched memory category - Name: $_memoryCategoryName');
      print('   - Icon Name: $iconName');
      print('   - Icon URL: $_memoryCategoryIcon');
      print('   - Memory Title: ${response['name']}');
    } catch (e) {
      print('⚠️ WARNING: Failed to fetch memory category: $e');
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
        _currentVideoController = controller;
        _isCurrentVideoInitialized = true;

        final videoDuration = controller.value.duration;
        _timerController?.duration = videoDuration;

        controller.play();
        _timerController?.forward();

        controller.addListener(() {
          if (controller.value.position >= controller.value.duration) {
            if (!_isPaused && !_isTransitioning && !_isAnyModalOpen) {
              _goToNextStory();
            }
          }
        });
      } else {
        _nextVideoController = controller;
        _isNextVideoInitialized = true;
      }

      setState(() {});

      print(
          '✅ DEBUG: Video initialized in ${isCurrentSlot ? 'current' : 'next'} slot');
    } catch (e) {
      print('❌ ERROR initializing video player: $e');
      setState(() {
        _errorMessage = 'Failed to load video';
      });
    }
  }

  void _goToNextStory() {
    if (_isAnyModalOpen) return;

    if (_currentIndex < _storyIds.length - 1) {
      _triggerHapticFeedback(HapticFeedbackType.medium);

      _pageController?.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _timerController?.stop();
      _currentVideoController?.pause();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _goToPreviousStory() {
    if (_isAnyModalOpen) return;

    if (_currentIndex > 0) {
      _triggerHapticFeedback(HapticFeedbackType.medium);

      _pageController?.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _togglePauseResume() {
    setState(() {
      _isPaused = !_isPaused;

      if (_isPaused) {
        _timerController?.stop();
        _currentVideoController?.pause();
      } else {
        _timerController?.forward();
        final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';
        if (mediaType == 'video' &&
            _currentVideoController != null &&
            _isCurrentVideoInitialized) {
          _currentVideoController?.play();
        }
      }
    });
  }

  void _toggleMute() {
    _triggerHapticFeedback(HapticFeedbackType.selection);

    setState(() {
      _isMuted = !_isMuted;
      _currentVideoController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  /// Triggers haptic vibration feedback
  Future<void> _triggerHapticFeedback(HapticFeedbackType type) async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (!hasVibrator) return;

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
    } catch (e) {
      print('Vibration error: $e');
    }
  }

  /// Shares the current story with native share sheet
  Future<void> _shareStory() async {
    if (_currentStoryData == null) {
      print('⚠️ WARNING: No story data available to share');
      return;
    }

    try {
      final userName =
          _currentStoryData?['user_name'] as String? ?? 'Unknown User';
      final mediaUrl = _currentStoryData?['media_url'] as String?;
      final memoryId = _currentStoryData?['memory_id'] as String?;
      final caption = _currentStoryData?['caption'] as String? ?? '';

      String memoryName = 'Memory';
      if (memoryId != null) {
        try {
          final client = SupabaseService.instance.client;
          final memoryData = await client
              ?.from('memories')
              .select('name')
              .eq('id', memoryId)
              .single();

          memoryName = memoryData?['name'] as String? ?? 'Memory';
        } catch (e) {
          print('⚠️ WARNING: Failed to fetch memory name: $e');
        }
      }

      final shareText = '''
Check out this story by $userName from "$memoryName"!

${caption.isNotEmpty ? caption : 'View their amazing memory on Capsule 📸'}

#CapsuleMemories #$memoryName
''';

      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(mediaUrl));

          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final fileName =
                'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File('${tempDir.path}/$fileName');

            await file.writeAsBytes(response.bodyBytes);

            await Share.shareXFiles(
              [XFile(file.path)],
              text: shareText,
              subject: 'Check out $userName\'s story on Capsule',
            );

            print('✅ DEBUG: Story shared successfully with thumbnail');
            return;
          }
        } catch (e) {
          print('⚠️ WARNING: Failed to share with thumbnail: $e');
        }
      }

      await Share.share(
        shareText,
        subject: 'Check out $userName\'s story on Capsule',
      );

      print('✅ DEBUG: Story shared successfully (text only)');
    } catch (e) {
      print('❌ ERROR sharing story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to share story',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.whiteCustom),
          ),
          backgroundColor: appTheme.colorFF3A3A,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _performHardMediaReset();
    _timerController?.dispose();
    _crossfadeController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _performHardMediaReset() {
    try {
      _timerController?.stop();
      _timerController?.reset();
      _crossfadeController?.stop();
      _crossfadeController?.reset();

      if (_currentVideoController != null) {
        _currentVideoController!.pause();
        _currentVideoController!.setVolume(0.0);
        _currentVideoController!.seekTo(Duration.zero);
        _currentVideoController!.removeListener(() {});
        _currentVideoController!.dispose();
        _currentVideoController = null;
        _isCurrentVideoInitialized = false;
      }

      if (_nextVideoController != null) {
        _nextVideoController!.pause();
        _nextVideoController!.setVolume(0.0);
        _nextVideoController!.seekTo(Duration.zero);
        _nextVideoController!.removeListener(() {});
        _nextVideoController!.dispose();
        _nextVideoController = null;
        _isNextVideoInitialized = false;
      }

      _currentStoryData = null;
      _nextStoryData = null;
      _isPrefetching = false;

      print(
          '✅ HARD RESET: All media players (dual slots) stopped and disposed');
    } catch (e) {
      print('⚠️ WARNING: Error during hard media reset: $e');
    }
  }

  /// Mark the current story as viewed in the database
  Future<void> _markStoryAsViewed() async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;

      if (currentUserId == null) {
        print(
            '⚠️ WARNING: No authenticated user, skipping story view tracking');
        return;
      }

      final currentStoryId = _initialStoryId;

      if (currentStoryId == null) {
        print('⚠️ WARNING: No current story ID available');
        return;
      }

      await client.from('story_views').upsert({
        'story_id': currentStoryId,
        'user_id': currentUserId,
        'viewed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'story_id,user_id');

      print('✅ SUCCESS: Marked story "$currentStoryId" as viewed');
    } catch (e) {
      print('❌ ERROR marking story as viewed: $e');
    }
  }

  // =========================
  // ✅ Modal helpers (pause/resume + prevent tap-through)
  // =========================

  void _pausePlaybackForModal() {
    _timerController?.stop();
    _currentVideoController?.pause();
  }

  void _resumePlaybackAfterModal({required bool wasPausedBefore}) {
    if (!mounted) return;
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

    _isAnyModalOpen = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows the sheet to grow and handle keyboard
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

    _isAnyModalOpen = false;
    _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
  }


  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Center(
          child: CircularProgressIndicator(color: appTheme.colorFF3A3A),
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
                onPressed: () => Navigator.pop(context),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: appTheme.blackCustom,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragStart: (details) {
          if (_isAnyModalOpen) return;
          setState(() {
            _dragStartY = details.globalPosition.dy;
            _dragCurrentY = details.globalPosition.dy;
            _isDragging = true;
          });
        },
        onVerticalDragUpdate: (details) {
          if (_isAnyModalOpen) return;
          setState(() {
            _dragCurrentY = details.globalPosition.dy;
          });
        },
        onVerticalDragEnd: (details) async {
          if (_isAnyModalOpen) return;

          final dragDistance = _dragCurrentY - _dragStartY;
          final velocity = details.primaryVelocity ?? 0;

          if (dragDistance > 100 || velocity > 500) {
            _triggerHapticFeedback(HapticFeedbackType.medium);
            _performHardMediaReset();
            Navigator.of(context).pop();
          }

          setState(() {
            _isDragging = false;
            _dragStartY = 0.0;
            _dragCurrentY = 0.0;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0,
            _isDragging
                ? (_dragCurrentY - _dragStartY).clamp(0, double.infinity)
                : 0,
            0,
          ),
          child: PageView.builder(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _storyIds.length,
            onPageChanged: (index) {
              _loadStoryAtIndex(index);
            },
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildDualMediaLayers(),
                  _buildGradientOverlays(),
                  _buildTapZones(),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildTimerBars(),
                        _buildTopBar(),
                        Spacer(),
                        _buildBottomInfo(),
                      ],
                    ),
                  ),
                  _buildTappableUserProfile(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// CRITICAL: Renders dual media layers with crossfade
  Widget _buildDualMediaLayers() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_currentStoryData != null)
          _buildMediaLayer(_currentStoryData!, _currentVideoController,
              _isCurrentVideoInitialized),
        if (_isTransitioning && _nextStoryData != null)
          FadeTransition(
            opacity: _crossfadeAnimation!,
            child: _buildMediaLayer(
                _nextStoryData!, _nextVideoController, _isNextVideoInitialized),
          ),
      ],
    );
  }

  /// Builds a single media layer (image or video)
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
      if (controller != null && isInitialized) {
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

  /// Builds transparent tap zones for story navigation
  Widget _buildTapZones() {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 120.h),
          Expanded(
            child: GestureDetector(
              onLongPressStart: (_) {
                if (_isAnyModalOpen) return;
                setState(() {
                  _isPaused = true;
                  _timerController?.stop();
                  _currentVideoController?.pause();
                });
              },
              onLongPressEnd: (_) {
                if (_isAnyModalOpen) return;
                setState(() {
                  _isPaused = false;
                  _timerController?.forward();

                  final mediaType =
                      _currentStoryData?['media_type'] as String? ?? 'image';
                  if (mediaType == 'video' &&
                      _currentVideoController != null &&
                      _isCurrentVideoInitialized) {
                    _currentVideoController?.play();
                  }
                });
              },
              child: Row(
                children: [
                  Expanded(
                    flex: 35,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_isAnyModalOpen) return;
                        _goToPreviousStory();
                      },
                      child: Container(color: appTheme.transparentCustom),
                    ),
                  ),
                  Expanded(
                    flex: 30,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_isAnyModalOpen) return;
                        _triggerHapticFeedback(HapticFeedbackType.selection);
                        _togglePauseResume();
                      },
                      child: Container(color: appTheme.transparentCustom),
                    ),
                  ),
                  Expanded(
                    flex: 35,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_isAnyModalOpen) return;
                        _goToNextStory();
                      },
                      child: Container(color: appTheme.transparentCustom),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBars() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 8.h),
      child: Row(
        children: List.generate(
          _storyIds.length,
              (index) {
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
          },
        ),
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
        Spacer(),
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

  /// Builds tappable user profile section positioned on top layer to ensure tap detection
  Widget _buildTappableUserProfile() {
    final userName =
        _currentStoryData?['user_name'] as String? ?? 'Unknown User';
    final userAvatar = _currentStoryData?['user_avatar'] as String?;
    final userId = _currentStoryData?['user_id'] as String?;
    final memoryTitle = _currentStoryData?['memory_title'] as String?;

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
              onTap: () {
                if (_isAnyModalOpen) return;
                print('🔍 DEBUG: User avatar tapped - userId: $userId');
                if (userId != null && userId.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.appProfileUser,
                    arguments: {'userId': userId},
                  );
                } else {
                  print('⚠️ WARNING: userId is null or empty, cannot navigate');
                }
              },
              child: Container(
                width: 40.h,
                height: 40.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: appTheme.whiteCustom, width: 2),
                ),
                child: ClipOval(
                  child: CustomImageView(
                    imagePath: userAvatar ?? ImageConstant.imgEllipse842x42,
                    fit: BoxFit.cover,
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
                  Text(
                    userName,
                    style: TextStyleHelper.instance.body16BoldPlusJakartaSans
                        .copyWith(color: appTheme.whiteCustom),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (memoryTitle != null && memoryTitle.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_isAnyModalOpen) return;
                        if (_memoryId != null && _currentStoryData != null) {
                          final navArgs = MemoryNavArgs(
                            memoryId: _memoryId!,
                            snapshot: MemorySnapshot(
                              title: memoryTitle,
                              date: _currentStoryData?['memory_date']
                              as String? ??
                                  _formatDate(_currentStoryData?['created_at']
                                  as String?),
                              location: _currentStoryData?['memory_location']
                              as String?,
                              categoryIcon: _memoryCategoryIcon,
                              participantAvatars: null,
                              isPrivate:
                              _currentStoryData?['memory_visibility'] ==
                                  'private',
                            ),
                          );

                          _performHardMediaReset();

                          NavigatorService.pushNamed(
                            AppRoutes.appTimeline,
                            arguments: navArgs,
                          );
                        }
                      },
                      child: Text(
                        memoryTitle,
                        style: TextStyleHelper
                            .instance.body14RegularPlusJakartaSans
                            .copyWith(
                          color: appTheme.whiteCustom.withAlpha(204),
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Text(
                    _formatTimeAgo(
                        _currentStoryData?['created_at'] as String? ?? ''),
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
    final hasCategoryBadge = _memoryCategoryName != null &&
        _memoryCategoryIcon != null &&
        _memoryId != null;

    final location = _currentStoryData?['location'] as String?;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
      child: Row(
        children: [
          Spacer(),
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
                  Icon(
                    Icons.location_on,
                    size: 14.h,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 4.h),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 100.w),
                    child: Text(
                      location,
                      style: TextStyleHelper
                          .instance.body12RegularPlusJakartaSans
                          .copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (hasCategoryBadge)
            GestureDetector(
              onTap: () async {
                if (_isAnyModalOpen) return;

                if (_memoryId != null && _currentStoryData != null) {
                  final navArgs = MemoryNavArgs(
                    memoryId: _memoryId!,
                    snapshot: MemorySnapshot(
                      title: _currentStoryData?['memory_title'] as String? ??
                          'Memory',
                      date: _currentStoryData?['memory_date'] as String? ??
                          _formatDate(
                              _currentStoryData?['created_at'] as String?),
                      location:
                      _currentStoryData?['memory_location'] as String?,
                      categoryIcon: _memoryCategoryIcon,
                      participantAvatars: null,
                      isPrivate:
                      _currentStoryData?['memory_visibility'] == 'private',
                    ),
                  );

                  _performHardMediaReset();

                  NavigatorService.pushNamed(
                    AppRoutes.appTimeline,
                    arguments: navArgs,
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
                decoration: BoxDecoration(
                  color: appTheme.blackCustom.withAlpha(153),
                  borderRadius: BorderRadius.circular(20.h),
                  border: Border.all(
                    color: appTheme.whiteCustom.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_memoryCategoryIcon != null)
                      CachedNetworkImage(
                        imageUrl: _memoryCategoryIcon!,
                        width: 20.h,
                        height: 20.h,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => SizedBox(
                          width: 20.h,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: appTheme.whiteCustom,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.category,
                          size: 20.h,
                          color: appTheme.whiteCustom,
                        ),
                      ),
                    SizedBox(width: 6.h),
                    Text(
                      _memoryCategoryName!,
                      style: TextStyleHelper
                          .instance.body14MediumPlusJakartaSans
                          .copyWith(color: appTheme.whiteCustom),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    final caption = _currentStoryData?['caption'] as String?;
    final storyId = _storyIds.isNotEmpty ? _storyIds[_currentIndex] : null;
    final isAuthenticated = Supabase.instance.client.auth.currentUser != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (storyId != null) _buildBottomRightControls(),
        SizedBox(height: 12.h),
        if (storyId != null && isAuthenticated)
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
              onReactionAdded: () {
                print('✅ Reaction added for story $storyId');
              },
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
    } catch (e) {
      return '';
    }
  }

  Widget _buildVolumeControl() {
    return SizedBox.shrink();
  }

  /// Bottom right vertical control stack (TikTok-style)
  /// Delete (only if owner) -> Ellipsis -> Volume (video only)
  Widget _buildBottomRightControls() {
    final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';
    final showVolumeButton = mediaType == 'video' &&
        _currentVideoController != null &&
        _isCurrentVideoInitialized;

    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    final storyOwnerId = _currentStoryData?['user_id'] as String?;
    final canDelete = currentUserId != null &&
        storyOwnerId != null &&
        currentUserId == storyOwnerId;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canDelete)
              GestureDetector(
                onTap: _confirmAndDeleteCurrentStory,
                child: Container(
                  width: 44.h,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: appTheme.blackCustom.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 24.h,
                  ),
                ),
              ),
            if (canDelete) SizedBox(height: 12.h),
            GestureDetector(
              onTap: _showMoreOptions,
              child: Container(
                width: 44.h,
                height: 44.h,
                decoration: BoxDecoration(
                  color: appTheme.blackCustom.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 26.h,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            if (showVolumeButton)
              GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  width: 44.h,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: appTheme.blackCustom.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 24.h,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteCurrentStory() async {
    final storyId = _initialStoryId;
    if (storyId == null || storyId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appTheme.gray_900_02,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.h),
          ),
          title: Text(
            'Delete story?',
            style: TextStyleHelper.instance.body16BoldPlusJakartaSans
                .copyWith(color: appTheme.whiteCustom),
          ),
          content: Text(
            'This will permanently delete this story.',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.whiteCustom.withAlpha(204)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.whiteCustom.withAlpha(204)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.colorFF3A3A),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    _timerController?.stop();
    _currentVideoController?.pause();

    final ok = await _deleteStoryById(storyId);

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete story',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.whiteCustom),
          ),
          backgroundColor: appTheme.colorFF3A3A,
          duration: Duration(seconds: 2),
        ),
      );

      if (!_isPaused) {
        _timerController?.forward();
        final mediaType = _currentStoryData?['media_type'] as String? ?? 'image';
        if (mediaType == 'video' &&
            _currentVideoController != null &&
            _isCurrentVideoInitialized) {
          _currentVideoController?.play();
        }
      }
      return;
    }

    final deletedIndex = _currentIndex;

    setState(() {
      _storyIds.removeWhere((id) => id == storyId);
    });

    if (_storyIds.isEmpty) {
      _performHardMediaReset();
      Navigator.of(context).pop();
      return;
    }

    final newIndex = deletedIndex.clamp(0, _storyIds.length - 1);

    _performHardMediaReset();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentIndex = newIndex;
      _startingIndex = newIndex;
    });

    _pageController?.jumpToPage(newIndex);
    await _loadStoryAtIndex(newIndex);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Story deleted',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.whiteCustom),
        ),
        backgroundColor: appTheme.blackCustom.withAlpha(220),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _deleteStoryById(String storyId) async {
    try {
      final client = Supabase.instance.client;

      final currentUserId = client.auth.currentUser?.id;
      final storyOwnerId = _currentStoryData?['user_id'] as String?;
      if (currentUserId == null ||
          storyOwnerId == null ||
          currentUserId != storyOwnerId) {
        print('⚠️ WARNING: User is not owner - blocking delete');
        return false;
      }

      final mediaUrl = _currentStoryData?['media_url'] as String?;

      try {
        await client.from('story_views').delete().eq('story_id', storyId);
      } catch (_) {}
      try {
        await client.from('story_reactions').delete().eq('story_id', storyId);
      } catch (_) {}

      await client.from('stories').delete().eq('id', storyId);

      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        await _tryDeleteMediaFromStorage(mediaUrl);
      }

      print('✅ SUCCESS: Deleted story $storyId');
      return true;
    } catch (e) {
      print('❌ ERROR deleting story $storyId: $e');
      return false;
    }
  }

  Future<void> _tryDeleteMediaFromStorage(String mediaUrl) async {
    try {
      final client = Supabase.instance.client;
      final uri = Uri.tryParse(mediaUrl);
      if (uri == null) return;

      final segments = uri.pathSegments;

      final objectIndex = segments.indexOf('object');
      if (objectIndex == -1 || objectIndex + 2 >= segments.length) return;

      final mode = segments[objectIndex + 1]; // public | sign
      if (mode != 'public' && mode != 'sign') return;

      final bucket = segments[objectIndex + 2];
      if (bucket.isEmpty) return;

      final objectPathSegments = segments.sublist(objectIndex + 3);
      if (objectPathSegments.isEmpty) return;

      final objectPath = objectPathSegments.join('/');

      await client.storage.from(bucket).remove([objectPath]);
      print('✅ SUCCESS: Deleted storage object $bucket/$objectPath');
    } catch (e) {
      print('⚠️ WARNING: Failed to delete storage media: $e');
    }
  }

  // ✅ Updated: opens options sheet, pauses immediately, resumes on close,
  // ✅ and opens Report as its own modal sheet (not route navigation).
  void _showMoreOptions() {
    final wasPausedBefore = _isPaused;

    _pausePlaybackForModal();
    setState(() {
      _isAnyModalOpen = true;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.gray_900_02,
      barrierColor: Colors.black.withAlpha(180),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
      ),
      builder: (sheetContext) => Container(
        padding: EdgeInsets.all(20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.report_outlined, color: appTheme.whiteCustom),
              title: Text(
                'Report Story',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: appTheme.whiteCustom),
              ),
              onTap: () async {
                // Close options sheet first
                Navigator.pop(sheetContext);

                // Open report modal after sheet closes
                await Future.delayed(const Duration(milliseconds: 80));
                if (!mounted) return;

                // Keep paused while report modal is up
                _pausePlaybackForModal();
                await _openReportStoryModal(wasPausedBefore: wasPausedBefore);
              },
            ),
            ListTile(
              leading: Icon(Icons.share_outlined, color: appTheme.whiteCustom),
              title: Text(
                'Share Story',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: appTheme.whiteCustom),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Future.delayed(const Duration(milliseconds: 40));
                if (!mounted) return;
                await _shareStory();
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isAnyModalOpen = false;
      });
      _resumePlaybackAfterModal(wasPausedBefore: wasPausedBefore);
    });
  }

  /// Format date for snapshot if memory_date not available
  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return DateTime.now().toString().split(' ')[0];
    }

    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return DateTime.now().toString().split(' ')[0];
    }
  }
}
