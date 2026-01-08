import 'dart:io';

import 'package:video_player/video_player.dart';

import '../../core/app_export.dart';
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
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyEditProvider.notifier).initializeScreen(widget.mediaPath);
      if (widget.isVideo) {
        _initializeVideoPlayer();
      }
    });
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
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyEditProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: state.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: appTheme.deep_purple_A100,
                ),
              )
            : Stack(
                children: [
                  // Video/Image Preview (full screen)
                  _buildMediaPreview(),

                  // Share to Memory Button (bottom)
                  _buildShareButton(context, state),
                ],
              ),
      ),
    );
  }

  /// Media preview showing the captured video/photo
  Widget _buildMediaPreview() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: Center(
          child: widget.isVideo && _videoController != null
              ? _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : CircularProgressIndicator(
                      color: appTheme.deep_purple_A100,
                    )
              : Image.file(
                  File(widget.mediaPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
        ),
      ),
    );
  }

  /// Share to Memory button positioned at bottom
  Widget _buildShareButton(BuildContext context, StoryEditState state) {
    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: 24.h,
      child: IgnorePointer(
        ignoring: state.isUploading,
        child: ElevatedButton(
          onPressed: state.isUploading ? null : () => _onShareStory(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: state.isUploading
                ? appTheme.deep_purple_A100.withAlpha(128)
                : appTheme.deep_purple_A100,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4,
          ),
          child: state.isUploading
              ? SizedBox(
                  height: 20.sp,
                  width: 20.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Share to Memory',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  /// Handle text overlay addition
  void _onTextTap() {
    // TODO: Implement text overlay UI
    print('🎨 Text tool tapped');
  }

  /// Handle sticker addition
  void _onStickersTap() {
    // TODO: Implement sticker picker UI
    print('🎨 Stickers tool tapped');
  }

  /// Handle drawing tool
  void _onDrawTap() {
    // TODO: Implement drawing canvas UI
    print('🎨 Draw tool tapped');
  }

  /// Handle music/audio selection
  void _onMusicTap() {
    // TODO: Implement music picker UI
    print('🎨 Music tool tapped');
  }

  /// Share story to memory
  Future<void> _onShareStory(BuildContext context) async {
    final notifier = ref.read(storyEditProvider.notifier);

    try {
      final success = await notifier.uploadAndShareStory(
        memoryId: widget.memoryId,
        mediaPath: widget.mediaPath,
        isVideo: widget.isVideo,
        caption: _captionController.text,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Story shared successfully!'),
              backgroundColor: appTheme.deep_purple_A100,
            ),
          );
          // Pop back to feed screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share story. Please try again.'),
              backgroundColor: appTheme.red_500,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error sharing story: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while sharing story'),
            backgroundColor: appTheme.red_500,
          ),
        );
      }
    }
  }
}
