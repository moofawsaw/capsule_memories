import 'dart:io';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import './notifier/story_edit_notifier.dart';

class StoryEditScreen extends ConsumerStatefulWidget {
  final String videoPath;
  final String memoryId;
  final String memoryTitle;
  final String? categoryIcon;

  const StoryEditScreen({
    Key? key,
    required this.videoPath,
    required this.memoryId,
    required this.memoryTitle,
    this.categoryIcon,
  }) : super(key: key);

  @override
  ConsumerState<StoryEditScreen> createState() => _StoryEditScreenState();
}

class _StoryEditScreenState extends ConsumerState<StoryEditScreen> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storyEditProvider.notifier).initializeScreen(widget.videoPath);
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
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

                  // Top Header
                  _buildTopHeader(),

                  // Right Side Editing Tools
                  _buildEditingTools(),

                  // Bottom Caption & Share Section
                  _buildBottomSection(),
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
          child: Image.file(
            File(widget.videoPath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }

  /// Top header with back button, memory name, and Next button
  Widget _buildTopHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(178),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(102),
                  shape: BoxShape.circle,
                ),
                child: CustomImageView(
                  imagePath: ImageConstant.imgArrowLeft,
                  height: 20.h,
                  width: 20.h,
                  color: appTheme.gray_50,
                ),
              ),
            ),

            // Memory name with category icon
            Row(
              children: [
                if (widget.categoryIcon != null)
                  CustomImageView(
                    imagePath: widget.categoryIcon!,
                    height: 20.h,
                    width: 20.h,
                    fit: BoxFit.contain,
                  ),
                SizedBox(width: 8.h),
                Text(
                  widget.memoryTitle,
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ],
            ),

            // Next/Share button
            Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(storyEditProvider);
                return GestureDetector(
                  onTap:
                      state.isUploading ? null : () => _onShareStory(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.h,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.deep_purple_A100,
                      borderRadius: BorderRadius.circular(20.h),
                    ),
                    child: state.isUploading
                        ? SizedBox(
                            height: 16.h,
                            width: 16.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  appTheme.gray_50),
                            ),
                          )
                        : Text(
                            'Next',
                            style: TextStyleHelper.instance.body14Bold
                                .copyWith(color: appTheme.gray_50),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Right side vertical editing tools
  Widget _buildEditingTools() {
    return Positioned(
      right: 16.h,
      top: 100.h,
      bottom: 200.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildEditingToolButton(
            icon: Icons.text_fields,
            label: 'Text',
            onTap: () => _onTextTap(),
          ),
          _buildEditingToolButton(
            icon: Icons.emoji_emotions_outlined,
            label: 'Stickers',
            onTap: () => _onStickersTap(),
          ),
          _buildEditingToolButton(
            icon: Icons.draw_outlined,
            label: 'Draw',
            onTap: () => _onDrawTap(),
          ),
          _buildEditingToolButton(
            icon: Icons.music_note,
            label: 'Music',
            onTap: () => _onMusicTap(),
          ),
        ],
      ),
    );
  }

  /// Individual editing tool button
  Widget _buildEditingToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(102),
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: appTheme.gray_50,
              size: 24.h,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyleHelper.instance.body10BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom section with caption input and share button
  Widget _buildBottomSection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(204),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption input
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(102),
                borderRadius: BorderRadius.circular(24.h),
              ),
              child: TextField(
                controller: _captionController,
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Add a caption...',
                  hintStyle: TextStyleHelper
                      .instance.body14MediumPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  ref.read(storyEditProvider.notifier).updateCaption(value);
                },
              ),
            ),

            SizedBox(height: 16.h),

            // Share to Memory button
            CustomButton(
              text: 'Share to Memory',
              width: double.infinity,
              onPressed: () => _onShareStory(context),
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          ],
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
        videoPath: widget.videoPath,
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
