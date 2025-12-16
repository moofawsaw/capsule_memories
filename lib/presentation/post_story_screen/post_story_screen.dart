import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_chip.dart';
import 'notifier/post_story_notifier.dart';

class PostStoryScreen extends ConsumerStatefulWidget {
  PostStoryScreen({Key? key}) : super(key: key);

  @override
  PostStoryScreenState createState() => PostStoryScreenState();
}

class PostStoryScreenState extends ConsumerState<PostStoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postStoryNotifier.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        appBar: _buildAppBar(context),
        body: Container(
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: 32.h, left: 16.h, right: 16.h),
                  child: Column(
                    children: [
                      SizedBox(height: 8.h),
                      _buildStoryContent(context),
                    ],
                  ),
                ),
              ),
              _buildBottomSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      layoutType: CustomAppBarLayoutType.titleWithLeading,
      leadingIcon: ImageConstant.imgIconGray5042x42,
      title: 'Post story',
      onLeadingTap: () => NavigatorService.goBack(),
      titleTextStyle: TextStyleHelper.instance.headline28ExtraBold,
      showBottomBorder: false,
    );
  }

  /// Section Widget
  Widget _buildStoryContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(postStoryNotifier);

        return Container(
          margin: EdgeInsets.only(top: 8.h, left: 6.h),
          width: double.infinity,
          height: 598.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildImageAndInfo(context),
              _buildToolsOverlay(context),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildImageAndInfo(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(postStoryNotifier);

        return Container(
          margin: EdgeInsets.only(right: 6.h),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            spacing: 24.h,
            children: [
              GestureDetector(
                onTap: () => _onTapStoryImage(context),
                child: Container(
                  width: double.infinity,
                  height: 542.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.h),
                  ),
                  child: CustomImageView(
                    imagePath: state.selectedImagePath ??
                        ImageConstant.imgImage8542x342,
                    width: double.infinity,
                    height: 542.h,
                    fit: BoxFit.cover,
                    radius: BorderRadius.circular(24.h),
                  ),
                ),
              ),
              _buildStoryDestination(context),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildStoryDestination(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Story will be posted to your',
          style: TextStyleHelper.instance.body12BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        CustomChip(
          iconPath: ImageConstant.imgVector,
          text: 'Vacation',
          padding: EdgeInsets.symmetric(horizontal: 6.h),
        ),
        SizedBox(width: 6.h),
        CustomImageView(
          imagePath: ImageConstant.imgEllipse826x26,
          width: 32.h,
          height: 32.h,
          fit: BoxFit.cover,
        ),
      ],
    );
  }

  /// Section Widget
  Widget _buildToolsOverlay(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(top: 164.h),
        width: double.infinity,
        child: Column(
          spacing: 38.h,
          children: [
            _buildToolOption(
              context,
              'Text',
              ImageConstant.imgIcons,
              () => _onTapTextTool(context),
            ),
            _buildToolOption(
              context,
              'Music',
              ImageConstant.imgIconsWhiteA700,
              () => _onTapMusicTool(context),
            ),
            _buildToolOption(
              context,
              'Draw',
              ImageConstant.imgIconsWhiteA70026x26,
              () => _onTapDrawTool(context),
            ),
            _buildToolOption(
              context,
              'Sticker',
              ImageConstant.imgIcons26x26,
              () => _onTapStickerTool(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildToolOption(
      BuildContext context, String text, String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.white_A700),
          ),
          SizedBox(width: 18.h),
          CustomImageView(
            imagePath: iconPath,
            width: 26.h,
            height: 26.h,
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildBottomSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 26.h),
      child: Column(
        children: [
          CustomButton(
            text: 'Share',
            width: double.infinity,
            onPressed: () => _onTapShare(context),
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            margin: EdgeInsets.only(bottom: 12.h),
          ),
        ],
      ),
    );
  }

  /// Handles story image tap for photo selection
  void _onTapStoryImage(BuildContext context) async {
    final hasPermission = await _requestCameraPermission();
    if (hasPermission) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        ref.read(postStoryNotifier.notifier).updateSelectedImage(image.path);
      }
    }
  }

  /// Requests camera permission
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  /// Handles text tool tap
  void _onTapTextTool(BuildContext context) {
    ref.read(postStoryNotifier.notifier).selectTool('text');
    // Add text overlay functionality here
  }

  /// Handles music tool tap
  void _onTapMusicTool(BuildContext context) {
    ref.read(postStoryNotifier.notifier).selectTool('music');
    // Add music selection functionality here
  }

  /// Handles draw tool tap
  void _onTapDrawTool(BuildContext context) {
    ref.read(postStoryNotifier.notifier).selectTool('draw');
    // Add drawing functionality here
  }

  /// Handles sticker tool tap
  void _onTapStickerTool(BuildContext context) {
    ref.read(postStoryNotifier.notifier).selectTool('sticker');
    // Add sticker selection functionality here
  }

  /// Handles share button tap
  void _onTapShare(BuildContext context) {
    ref.read(postStoryNotifier.notifier).shareStory();
  }
}
