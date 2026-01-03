import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_export.dart';
import '../../services/feed_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_image_view.dart';
import 'models/event_stories_view_model.dart';

class EventStoriesViewScreen extends ConsumerStatefulWidget {
  const EventStoriesViewScreen({Key? key}) : super(key: key);

  @override
  EventStoriesViewScreenState createState() => EventStoriesViewScreenState();
}

class EventStoriesViewScreenState extends ConsumerState<EventStoriesViewScreen>
    with SingleTickerProviderStateMixin {
  String? _initialStoryId;
  String?
      _feedType; // Track feed type: 'happening_now', 'trending', or 'memory'
  List<String> _storyIds = [];
  int _currentIndex = 0;
  int _startingIndex = 0; // Track where user started viewing from
  Map<String, dynamic>? _storyData;
  bool _isLoading = true;
  String? _errorMessage;
  final FeedService _feedService = FeedService();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  PageController? _pageController;

  // Timer animation controllers
  AnimationController? _timerController;
  bool _isPaused = false;
  bool _isMuted = false; // Track mute state
  static const Duration _imageDuration = Duration(seconds: 5);

  // Swipe gesture tracking
  double _dragStartY = 0.0;
  double _dragCurrentY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: _imageDuration,
    );

    _timerController?.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isPaused) {
        // Trigger vibration on progress bar completion
        _triggerHapticFeedback(HapticFeedbackType.light);
        _goToNextStory();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      // For memories feed, accept String ID but load ALL feed stories (not memory-specific)
      if (args is String) {
        print('🔍 DEBUG: Received story ID from memories feed: $args');
        _initialStoryId = args;
        _feedType =
            'latest_stories'; // Mark as latest stories feed (not memory-grouped)
        _loadAllLatestStories(); // Load entire feed array instead of memory-specific
      }
      // Check if feed context was passed (for happening now and other feeds)
      else if (args is FeedStoryContext) {
        print('🔍 DEBUG: Received FeedStoryContext');
        print('   Feed type: ${args.feedType}');
        print('   Story count: ${args.storyIds.length}');
        print('   Initial story: ${args.initialStoryId}');

        _feedType = args.feedType;
        _initialStoryId = args.initialStoryId;
        _storyIds = args.storyIds;

        // Find the index of the initial story
        _currentIndex = _storyIds.indexOf(args.initialStoryId);
        if (_currentIndex == -1) {
          print('⚠️ WARNING: Initial story not found in feed, defaulting to 0');
          _currentIndex = 0;
        }

        _startingIndex = _currentIndex;

        // Initialize PageController with the current index
        _pageController = PageController(initialPage: _currentIndex);

        // Load the initial story
        _loadStoryAtIndex(_currentIndex);

        print(
            '✅ DEBUG: Feed-based story viewer initialized at index $_currentIndex');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid story data provided';
        });
      }
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

      // Reset and stop timer
      _timerController?.stop();
      _timerController?.reset();

      // Dispose previous video controller if exists
      if (_videoController != null) {
        await _videoController!.pause();
        await _videoController!.dispose();
        _videoController = null;
        _isVideoInitialized = false;
      }

      final storyData = await _feedService.fetchStoryDetails(_storyIds[index]);

      if (storyData == null) {
        print('❌ ERROR: Story data is null for ID ${_storyIds[index]}');
        setState(() {
          _errorMessage = 'Story not found';
        });
        return;
      }

      setState(() {
        _storyData = storyData;
        _currentIndex = index;
        _isLoading = false;
        _isPaused = false;
      });

      // Initialize video player if media type is video
      final mediaType = storyData['media_type'] as String? ?? 'image';
      final mediaUrl = storyData['media_url'] as String?;

      print('📹 DEBUG: Media type: $mediaType, URL: $mediaUrl');

      if (mediaType == 'video' && mediaUrl != null && mediaUrl.isNotEmpty) {
        await _initializeVideoPlayer(mediaUrl);
      } else {
        // Start timer for images
        print('⏱️ DEBUG: Starting timer for image at index $index');
        _timerController?.duration = _imageDuration;
        _timerController?.forward();
      }

      print('✅ DEBUG: Successfully loaded story at index $index');
    } catch (e) {
      print('❌ ERROR loading story at index $index: $e');
      setState(() {
        _errorMessage = 'Error loading story: ${e.toString()}';
      });
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      // Set timer duration to video duration
      final videoDuration = _videoController!.value.duration;
      _timerController?.duration = videoDuration;

      // Apply mute state to video controller
      _videoController!.setVolume(_isMuted ? 0.0 : 1.0);

      _videoController!.setLooping(false);
      _videoController!.play();
      _timerController?.forward();

      // Listen for video completion
      _videoController!.addListener(() {
        if (_videoController!.value.position >=
            _videoController!.value.duration) {
          if (!_isPaused) {
            _goToNextStory();
          }
        }
      });

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('❌ ERROR initializing video player: $e');
      setState(() {
        _errorMessage = 'Failed to load video';
      });
    }
  }

  void _goToNextStory() {
    if (_currentIndex < _storyIds.length - 1) {
      // Trigger vibration on swipe/navigation
      _triggerHapticFeedback(HapticFeedbackType.medium);

      _pageController?.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last story reached - stop timer and keep viewer open
      // User must manually close via back button
      _timerController?.stop();
      _videoController?.pause();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _goToPreviousStory() {
    if (_currentIndex > 0) {
      // Trigger vibration on swipe/navigation
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
        _videoController?.pause();
      } else {
        _timerController?.forward();
        _videoController?.play();
      }
    });
  }

  void _toggleMute() {
    // Trigger vibration on volume toggle
    _triggerHapticFeedback(HapticFeedbackType.selection);

    setState(() {
      _isMuted = !_isMuted;
      _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  /// Triggers haptic vibration feedback
  Future<void> _triggerHapticFeedback(HapticFeedbackType type) async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (!hasVibrator) return;

      switch (type) {
        case HapticFeedbackType.light:
          // Light vibration for subtle feedback (progress transitions)
          await Vibration.vibrate(duration: 10);
          break;
        case HapticFeedbackType.medium:
          // Medium vibration for navigation (swipe gestures)
          await Vibration.vibrate(duration: 20);
          break;
        case HapticFeedbackType.selection:
          // Selection vibration for toggles (volume button)
          await Vibration.vibrate(duration: 15);
          break;
      }
    } catch (e) {
      // Silently fail if vibration is not supported or permission denied
      print('Vibration error: $e');
    }
  }

  /// Shares the current story with native share sheet
  Future<void> _shareStory() async {
    if (_storyData == null) {
      print('⚠️ WARNING: No story data available to share');
      return;
    }

    try {
      final userName = _storyData?['user_name'] as String? ?? 'Unknown User';
      final mediaUrl = _storyData?['media_url'] as String?;
      final memoryId = _storyData?['memory_id'] as String?;
      final caption = _storyData?['caption'] as String? ?? '';

      // Fetch memory name
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

      // Prepare share text
      final shareText = '''
Check out this story by $userName from "$memoryName"!

${caption.isNotEmpty ? caption : 'View their amazing memory on Capsule 📸'}

#CapsuleMemories #$memoryName
''';

      // Share with thumbnail if available
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        try {
          // Download thumbnail to temporary directory
          final response = await http.get(Uri.parse(mediaUrl));

          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final fileName =
                'story_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File('${tempDir.path}/$fileName');

            await file.writeAsBytes(response.bodyBytes);

            // Share with thumbnail
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
          // Fall through to share without thumbnail
        }
      }

      // Fallback: Share without thumbnail
      await Share.share(
        shareText,
        subject: 'Check out $userName\'s story on Capsule',
      );

      print('✅ DEBUG: Story shared successfully (text only)');
    } catch (e) {
      print('❌ ERROR sharing story: $e');
      // Show error feedback to user
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
    // CRITICAL: Stop video playback IMMEDIATELY before disposal
    _videoController?.pause();

    _timerController?.dispose();
    _videoController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

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

    if (_errorMessage != null || _storyData == null) {
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
          setState(() {
            _dragStartY = details.globalPosition.dy;
            _dragCurrentY = details.globalPosition.dy;
            _isDragging = true;
          });
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragCurrentY = details.globalPosition.dy;
          });
        },
        onVerticalDragEnd: (details) async {
          final dragDistance = _dragCurrentY - _dragStartY;
          final velocity = details.primaryVelocity ?? 0;

          // Close if dragged down by 100 pixels or with significant velocity
          if (dragDistance > 100 || velocity > 500) {
            // Trigger vibration on swipe down gesture
            _triggerHapticFeedback(HapticFeedbackType.medium);

            // CRITICAL FIX: Stop and dispose video BEFORE navigation
            await _stopAndDisposeVideo();

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
                  _buildStoryBackground(),
                  _buildGradientOverlays(),
                  // Tap zones positioned BELOW UI elements so they don't block interaction
                  _buildTapZones(),
                  // UI elements rendered ABOVE tap zones
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
                  // Volume control positioned ABOVE tap zones
                  _buildVolumeControl(),
                  // Explicitly position tappable user profile section on top layer
                  _buildTappableUserProfile(),
                ],
              );
            },
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
          // Reserve space for header (timer bars + top bar) - no tap detection here
          SizedBox(
              height: 120.h), // Increased from 100.h to fully clear header area
          // Tap zones only cover content area below header
          Expanded(
            child: GestureDetector(
              onLongPressStart: (_) {
                // Long press to pause
                setState(() {
                  _isPaused = true;
                  _timerController?.stop();
                  _videoController?.pause();
                });
              },
              onLongPressEnd: (_) {
                // Release to resume
                setState(() {
                  _isPaused = false;
                  _timerController?.forward();
                  _videoController?.play();
                });
              },
              child: Row(
                children: [
                  // Left tap zone - previous story
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _goToPreviousStory,
                      child: Container(
                        color: appTheme.transparentCustom,
                      ),
                    ),
                  ),
                  // Right tap zone - next story
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _goToNextStory,
                      child: Container(
                        color: appTheme.transparentCustom,
                      ),
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

                    // Simple progress logic - stories before current are filled, current shows timer, rest empty
                    if (index < _currentIndex) {
                      // Stories already viewed - filled completely
                      progress = 1.0;
                    } else if (index == _currentIndex) {
                      // Current story - show animated progress
                      progress = _timerController!.value;
                    } else {
                      // Future stories - empty
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

  Widget _buildStoryIndicators() {
    return Positioned(
      top: 50.h,
      left: 16.h,
      right: 16.h,
      child: Row(
        children: List.generate(
          _storyIds.length,
          (index) => Expanded(
            child: Container(
              height: 3.h,
              margin: EdgeInsets.symmetric(horizontal: 2.h),
              decoration: BoxDecoration(
                color: index <= _currentIndex
                    ? appTheme.whiteCustom
                    : appTheme.whiteCustom.withAlpha(77),
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryBackground() {
    final mediaUrl = _storyData?['media_url'] as String?;
    final mediaType = _storyData?['media_type'] as String? ?? 'image';

    print('🔍 DEBUG Story Media - URL: $mediaUrl, Type: $mediaType');

    if (mediaUrl == null || mediaUrl.isEmpty) {
      return Container(
        color: appTheme.gray_900_02,
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 64.h,
            color: appTheme.blue_gray_300,
          ),
        ),
      );
    }

    if (mediaType == 'video') {
      if (_videoController != null && _isVideoInitialized) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        );
      } else {
        return Container(
          color: appTheme.gray_900_02,
          child: Center(
            child: CircularProgressIndicator(color: appTheme.colorFF3A3A),
          ),
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
          child: CircularProgressIndicator(color: appTheme.colorFF3A3A),
        ),
      ),
      errorWidget: (context, url, error) {
        print('❌ ERROR loading image: $error');
        return Container(
          color: appTheme.gray_900_02,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 64.h,
                  color: appTheme.blue_gray_300,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Failed to load image',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
              ],
            ),
          ),
        );
      },
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
    final userName = _storyData?['user_name'] as String? ?? 'Unknown User';
    final userAvatar = _storyData?['user_avatar'] as String?;
    final userId = _storyData?['user_id'] as String?;

    return Positioned(
      top: MediaQuery.of(context).padding.top +
          20.h, // Position below timer bars
      left: 68
          .h, // Position after back button (40.h width + 16.h padding + 12.h gap)
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          print('🔍 DEBUG: User profile tapped - userId: $userId');
          if (userId != null && userId.isNotEmpty) {
            Navigator.pushNamed(
              context,
              AppRoutes.appProfileUser,
              arguments: {
                'userId': userId
              }, // ✅ FIX: Pass as Map instead of plain String
            );
          } else {
            print('⚠️ WARNING: userId is null or empty, cannot navigate');
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.h, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                    Text(
                      _formatTimeAgo(
                          _storyData?['created_at'] as String? ?? ''),
                      style: TextStyleHelper
                          .instance.body14RegularPlusJakartaSans
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
      child: Row(
        children: [
          CustomIconButton(
            iconPath: ImageConstant.imgArrowLeft,
            backgroundColor: appTheme.blackCustom.withAlpha(128),
            borderRadius: 20.h,
            height: 40.h,
            width: 40.h,
            padding: EdgeInsets.all(10.h),
            onTap: () async {
              // CRITICAL FIX: Stop and dispose video BEFORE navigation
              await _stopAndDisposeVideo();

              // Close modal route if opened as modal, otherwise pop normally
              if (ModalRoute.of(context)?.isActive == true) {
                Navigator.of(context).pop();
              }
            },
          ),
          Spacer(),
          CustomIconButton(
            iconPath: ImageConstant.imgIcon,
            backgroundColor: appTheme.blackCustom.withAlpha(128),
            borderRadius: 20.h,
            height: 40.h,
            width: 40.h,
            padding: EdgeInsets.all(10.h),
            onTap: () => _showMoreOptions(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    final caption = _storyData?['caption'] as String?;
    final location = _storyData?['location'] as String?;

    if (caption == null && location == null) {
      return SizedBox.shrink();
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (caption != null && caption.isNotEmpty)
            Text(
              caption,
              style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                  .copyWith(color: appTheme.whiteCustom),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (location != null && location.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16.h,
                  color: Colors.white70,
                ),
                SizedBox(width: 4.h),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
    final mediaType = _storyData?['media_type'] as String? ?? 'image';

    // Only show volume control for videos
    if (mediaType != 'video' ||
        _videoController == null ||
        !_isVideoInitialized) {
      return SizedBox.shrink();
    }

    return Positioned(
      right: 16.h,
      bottom: 100.h,
      child: GestureDetector(
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
    );
  }

  /// NEW METHOD: Properly stops and disposes video controller
  Future<void> _stopAndDisposeVideo() async {
    try {
      // Stop playback immediately
      if (_videoController != null) {
        await _videoController!.pause();
        await _videoController!.seekTo(Duration.zero); // Reset video position

        // Dispose controller
        await _videoController!.dispose();
        _videoController = null;
        _isVideoInitialized = false;
      }

      // Stop timer
      _timerController?.stop();
      _timerController?.reset();
    } catch (e) {
      print('⚠️ WARNING: Error stopping video: $e');
      // Continue with navigation even if there's an error
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.gray_900_02,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.report_outlined, color: appTheme.colorFF3A3A),
              title: Text(
                'Report Story',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.share_outlined, color: appTheme.whiteCustom),
              title: Text(
                'Share Story',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: appTheme.whiteCustom),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareStory(); // Trigger native share functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Enum for different haptic feedback types
enum HapticFeedbackType {
  light, // Subtle feedback for progress transitions
  medium, // Navigation feedback for swipes
  selection // Toggle feedback for button presses
}
