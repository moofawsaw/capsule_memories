// lib/presentation/memory_timeline_playback_screen/memory_timeline_playback_screen.dart
import 'dart:async';

import 'package:video_player/video_player.dart';

import '../../core/app_export.dart';
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
  ProviderSubscription<MemoryTimelinePlaybackState>? _playbackSub;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Timer? _controlsTimer;

  // ✅ NEW: Volume toggle state for playback screen
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(memoryTimelinePlaybackNotifier.notifier)
          .loadMemoryPlayback(widget.memoryId);

      _showControls = true;
      _fadeController.forward();

      final isPlaying =
          ref.read(memoryTimelinePlaybackNotifier).isPlaying ?? false;
      if (isPlaying) _startControlsTimer();

      // ✅ Apply initial volume once playback loads
      _applyVolumeToCurrentController();
    });

    // ✅ MUST use listenManual outside build()
    _playbackSub = ref.listenManual<MemoryTimelinePlaybackState>(
      memoryTimelinePlaybackNotifier,
          (prev, next) {
        // ✅ If controller/story changes, re-apply mute state
        final prevStoryId = prev?.currentStory?.storyId;
        final nextStoryId = next.currentStory?.storyId;
        if (prevStoryId != nextStoryId) {
          _applyVolumeToCurrentController();
        }

        final wasPlaying = prev?.isPlaying ?? false;
        final isPlaying = next.isPlaying ?? false;

        if (wasPlaying == isPlaying) return;

        if (!isPlaying) {
          // Paused: always show overlay + cancel auto-hide
          _controlsTimer?.cancel();
          _controlsTimer = null;

          if (mounted) {
            setState(() => _showControls = true);
            _fadeController.forward();
          }
        } else {
          // Playing: show overlay briefly then auto-hide
          if (mounted) {
            setState(() => _showControls = true);
            _fadeController.forward();
          }
          _startControlsTimer();
        }
      },
    );
  }

  // ✅ New: image badge under the top countdown/progress pill
  Widget _buildImageStoryBadge(MemoryTimelinePlaybackState state) {
    final story = state.currentStory;
    if (story == null) return const SizedBox.shrink();

    // Treat anything not video as image for this badge.
    final isImage = story.mediaType != 'video';
    if (!isImage) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(999.h),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image,
            color: Colors.white.withAlpha(220),
            size: 14.h,
          ),
          SizedBox(width: 6.h),
          Text(
            'IMAGE',
            style: TextStyle(
              color: Colors.white.withAlpha(235),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: cinema-mode subtitle above thumbnails row
  Widget _buildCinemaOrderSubtitle(MemoryTimelinePlaybackState state) {
    final stories = state.stories ?? [];
    if (stories.isEmpty) return const SizedBox.shrink();

    // If your state ever exposes a sort choice, you can branch here later.
    const label = 'Playing in chronological order (first posted → last)';

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.swap_vert,
            color: Colors.white.withAlpha(170),
            size: 14.h,
          ),
          SizedBox(width: 6.h),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(170),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playbackSub?.close();
    _controlsTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      final isPlaying =
          ref.read(memoryTimelinePlaybackNotifier).isPlaying ?? false;

      // ✅ Only auto-hide overlay while playing
      if (isPlaying && _showControls) {
        setState(() => _showControls = false);
        _fadeController.reverse();
      }
    });
  }

  Future<void> _toggleControls() async {
    final state = ref.read(memoryTimelinePlaybackNotifier);
    final isPlaying = state.isPlaying ?? false;

    // Always show controls on tap
    if (!_showControls) {
      setState(() => _showControls = true);
      _fadeController.forward();
    }

    // If playing, restart auto-hide countdown
    if (isPlaying) {
      _startControlsTimer();
    }

    // If paused, keep overlay visible (no timer)
  }

  // ✅ NEW: Toggle mute + apply to current video controller
  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _applyVolumeToCurrentController();
  }

  // ✅ NEW: Apply current mute state to the active video controller (if any)
  Future<void> _applyVolumeToCurrentController() async {
    final notifier = ref.read(memoryTimelinePlaybackNotifier.notifier);
    final controller = notifier.currentVideoController;
    if (controller == null) return;

    // If not initialized yet, wait a microtask and try once.
    if (!controller.value.isInitialized) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final retry = notifier.currentVideoController;
      if (retry == null || !retry.value.isInitialized) return;
      await retry.setVolume(_isMuted ? 0.0 : 1.0);
      return;
    }

    await controller.setVolume(_isMuted ? 0.0 : 1.0);
  }

  String _formatCountdown(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 24 * 60 * 60);
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryTimelinePlaybackNotifier);
    final isLoading = state.isLoading ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () async => await _toggleControls(),
        onDoubleTap: () {
          ref
              .read(memoryTimelinePlaybackNotifier.notifier)
              .toggleFavorite(state.currentStoryIndex ?? 0);
        },
        child: Stack(
          children: [
            _buildMainContent(context, state),

            // ✅ ALWAYS show story progress bar + countdown at the very top
            // (independent of controls hidden/shown)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10.h,
              left: 16.h,
              right: 16.h,
              child: _buildTopStoryProgress(context, state),
            ),

            // ✅ NEW: Image badge (top-right) under the countdown/progress pill
            Positioned(
              top: MediaQuery.of(context).padding.top + 10.h + 46.h,
              right: 16.h,
              child: _buildImageStoryBadge(state),
            ),

            if (_showControls) _buildTopOverlay(context, state),
            if (_showControls) _buildBottomOverlay(context, state),
            if (_showControls) _buildPlaybackControls(context, state),

            _buildTimelineScrubber(context, state),

            if (_showFilters) _buildFilterPanel(context, state),

            // Author badge – ONLY in full screen (controls hidden)
            if (!_showControls)
              Positioned(
                left: 16.h,
                bottom: 28.h, // adjust if it overlaps your bottom UI
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: 1.0,
                  child: _buildAuthorBadge(state),
                ),
              ),

            if (isLoading) _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryThumbnailsRow(MemoryTimelinePlaybackState state) {
    final stories = state.stories ?? [];
    if (stories.isEmpty) return const SizedBox.shrink();

    final currentIndex = state.currentStoryIndex ?? 0;

    return SizedBox(
      height: 62.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 2.h),
        itemCount: stories.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.h),
        itemBuilder: (context, index) {
          final story = stories[index];
          final isCurrent = index == currentIndex;

          final thumb = (story.thumbnailUrl ?? story.imageUrl ?? '').trim();

          return InkWell(
            onTap: () {
              ref
                  .read(memoryTimelinePlaybackNotifier.notifier)
                  .jumpToStory(index);
            },
            borderRadius: BorderRadius.circular(10.h),
            child: Container(
              width: 56.h,
              height: 56.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.h),
                border: Border.all(
                  color: isCurrent
                      ? appTheme.deep_purple_A100
                      : Colors.white.withAlpha(35),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9.h),
                child: thumb.isNotEmpty
                    ? CustomImageView(
                  imagePath: thumb,
                  fit: BoxFit.cover,
                  width: 56.h,
                  height: 56.h,
                )
                    : Container(
                  color: Colors.white.withAlpha(20),
                  alignment: Alignment.center,
                  child: Icon(
                    story.mediaType == 'video'
                        ? Icons.videocam
                        : Icons.image,
                    color: Colors.white.withAlpha(160),
                    size: 20.h,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ New: the always-visible diminishing bar + countdown (top)
  Widget _buildTopStoryProgress(
      BuildContext context, MemoryTimelinePlaybackState state) {
    final progress = (state.storyProgress ?? 0.0).clamp(0.0, 1.0);
    final remaining = state.storyRemaining ?? Duration.zero;
    final total = state.storyTotal ?? Duration.zero;

    // If you want “diminishing” (shrinking) bar, use (1 - progress)
    final diminishingValue = (1.0 - progress).clamp(0.0, 1.0);

    // Hide until we have a story loaded
    if (state.currentStory == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(999.h),
      ),
      child: Row(
        children: [
          // countdown
          Text(
            _formatCountdown(remaining),
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 10.h),
          // bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999.h),
              child: LinearProgressIndicator(
                value: diminishingValue,
                backgroundColor: Colors.white.withAlpha(20),
                valueColor: AlwaysStoppedAnimation<Color>(
                  appTheme.deep_purple_A100,
                ),
                minHeight: 6.h,
              ),
            ),
          ),
          SizedBox(width: 10.h),
          // total (optional)
          Text(
            _formatCountdown(total),
            style: TextStyle(
              color: Colors.white.withAlpha(170),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

    if (currentStory.mediaType == 'video' && currentStory.videoUrl != null) {
      return _buildVideoPlayer();
    } else if (currentStory.imageUrl != null) {
      return _buildImageDisplay(currentStory.imageUrl!);
    }

    return const Center(
      child: Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
    );
  }

  Widget _buildVideoPlayer() {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryTimelinePlaybackNotifier);
        final notifier = ref.read(memoryTimelinePlaybackNotifier.notifier);
        final controller = notifier.currentVideoController;

        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ Ensure current mute state is applied once controller is ready
        // (this is safe; it only sets volume to 0 or 1)
        controller.setVolume(_isMuted ? 0.0 : 1.0);

        final key = ValueKey<String>(
          state.currentStory?.storyId ?? 'story_${state.currentStoryIndex ?? 0}',
        );

        return Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: KeyedSubtree(
              key: key,
              child: VideoPlayer(controller),
            ),
          ),
        );
      },
    );
  }

  // ✅ Updated: Author badge with timestamp underneath
  Widget _buildAuthorBadge(MemoryTimelinePlaybackState state) {
    final story = state.currentStory;
    if (story == null) return const SizedBox.shrink();

    final name = (story.contributorName ?? 'Unknown').trim();
    final avatarUrl = (story.contributorAvatar ?? '').trim();
    final timestamp = (story.timestamp ?? '').trim();

    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(90),
        borderRadius: BorderRadius.circular(999.h),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(999.h),
            child: avatarUrl.isNotEmpty
                ? CustomImageView(
              imagePath: avatarUrl,
              width: 26.h,
              height: 26.h,
              fit: BoxFit.cover,
            )
                : Container(
              width: 26.h,
              height: 26.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(30),
              ),
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 8.h),

          // Name (left)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 140.h),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(width: 12.h),
          if (timestamp.isNotEmpty) ...[
            Text(
              '•',
              style: TextStyle(
                color: Colors.white.withAlpha(120),
                fontSize: 12.sp,
              ),
            ),
            SizedBox(width: 8.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 160.h),
              child: Text(
                timestamp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withAlpha(170),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageDisplay(String imageUrl) {
    return SizedBox(
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
    final notifier = ref.read(memoryTimelinePlaybackNotifier.notifier);

    // ✅ Only show volume button when we have a usable video controller
    final showVolumeButton = (state.currentStory?.mediaType == 'video') &&
        (notifier.currentVideoController != null);

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
                CustomIconButton(
                  icon: Icons.arrow_back,
                  backgroundColor: Colors.black26,
                  iconColor: Colors.white,
                  height: 40.h,
                  width: 40.h,
                  onTap: () => Navigator.pop(context),
                ),
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

                // ✅ Right side: cast + volume (stacked)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconButton(
                      icon: Icons.cast,
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
                    if (showVolumeButton) ...[
                      SizedBox(height: 10.h),
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
                  ],
                ),
              ],
            ),
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
          padding: EdgeInsets.fromLTRB(20.h, 14.h, 20.h, 40.h),
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
              // ✅ NEW subtitle above thumbnails (cinema mode context)
              _buildCinemaOrderSubtitle(state),

              _buildStoryThumbnailsRow(state),

              SizedBox(height: 12.h),

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
                          appTheme.deep_purple_A100,
                        ),
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
            CustomIconButton(
              icon: Icons.chevron_left,
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
            CustomIconButton(
              icon: (state.isPlaying ?? false)
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              backgroundColor: appTheme.deep_purple_A100,
              iconColor: Colors.white,
              iconSize: 36.h,
              height: 72.h,
              width: 72.h,
              onTap: () {
                ref
                    .read(memoryTimelinePlaybackNotifier.notifier)
                    .togglePlayPause();
              },
            ),
            CustomIconButton(
              icon: Icons.chevron_right,
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
      duration: const Duration(milliseconds: 300),
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
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      ref
                          .read(memoryTimelinePlaybackNotifier.notifier)
                          .toggleTimelineScrubber();
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: state.stories?.length ?? 0,
                itemBuilder: (context, index) {
                  final story = state.stories![index];
                  final isCurrentStory = index == (state.currentStoryIndex ?? 0);

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
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() => _showFilters = false);
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
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