import 'package:video_player/video_player.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_image_view.dart';
import './models/memory_timeline_playback_model.dart';
import './notifier/memory_timeline_playback_notifier.dart';
import './notifier/memory_timeline_playback_state.dart';

class MemoryTimelinePlaybackScreen extends ConsumerStatefulWidget {
  final String memoryId;

  const MemoryTimelinePlaybackScreen({
    Key? key,
    required this.memoryId,
  }) : super(key: key);

  @override
  MemoryTimelinePlaybackScreenState createState() =>
      MemoryTimelinePlaybackScreenState();
}

class MemoryTimelinePlaybackScreenState
    extends ConsumerState<MemoryTimelinePlaybackScreen>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  bool _showFilters = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade animation for auto-hiding controls
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Load memory playback data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(memoryTimelinePlaybackNotifier.notifier)
          .loadMemoryPlayback(widget.memoryId);
      _fadeController.forward();
    });

    // Auto-hide controls after 3 seconds
    _startControlsTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startControlsTimer() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
          _fadeController.reverse();
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _fadeController.forward();
        _startControlsTimer();
      } else {
        _fadeController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryTimelinePlaybackNotifier);
    final isLoading = state.isLoading ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTap: () {
          ref
              .read(memoryTimelinePlaybackNotifier.notifier)
              .toggleFavorite(state.currentStoryIndex ?? 0);
        },
        child: Stack(
          children: [
            // Main content area - full screen story display
            _buildMainContent(context, state),

            // Top overlay - memory info (auto-hide)
            if (_showControls) _buildTopOverlay(context, state),

            // Bottom overlay - progress bar (auto-hide)
            if (_showControls) _buildBottomOverlay(context, state),

            // Playback controls (auto-hide)
            if (_showControls) _buildPlaybackControls(context, state),

            // Timeline scrubber (collapsible)
            _buildTimelineScrubber(context, state),

            // Filter panel (slide-in)
            if (_showFilters) _buildFilterPanel(context, state),

            // Loading indicator
            if (isLoading) _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, MemoryTimelinePlaybackState state) {
    final currentStory = state.currentStory;

    if (currentStory == null) {
      return Center(
        child: Text(
          'No stories available',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
      );
    }

    // Display image or video based on media type
    if (currentStory.mediaType == 'video' && currentStory.videoUrl != null) {
      return _buildVideoPlayer(currentStory.videoUrl!);
    } else if (currentStory.imageUrl != null) {
      return _buildImageDisplay(currentStory.imageUrl!);
    }

    return Center(
      child: Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    return Consumer(
      builder: (context, ref, _) {
        final notifier = ref.read(memoryTimelinePlaybackNotifier.notifier);
        final controller = notifier.currentVideoController;

        if (controller == null || !controller.value.isInitialized) {
          return Center(child: CircularProgressIndicator());
        }

        return Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        );
      },
    );
  }

  Widget _buildImageDisplay(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomImageView(
        imagePath: imageUrl,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildTopOverlay(
      BuildContext context, MemoryTimelinePlaybackState state) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.h, 40.h, 20.h, 20.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(179),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                CustomIconButton(
                  iconPath: ImageConstant.imgArrowLeft,
                  backgroundColor: Colors.black26,
                  iconColor: Colors.white,
                  height: 40.h,
                  width: 40.h,
                  onTap: () => Navigator.pop(context),
                ),
                // Memory info
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.memoryTitle ?? 'Memory Playback',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${(state.currentStoryIndex ?? 0) + 1} of ${state.totalStories ?? 0}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Chromecast button
                CustomIconButton(
                  iconPath: ImageConstant.imgShare,
                  backgroundColor: state.isChromecastConnected ?? false
                      ? appTheme.deep_purple_A100
                      : Colors.black26,
                  iconColor: Colors.white,
                  height: 40.h,
                  width: 40.h,
                  onTap: () {
                    ref
                        .read(memoryTimelinePlaybackNotifier.notifier)
                        .toggleChromecast();
                  },
                ),
              ],
            ),
            // Replay All button
            SizedBox(height: 16.h),
            InkWell(
              onTap: () {
                ref.read(memoryTimelinePlaybackNotifier.notifier).replayAll();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 10.h),
                decoration: BoxDecoration(
                  color: appTheme.deep_purple_A100,
                  borderRadius: BorderRadius.circular(20.h),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.replay,
                      color: Colors.white,
                      size: 20.h,
                    ),
                    SizedBox(width: 8.h),
                    Text(
                      'Replay All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(
      BuildContext context, MemoryTimelinePlaybackState state) {
    final progress = (state.currentStoryIndex ?? 0) / (state.totalStories ?? 1);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.fromLTRB(20.h, 20.h, 20.h, 40.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withAlpha(179),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Story timestamp
              if (state.currentStory?.timestamp != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Text(
                    state.currentStory!.timestamp!,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              // Progress bar
              Row(
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                  SizedBox(width: 8.h),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.h),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            appTheme.deep_purple_A100),
                        minHeight: 4.h,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(
      BuildContext context, MemoryTimelinePlaybackState state) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 40.h,
          children: [
            // Skip backward
            CustomIconButton(
              iconPath: ImageConstant.imgArrowLeft,
              backgroundColor: Colors.black54,
              iconColor: Colors.white,
              height: 56.h,
              width: 56.h,
              onTap: () {
                ref
                    .read(memoryTimelinePlaybackNotifier.notifier)
                    .skipBackward();
              },
            ),
            // Play/Pause
            CustomIconButton(
              iconPath: state.isPlaying ?? false
                  ? ImageConstant.imgPlayCircle
                  : ImageConstant.imgPlayCircle,
              backgroundColor: appTheme.deep_purple_A100,
              iconColor: Colors.white,
              height: 72.h,
              width: 72.h,
              onTap: () {
                ref
                    .read(memoryTimelinePlaybackNotifier.notifier)
                    .togglePlayPause();
              },
            ),
            // Skip forward
            CustomIconButton(
              iconPath: ImageConstant.imgArrowLeft,
              backgroundColor: Colors.black54,
              iconColor: Colors.white,
              height: 56.h,
              width: 56.h,
              onTap: () {
                ref.read(memoryTimelinePlaybackNotifier.notifier).skipForward();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineScrubber(
      BuildContext context, MemoryTimelinePlaybackState state) {
    final isExpanded = state.isTimelineScrubberExpanded ?? false;

    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      left: isExpanded ? 0 : -300.h,
      top: 0,
      bottom: 0,
      width: 300.h,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.gray_900_01.withAlpha(242),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16.h),
            bottomRight: Radius.circular(16.h),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Timeline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      ref
                          .read(memoryTimelinePlaybackNotifier.notifier)
                          .toggleTimelineScrubber();
                    },
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white24, height: 1),
            // Story thumbnails
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: state.stories?.length ?? 0,
                itemBuilder: (context, index) {
                  final story = state.stories![index];
                  final isCurrentStory =
                      index == (state.currentStoryIndex ?? 0);

                  return _buildTimelineStoryItem(
                      context, story, index, isCurrentStory);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStoryItem(BuildContext context, PlaybackStoryModel story,
      int index, bool isCurrent) {
    return InkWell(
      onTap: () {
        ref.read(memoryTimelinePlaybackNotifier.notifier).jumpToStory(index);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
        padding: EdgeInsets.all(8.h),
        decoration: BoxDecoration(
          color: isCurrent
              ? appTheme.deep_purple_A100.withAlpha(51)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.h),
          border: Border.all(
            color: isCurrent ? appTheme.deep_purple_A100 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6.h),
              child: CustomImageView(
                imagePath: story.thumbnailUrl ?? story.imageUrl,
                width: 48.h,
                height: 48.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 12.h),
            // Story info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.contributorName ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    story.timestamp ?? '',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            // Play indicator
            if (isCurrent)
              Icon(
                Icons.play_circle_filled,
                color: appTheme.deep_purple_A100,
                size: 24.h,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(
      BuildContext context, MemoryTimelinePlaybackState state) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: 280.h,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.gray_900_01.withAlpha(242),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.h),
            bottomLeft: Radius.circular(16.h),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters & Sort',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() => _showFilters = false);
                    },
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white24, height: 1),
            // Filter options
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.h),
                children: [
                  _buildFilterSection('Sort By', [
                    'Chronological',
                    'Contributors',
                    'Reactions',
                  ]),
                  SizedBox(height: 16.h),
                  _buildFilterSection('Content Type', [
                    'All',
                    'Photos',
                    'Videos',
                  ]),
                  SizedBox(height: 16.h),
                  _buildFilterSection('Time Period', [
                    'All',
                    'Morning',
                    'Afternoon',
                    'Evening',
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        ...options.map((option) => _buildFilterOption(option)),
      ],
    );
  }

  Widget _buildFilterOption(String option) {
    return InkWell(
      onTap: () {
        // Apply filter
        ref.read(memoryTimelinePlaybackNotifier.notifier).applyFilter(option);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              option,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
            Icon(Icons.radio_button_unchecked,
                color: Colors.white30, size: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: CircularProgressIndicator(
          color: appTheme.deep_purple_A100,
        ),
      ),
    );
  }
}
