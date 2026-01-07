import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/post_story_notifier.dart';

class PostStoryScreen extends ConsumerStatefulWidget {
  PostStoryScreen({Key? key}) : super(key: key);

  @override
  PostStoryScreenState createState() => PostStoryScreenState();
}

class PostStoryScreenState extends ConsumerState<PostStoryScreen> {
  String? memoryLocation;
  DateTime? memoryDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postStoryNotifier.notifier).initialize();

      // Get navigation arguments for memory location and date
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          memoryLocation = args['memoryLocation'] as String?;
          memoryDate = args['memoryDate'] as DateTime?;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        appBar: _buildAppBar(context) as PreferredSizeWidget,
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
  Widget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      layoutType: CustomAppBarLayoutType.titleWithLeading,
      leadingIcon: ImageConstant.imgIconGray5042x42,
      title: 'Post story',
      onLeadingTap: () => NavigatorService.goBack(),
      titleTextStyle: TextStyleHelper.instance.headline28ExtraBold,
      showBottomBorder: false,
    );
  }

  /// Helper Widget for Memory Info
  Widget? _buildMemoryInfo() {
    if (memoryLocation == null && memoryDate == null) return null;

    final locationText = memoryLocation ?? 'Unknown Location';
    final dateText = memoryDate != null
        ? '${memoryDate!.day}/${memoryDate!.month}/${memoryDate!.year}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (memoryLocation != null)
          Text(
            locationText,
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50.withAlpha(204)),
          ),
        if (memoryDate != null) SizedBox(height: 2.h),
        if (memoryDate != null)
          Text(
            dateText,
            style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50.withAlpha(153)),
          ),
      ],
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
            ],
          ),
        );
      },
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

  /// Handles share button tap
  void _onTapShare(BuildContext context) {
    ref.read(postStoryNotifier.notifier).shareStory();
  }

  /// Section Widget - Bottom section with share button
  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.h),
      child: ElevatedButton(
        onPressed: () => _onTapShare(context),
        child: Text('Share Story'),
      ),
    );
  }
}