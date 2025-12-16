import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/utils/image_constant.dart';
import '../../core/utils/navigator_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/text_style_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_story_list.dart'
    show CustomStoryList, CustomStoryItem;
import '../../widgets/custom_story_viewer.dart' show CustomStoryViewer;
import 'notifier/memory_details_view_notifier.dart';

// Modified: Added alias to resolve CustomStoryItem ambiguity

class MemoryDetailsViewScreen extends ConsumerStatefulWidget {
  MemoryDetailsViewScreen({Key? key}) : super(key: key);

  @override
  MemoryDetailsViewScreenState createState() => MemoryDetailsViewScreenState();
}

class MemoryDetailsViewScreenState
    extends ConsumerState<MemoryDetailsViewScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        appBar: _buildAppBar(),
        body: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 18.h),
                _buildEventCard(context),
                SizedBox(height: 18.h),
                _buildTimelineSection(context),
                SizedBox(height: 38.h),
                _buildTimelineDetails(context),
                SizedBox(height: 20.h),
                _buildStoriesSection(context),
                SizedBox(height: 19.h),
                _buildStoriesList(context),
                SizedBox(height: 21.h),
                _buildMemoryStatus(context),
                SizedBox(height: 23.h),
                _buildActionButtons(context),
                SizedBox(height: 24.h),
                _buildFooterMessage(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      logoImagePath: ImageConstant.imgLogo,
      showIconButton: true,
      iconButtonImagePath: ImageConstant.imgFrame19,
      iconButtonBackgroundColor: appTheme.color3BD81E,
      onIconButtonTap: () {
        ref.read(memoryDetailsViewNotifier.notifier).onAddContentTap();
      },
      actionIcons: [
        ImageConstant.imgIcon9,
        ImageConstant.imgIconGray5032x32,
      ],
      showProfileImage: true,
      profileImagePath: ImageConstant.imgEllipse8,
      isProfileCircular: true,
      onProfileTap: () {
        NavigatorService.pushNamed(AppRoutes.userProfileScreen);
      },
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
          CustomStoryViewer(
            storyItems: [
              story_viewer.CustomStoryItem(
                // Modified: Used aliased class to resolve ambiguity
                imagePath: ImageConstant.imgImage9,
                showPlayButton: true,
              ),
              story_viewer.CustomStoryItem(
                // Modified: Used aliased class to resolve ambiguity
                imagePath: ImageConstant.imgImage8,
                showPlayButton: true,
              ),
            ],
            profileImages: [
              ImageConstant.imgEllipse826x26,
              ImageConstant.imgFrame2,
            ],
            onStoryTap: (index) {
              NavigatorService.pushNamed(AppRoutes.videoCallScreen);
            },
            onPlayButtonTap: (index) {
              NavigatorService.pushNamed(AppRoutes.videoCallScreen);
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
        final state = ref.watch(memoryDetailsViewNotifier);

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
        NavigatorService.pushNamed(AppRoutes.videoCallScreen);
      },
    );
  }

  /// Section Widget
  Widget _buildMemoryStatus(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 22.h),
      child: Row(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgIconDeepPurpleA10014x14,
            height: 18.h,
            width: 18.h,
          ),
          SizedBox(width: 6.h),
          Text(
            'This memory is sealed',
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          Spacer(),
          Text(
            'Closed Dec 4, 2025',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
        ],
      ),
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
                ref.read(memoryDetailsViewNotifier.notifier).onAddMediaTap();
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
