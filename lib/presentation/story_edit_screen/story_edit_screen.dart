import 'dart:io';
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import './notifier/story_edit_notifier.dart';

class StoryEditScreen extends ConsumerStatefulWidget {
  final String mediaPath;
  final bool isVideo;
  final String memoryId;
  final String memoryTitle;
  final String? categoryIcon;

  const StoryEditScreen({
    Key? key,
    required this.mediaPath,
    required this.isVideo,
    required this.memoryId,
    required this.memoryTitle,
    this.categoryIcon,
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

  // 🔥 NEW: Track memory visibility
  String? _memoryVisibility;

  bool _showVideoControls = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyEditProvider.notifier).initializeScreen(widget.mediaPath);
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

      // 🔥 MODIFIED: Added 'visibility' to the select query
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
        _createdAt =
            DateTime.tryParse(response['created_at']?.toString() ?? '');
        _locationName = response['location_name']?.toString();
        _memoryVisibility =
            response['visibility']?.toString(); // 🔥 NEW: Store visibility
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
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyEditProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: state.isLoading
            ? Center(
                child:
                    CircularProgressIndicator(color: appTheme.deep_purple_A100),
              )
            : Stack(
                children: [
                  _buildMediaPreview(),
                  _buildTopOverlay(),
                  _buildBottomOverlay(state),
                ],
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

  /// TOP OVERLAY
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
                _roundIcon(Icons.close_rounded,
                    () => Navigator.of(context).maybePop()),
                Expanded(
                  child: Text(
                    'Post Story',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                _roundIcon(Icons.refresh_rounded,
                    () => Navigator.of(context).maybePop()),
              ],
            ),
            SizedBox(height: 12.h),
            _isLoadingMemoryDetails ? const SizedBox() : _memoryMetaCard(),
          ],
        ),
      ),
    );
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
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        if (_createdAt != null)
                          Text(
                            DateFormat('MMM d, yyyy').format(_createdAt!),
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13.sp),
                          ),
                        if (_locationName != null) ...[
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _locationName!,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13.sp),
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

  /// 🔥 SVG-AWARE CATEGORY ICON
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
            errorBuilder: (_, __, ___) => Icon(Icons.category_rounded,
                size: 22.sp, color: Colors.white70),
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

  /// BOTTOM OVERLAY
  Widget _buildBottomOverlay(StoryEditState state) {
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
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Share to $_safeMemoryName',
                onPressed:
                    state.isUploading ? null : () => _onShareStory(context),
                isDisabled: state.isUploading,
                isLoading: state.isUploading, // 🔥 loading spinner
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

  Future<void> _onShareStory(BuildContext context) async {
    final notifier = ref.read(storyEditProvider.notifier);
    final success = await notifier.uploadAndShareStory(
      memoryId: widget.memoryId,
      mediaPath: widget.mediaPath,
      isVideo: widget.isVideo,
      caption: _captionController.text.trim(),
    );

    if (!mounted) return;

    // 🔥 NEW: Navigate to timeline for private memories after successful upload
    if (success && _memoryVisibility == 'private') {
      print(
          '✅ Private story posted - navigating to timeline for memory: ${widget.memoryId}');
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.appTimeline,
        (route) => route.settings.name == AppRoutes.appFeed,
        arguments: widget.memoryId,
      );
    } else {
      // For public memories or failed uploads, use original behavior
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}
