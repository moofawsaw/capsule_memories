import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_happening_now_section.dart';
import '../../widgets/custom_public_memories.dart';
import '../../widgets/custom_section_header.dart';
import 'notifier/memory_feed_dashboard_notifier.dart';

class MemoryFeedDashboardScreen extends ConsumerStatefulWidget {
  MemoryFeedDashboardScreen({Key? key}) : super(key: key);

  @override
  MemoryFeedDashboardScreenState createState() =>
      MemoryFeedDashboardScreenState();
}

class MemoryFeedDashboardScreenState
    extends ConsumerState<MemoryFeedDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: appTheme.gray_900_02,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  _buildCreateMemoryButton(context),
                  _buildHappeningNowSection(context),
                  _buildPublicMemoriesSection(context),
                  _buildTrendingStoriesHeader(context),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.fromLTRB(22.h, 26.h, 22.h, 24.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appTheme.blue_gray_900,
            width: 1.h,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgLogo,
            height: 26.h,
            width: 130.h,
            margin: EdgeInsets.only(bottom: 10.h),
          ),
          Spacer(),
          GestureDetector(
            onTap: () => onTapPlusButton(context),
            child: Container(
              height: 46.h,
              width: 46.h,
              padding: EdgeInsets.all(6.h),
              decoration: BoxDecoration(
                color: appTheme.color3BD81E,
                borderRadius: BorderRadius.circular(22.h),
              ),
              child: CustomImageView(
                imagePath: ImageConstant.imgFrame19,
                height: 34.h,
                width: 34.h,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onTapGalleryIcon(context),
            child: CustomImageView(
              imagePath: ImageConstant.imgIconGray50,
              height: 32.h,
              width: 32.h,
              margin: EdgeInsets.only(left: 18.h, bottom: 8.h),
            ),
          ),
          GestureDetector(
            onTap: () => onTapNotificationIcon(context),
            child: CustomImageView(
              imagePath: ImageConstant.imgIconGray5032x32,
              height: 32.h,
              width: 32.h,
              margin: EdgeInsets.only(left: 6.h, bottom: 8.h),
            ),
          ),
          GestureDetector(
            onTap: () => onTapProfileImage(context),
            child: Container(
              height: 50.h,
              width: 50.h,
              margin: EdgeInsets.only(left: 8.h, top: 22.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.h),
              ),
              child: CustomImageView(
                imagePath: ImageConstant.imgEllipse8DeepOrange100,
                height: 50.h,
                width: 50.h,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildCreateMemoryButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final notifier = ref.read(memoryFeedDashboardNotifier.notifier);

        return CustomButton(
          text: 'Create Memory',
          width: double.infinity,
          leftIcon: ImageConstant.imgIcon20x20,
          onPressed: () => onTapCreateMemory(context),
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
          margin: EdgeInsets.fromLTRB(20.h, 16.h, 20.h, 0.h),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildHappeningNowSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardNotifier);

        return CustomHappeningNowSection(
          sectionTitle: 'Happening Now',
          sectionIcon: ImageConstant.imgIconDeepPurpleA10022x22,
          stories: state.memoryFeedDashboardModel?.happeningNowStories
                  ?.cast<HappeningNowStoryData>() ??
              [], // Modified: Cast to proper type
          onStoryTap: (story) => onTapHappeningNowStory(context, story),
          margin: EdgeInsets.only(top: 22.h, left: 24.h),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildPublicMemoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardNotifier);

        return CustomPublicMemories(
          sectionTitle: 'Public Memories',
          sectionIcon: ImageConstant.imgIcon22x22,
          memories: state.memoryFeedDashboardModel?.publicMemories
                  ?.cast<CustomMemoryItem>() ??
              [], // Modified: Cast to proper type
          onMemoryTap: (memory) => onTapPublicMemory(context, memory),
          margin: EdgeInsets.only(top: 30.h, left: 24.h),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildTrendingStoriesHeader(BuildContext context) {
    return CustomSectionHeader(
      iconPath: ImageConstant.imgIconBlueA700,
      text: 'Trending Stories',
      margin: EdgeInsets.fromLTRB(24.h, 30.h, 24.h, 0.h),
    );
  }

  /// Navigates to the create memory screen
  void onTapCreateMemory(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.createMemoryScreen);
  }

  /// Handles plus button tap
  void onTapPlusButton(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.createMemoryScreen);
  }

  /// Handles gallery icon tap
  void onTapGalleryIcon(BuildContext context) {
    // Navigate to gallery or media selection
    NavigatorService.pushNamed(AppRoutes.addMemoryUploadScreen);
  }

  /// Handles notification icon tap
  void onTapNotificationIcon(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }

  /// Handles profile image tap
  void onTapProfileImage(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  /// Handles happening now story tap
  void onTapHappeningNowStory(BuildContext context, dynamic story) {
    NavigatorService.pushNamed(AppRoutes.videoCallScreen);
  }

  /// Handles public memory tap
  void onTapPublicMemory(BuildContext context, dynamic memory) {
    NavigatorService.pushNamed(AppRoutes.eventStoriesViewScreen);
  }
}
