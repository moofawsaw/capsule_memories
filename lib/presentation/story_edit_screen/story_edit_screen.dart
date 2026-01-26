// lib/presentation/story_edit_screen/story_edit_screen.dart

import 'dart:io';
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import 'notifier/story_edit_notifier.dart';
import 'notifier/story_edit_state.dart';
import 'notifier/preupload_state.dart';
import '../../services/network_quality_service.dart';
import '../../services/daily_capsule_service.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';

class StoryEditScreen extends ConsumerStatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final String memoryId;
  final String memoryTitle;
  final String? categoryIcon;

  /// Optional: when set, this share completes the Daily Capsule for today.
  /// Valid values: 'instant_story' | 'memory_post'
  final String? dailyCapsuleCompletionType;

  /// Optional: override navigation after successful share.
  /// If provided, we will navigate to this route and clear the stack to root.
  final String? afterShareRouteName;
  final Object? afterShareRouteArgs;

  const StoryEditScreen({
    Key? key,
    required this.mediaPath,
    required this.isVideo,
    required this.memoryId,
    required this.memoryTitle,
    this.categoryIcon,
    this.dailyCapsuleCompletionType,
    this.afterShareRouteName,
    this.afterShareRouteArgs,
  }) : super(key: key);

  @override
  ConsumerState<StoryEditScreen> createState() => _StoryEditScreenState();
}

class _StoryEditScreenState extends ConsumerState<StoryEditScreen> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocus = FocusNode();

  VideoPlayerController? _videoController;

  String? _categoryIconUrl;
  DateTime? _createdAt;
  String? _locationName;
  bool _isLoadingMemoryDetails = true;

  String? _memoryVisibility;

  bool _showVideoControls = true;

  bool _didShare = false;
  bool _cleanupTriggered = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NetworkQualityService.prime();

      ref.read(storyEditProvider.notifier).initializeScreen(
        mediaPath: widget.mediaPath,
        isVideo: widget.isVideo,
        memoryId: widget.memoryId,
      );

      _fetchMemoryDetails();
      if (widget.isVideo) _initializeVideoPlayer();
    });

    _captionController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchMemoryDetails() async {
    try {
      setState(() => _isLoadingMemoryDetails = true);

      final client = SupabaseService.instance.client;
      if (client == null) return;

      final response = await client
          .from('memories')
          .select(
          'created_at, location_name, visibility, memory_categories(icon_url)')
          .eq('id', widget.memoryId)
          .single();

      final rawCategory = response['memory_categories'];

      Map<String, dynamic>? category;
      if (rawCategory is Map) {
        category = Map<String, dynamic>.from(rawCategory);
      }

      setState(() {
        _categoryIconUrl = category?['icon_url']?.toString();
        _createdAt = DateTime.tryParse(response['created_at']?.toString() ?? '');
        _locationName = response['location_name']?.toString();
        _memoryVisibility = response['visibility']?.toString();
        _isLoadingMemoryDetails = false;
      });
    } catch (_) {
      setState(() => _isLoadingMemoryDetails = false);
    }
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(File(widget.mediaPath));
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    await _videoController!.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String get _safeMemoryName =>
      widget.memoryTitle.trim().isEmpty ? 'Memory' : widget.memoryTitle;

  Future<void> _cleanupIfNeeded() async {
    if (_cleanupTriggered) return;
    _cleanupTriggered = true;

    if (_didShare) return;

    // Best-effort cleanup of preuploaded storage objects when user exits/cancels.
    if (widget.isVideo) {
      await ref.read(storyEditProvider.notifier).cancelPreuploadAndCleanup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyEditProvider);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop) return;
        await _cleanupIfNeeded();
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: state.isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: appTheme.deep_purple_A100,
            ),
          )
              : Stack(
            children: [
              _buildMediaPreview(),
              _buildTopOverlay(),
              _buildBottomOverlay(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Positioned.fill(
      child: widget.isVideo && _videoController != null
          ? _buildVideo()
          : Image.file(
        File(widget.mediaPath),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildVideo() {
    final vc = _videoController!;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: vc.value.size.width,
              height: vc.value.size.height,
              child: VideoPlayer(vc),
            ),
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _showVideoControls ? 1 : 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                vc.value.isPlaying ? vc.pause() : vc.play();
                _showVideoControls = !vc.value.isPlaying;
              });
            },
            child: Container(
              width: 62.sp,
              height: 62.sp,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(130),
                shape: BoxShape.circle,
              ),
              child: Icon(
                vc.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding:
        EdgeInsets.only(left: 12.w, right: 12.w, top: 10.h, bottom: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(220),
              Colors.black.withAlpha(120),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _roundIcon(
                  Icons.arrow_back_rounded,
                      () async {
                    await _cleanupIfNeeded();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
                Expanded(
                  child: Text(
                    'Post Story',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _roundIcon(
                  Icons.refresh_rounded,
                      () async {
                    await _cleanupIfNeeded();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _isLoadingMemoryDetails ? const SizedBox() : _memoryMetaCard(),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _cancelAndExitFlow(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      final name = route.settings.name;
      if (name == AppRoutes.appFeed) return true;
      if (name == AppRoutes.appMemories) return true;
      if (name == AppRoutes.appTimeline) return true;
      if (name == AppRoutes.appProfileUser) return true;
      return route.isFirst;
    });
  }

  Widget _memoryMetaCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildCategoryIcon(),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safeMemoryName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (_createdAt != null)
                          Text(
                            DateFormat('MMM d, yyyy').format(_createdAt!),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.sp,
                            ),
                          ),
                        if (_locationName != null) ...[
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _locationName!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildCategoryIcon() {
    final url = _categoryIconUrl?.trim() ?? '';
    if (url.isEmpty) {
      return Icon(Icons.category_rounded, size: 22.sp, color: Colors.white54);
    }

    final isSvg = url.toLowerCase().endsWith('.svg');

    return isSvg
        ? SvgPicture.network(
      url,
      width: 22.sp,
      height: 22.sp,
      placeholderBuilder: (_) => SizedBox(
        width: 22.sp,
        height: 22.sp,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      ),
    )
        : Image.network(
      url,
      width: 22.sp,
      height: 22.sp,
      errorBuilder: (_, __, ___) => Icon(
        Icons.category_rounded,
        size: 22.sp,
        color: Colors.white70,
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.sp,
        height: 40.sp,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(120),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomOverlay(StoryEditState state) {
    final showStatus =
        widget.isVideo && (state.preuploadState != PreuploadState.idle);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(240),
              Colors.black.withAlpha(140),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            if (showStatus) ...[
              _uploadStatusCard(state),
              SizedBox(height: 10.h),
            ],
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Share to $_safeMemoryName',
                leftIcon: Icons.ios_share_rounded,
                onPressed:
                state.isUploading ? null : () => _onShareStory(context),
                isDisabled: state.isUploading,
                isLoading: state.isUploading,
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your story will be added to the timeline for $_safeMemoryName.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadStatusCard(StoryEditState state) {
    String stage = state.uploadStage ?? '';
    if (stage.isEmpty) {
      switch (state.preuploadState) {
        case PreuploadState.uploading:
          stage = 'Uploading in background...';
          break;
        case PreuploadState.ready:
          stage = 'Ready to share';
          break;
        case PreuploadState.failed:
          stage = 'Upload failed';
          break;
        case PreuploadState.cancelled: // ✅ FIXED (was "canceled")
          stage = 'Cancelled';
          break;
        case PreuploadState.preparing:
          stage = 'Preparing upload...';
          break;
        case PreuploadState.idle:
          stage = '';
          break;
      }
    }

    final showThumb = widget.isVideo && state.thumbProgress > 0.0;
    final mediaPct =
    (state.mediaProgress * 100).clamp(0, 100).toStringAsFixed(0);
    final thumbPct =
    (state.thumbProgress * 100).clamp(0, 100).toStringAsFixed(0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.preuploadState == PreuploadState.failed &&
                  (state.preuploadError ?? '').isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  state.preuploadError!,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 10.h),
              _progressRow(
                label: 'Video',
                progress: state.mediaProgress,
                percentText: '$mediaPct%',
              ),
              if (showThumb) ...[
                SizedBox(height: 8.h),
                _progressRow(
                  label: 'Thumbnail',
                  progress: state.thumbProgress,
                  percentText: '$thumbPct%',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressRow({
    required String label,
    required double progress,
    required String percentText,
  }) {
    final p = progress.clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 72.w,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p == 0.0 ? null : p,
              minHeight: 7.h,
              backgroundColor: Colors.white.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(
                appTheme.deep_purple_A100,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          width: 44.w,
          child: Text(
            percentText,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onShareStory(BuildContext context) async {
    final notifier = ref.read(storyEditProvider.notifier);

    final storyId = await notifier.finalizeShare(
      memoryId: widget.memoryId,
      mediaPath: widget.mediaPath, // ✅ FIXED: required
      isVideo: widget.isVideo,     // ✅ FIXED: required
      caption: _captionController.text.trim(),
    );

    if (!mounted) return;

    final success = storyId != null && storyId.isNotEmpty;
    if (success) {
      _didShare = true;
    }

    // Daily Capsule completion hook
    if (success && widget.dailyCapsuleCompletionType != null) {
      try {
        await DailyCapsuleService.instance.completeWithStory(
          completionType: widget.dailyCapsuleCompletionType!,
          storyId: storyId,
          memoryId: widget.memoryId,
        );
      } catch (_) {
        // Best-effort; navigation should still happen.
      }
    }

    // Optional navigation override (used by Daily Capsule to avoid bouncing to timeline/feed)
    if (success && widget.afterShareRouteName != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        widget.afterShareRouteName!,
        (route) => route.isFirst,
        arguments: widget.afterShareRouteArgs,
      );
      return;
    }

    if (success && _memoryVisibility == 'private') {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.appTimeline,
            (route) => route.isFirst,
        arguments: {'memoryId': widget.memoryId},
      );
    } else {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}