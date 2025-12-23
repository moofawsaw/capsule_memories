import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_story_list.dart'
    show CustomStoryList, CustomStoryItem;
import '../../widgets/custom_story_viewer.dart' as story_viewer
    show CustomStoryViewer, CustomStoryItem;
import '../add_memory_upload_screen/add_memory_upload_screen.dart';
import 'notifier/memory_details_view_notifier.dart';

class MemoryDetailsViewScreen extends ConsumerStatefulWidget {
  MemoryDetailsViewScreen({Key? key}) : super(key: key);

  @override
  MemoryDetailsViewScreenState createState() => MemoryDetailsViewScreenState();
}

class MemoryDetailsViewScreenState
    extends ConsumerState<MemoryDetailsViewScreen> {
  @override
  Widget build(BuildContext context) {
    // This screen is rendered inside `AppShell`, which already provides a
    // `Scaffold` with a persistent header. To avoid duplicate app bars and
    // layout overflow issues, we render only the content here and make it
    // scrollable.
    return Container(
      color: appTheme.gray_900_02,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 18.h),
            _buildEventCard(context),
            SizedBox(height: 18.h),
            _buildTimelineSection(context),
            SizedBox(height: 20.h),
            _buildStoriesSection(context),
            SizedBox(height: 19.h),
            _buildStoriesList(context),
            SizedBox(height: 23.h),
            _buildActionButtons(context),
            _buildFooterMessage(context),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildEventCard(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 34.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        border: Border(
          bottom: BorderSide(
            color: appTheme.blue_gray_900,
            width: 1.h,
          ),
        ),
      ),
      child: Row(
        spacing: 16.h,
        children: [
          GestureDetector(
            onTap: () {
              NavigatorService.goBack();
            },
            child: CustomImageView(
              imagePath: ImageConstant.imgArrowLeft,
              height: 24.h,
              width: 24.h,
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(memoryDetailsViewNotifier.notifier).onEventOptionsTap();
            },
            child: Container(
              height: 36.h,
              width: 36.h,
              padding: EdgeInsets.all(6.h),
              decoration: BoxDecoration(
                color: appTheme.color41C124,
                borderRadius: BorderRadius.circular(18.h),
              ),
              child: CustomImageView(
                imagePath: ImageConstant.imgFrame13Red600,
                height: 24.h,
                width: 24.h,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h),
              child: Column(
                spacing: 6.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boyz Golf Trip',
                    style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 8.h),
                    child: Row(
                      spacing: 6.h,
                      children: [
                        Text(
                          'Sept 21, 2025',
                          style: TextStyleHelper
                              .instance.body12MediumPlusJakartaSans,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.h,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: appTheme.gray_900_03,
                            borderRadius: BorderRadius.circular(6.h),
                          ),
                          child: Row(
                            spacing: 4.h,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomImageView(
                                imagePath: ImageConstant.imgIcon14x14,
                                height: 14.h,
                                width: 14.h,
                              ),
                              Text(
                                'PUBLIC',
                                style: TextStyleHelper
                                    .instance.body12BoldPlusJakartaSans
                                    .copyWith(color: appTheme.deep_purple_A100),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 84.h,
            height: 36.h,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomImageView(
                    imagePath: ImageConstant.imgFrame2,
                    height: 36.h,
                    width: 36.h,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: CustomImageView(
                    imagePath: ImageConstant.imgFrame1,
                    height: 36.h,
                    width: 36.h,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomImageView(
                    imagePath: ImageConstant.imgEllipse81,
                    height: 36.h,
                    width: 36.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildTimelineSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 4.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appTheme.blue_gray_900,
            width: 1.h,
          ),
        ),
      ),
      child: Column(
        spacing: 38.h,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          story_viewer.CustomStoryViewer(
            storyItems: [
              story_viewer.CustomStoryItem(
                imagePath: ImageConstant.imgImage9,
                showPlayButton: true,
              ),
              story_viewer.CustomStoryItem(
                imagePath: ImageConstant.imgImage8,
                showPlayButton: true,
              ),
            ],
            profileImages: [
              ImageConstant.imgEllipse826x26,
              ImageConstant.imgFrame2,
            ],
            onStoryTap: (index) {
              NavigatorService.pushNamed(AppRoutes.appVideoCall);
            },
            onPlayButtonTap: (index) {
              NavigatorService.pushNamed(AppRoutes.appVideoCall);
            },
          ),
          _buildTimelineDetails(context),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildTimelineDetails(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Row(
            spacing: 78.h,
            children: [
              Column(
                spacing: 6.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dec 4',
                    style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  Text(
                    '3:18pm',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ],
              ),
              Column(
                spacing: 4.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tillsonburg, ON',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                  Text(
                    '21km',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ],
              ),
              Column(
                spacing: 6.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dec 4',
                    style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  Text(
                    '3:18am',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildStoriesSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 22.h),
      child: Text(
        'Stories (6)',
        style: TextStyleHelper.instance.body14BoldPlusJakartaSans
            .copyWith(color: appTheme.gray_50),
      ),
    );
  }

  /// Section Widget
  Widget _buildStoriesList(BuildContext context) {
    return CustomStoryList(
      storyItems: [
        CustomStoryItem(
          backgroundImage: ImageConstant.imgImage8202x116,
          profileImage: ImageConstant.imgFrame2,
          timestamp: '2 mins ago',
          navigateTo: '1398:6774',
        ),
        CustomStoryItem(
          backgroundImage: ImageConstant.imgImage8120x90,
          profileImage: ImageConstant.imgFrame1,
          timestamp: '2 mins ago',
          navigateTo: '1398:6774',
        ),
        CustomStoryItem(
          backgroundImage: ImageConstant.imgImage8,
          profileImage: ImageConstant.imgFrame48x48,
          timestamp: '2 mins ago',
          navigateTo: '1398:6774',
        ),
        CustomStoryItem(
          backgroundImage: ImageConstant.imgImg,
          profileImage: ImageConstant.imgEllipse842x42,
          timestamp: '2 mins ago',
          navigateTo: '1398:6774',
        ),
        CustomStoryItem(
          backgroundImage: ImageConstant.imgImage81,
          profileImage: ImageConstant.imgEllipse81,
          timestamp: '2 mins ago',
          navigateTo: '1398:6774',
        ),
      ],
      onStoryTap: (index) {
        NavigatorService.pushNamed(AppRoutes.appVideoCall);
      },
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22.h),
      child: Row(
        spacing: 18.h,
        children: [
          Expanded(
            child: CustomButton(
              text: 'Replay All',
              leftIcon: ImageConstant.imgIcon12,
              onPressed: () {
                ref.read(memoryDetailsViewNotifier.notifier).onReplayAllTap();
              },
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Add Media',
              leftIcon: ImageConstant.imgIcon13,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: AddMemoryUploadScreen(),
                  ),
                );
              },
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildFooterMessage(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 33.h, vertical: 14.h),
      child: Text(
        'You can still add photos and videos you captured during the memory window',
        textAlign: TextAlign.center,
        style: TextStyleHelper.instance.body14RegularPlusJakartaSans
            .copyWith(color: appTheme.blue_gray_300, height: 1.21),
      ),
    );
  }
}
