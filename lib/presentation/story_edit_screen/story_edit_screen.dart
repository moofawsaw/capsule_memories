import 'dart:io';

import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
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

  // Memory details
  String? _categoryName;
  String? _categoryIconUrl;
  DateTime? _createdAt;
  String? _locationName;
  bool _isLoadingMemoryDetails = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyEditProvider.notifier).initializeScreen(widget.mediaPath);
      _fetchMemoryDetails();
      if (widget.isVideo) {
        _initializeVideoPlayer();
      }
    });
  }

  Future<void> _fetchMemoryDetails() async {
    try {
      setState(() => _isLoadingMemoryDetails = true);

      final client = SupabaseService.instance.client;
      if (client == null) {
        print('❌ Supabase client not initialized');
        setState(() => _isLoadingMemoryDetails = false);
        return;
      }

      final response = await client
          .from('memories')
          .select(
              'title, created_at, location_name, category_id, memory_categories(name, icon_url)')
          .eq('id', widget.memoryId)
          .single();

      final categoryData = response['memory_categories'];
      setState(() {
        _categoryName = categoryData?['name'];
        _categoryIconUrl = categoryData?['icon_url'];
        _createdAt = DateTime.parse(response['created_at']);
        _locationName = response['location_name'];
        _isLoadingMemoryDetails = false;
      });
        } catch (e) {
      print('❌ Error fetching memory details: $e');
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

                  // Memory Details Header (top)
                  _buildMemoryDetailsHeader(),

                  // Share to Memory Button (bottom)
                  _buildShareButton(context, state),
                ],
              ),
      ),
    );
  }

  /// Memory details header showing name, category, creation date, and location
  Widget _buildMemoryDetailsHeader() {
    if (_isLoadingMemoryDetails) {
      return Positioned(
        top: 16.h,
        left: 16.w,
        right: 16.w,
        child: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(179),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Center(
            child: SizedBox(
              height: 20.sp,
              width: 20.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(appTheme.deep_purple_A100),
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      top: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(179),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Memory title
            Text(
              widget.memoryTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),

            // Category with icon
            if (_categoryName != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_categoryIconUrl != null)
                    Padding(
                      padding: EdgeInsets.only(right: 1.w),
                      child: Image.network(
                        _categoryIconUrl!,
                        width: 20.sp,
                        height: 20.sp,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.category,
                          size: 20.sp,
                          color: appTheme.deep_purple_A100,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      _categoryName!,
                      style: TextStyle(
                        color: appTheme.deep_purple_A100,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            SizedBox(height: 1.h),

            // Creation date and location
            Row(
              children: [
                // Creation date
                if (_createdAt != null) ...[
                  Icon(
                    Icons.calendar_today,
                    size: 14.sp,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    DateFormat('MMM d, yyyy').format(_createdAt!),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                  ),
                ],

                // Separator
                if (_createdAt != null && _locationName != null) ...[
                  SizedBox(width: 2.w),
                  Container(
                    width: 1,
                    height: 12.sp,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 2.w),
                ],

                // Location
                if (_locationName != null)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14.sp,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 1.w),
                        Flexible(
                          child: Text(
                            _locationName!,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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
