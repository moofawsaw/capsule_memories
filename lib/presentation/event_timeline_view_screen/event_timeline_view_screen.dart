import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/custom_story_progress.dart';
import '../qr_code_share_screen/qr_code_share_screen.dart';
import './widgets/timeline_detail_widget.dart';
import 'notifier/event_timeline_view_notifier.dart';

class EventTimelineViewScreen extends ConsumerStatefulWidget {
  EventTimelineViewScreen({Key? key}) : super(key: key);

  @override
  EventTimelineViewScreenState createState() => EventTimelineViewScreenState();
}

class EventTimelineViewScreenState
    extends ConsumerState<EventTimelineViewScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Column(
                children: [
                  _buildEventCard(context),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTimelineSection(context),
                        SizedBox(height: 18.h),
                        Expanded(
                          child: Column(
                            children: [
                              _buildStoriesSection(context),
                              SizedBox(height: 18.h),
                              Expanded(child: SizedBox()),
                              _buildActionButtons(context),
                              SizedBox(height: 20.h),
                            ],
                          ),
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
    );
  }

  /// Section Widget
  Widget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      logoImagePath: ImageConstant.imgLogo,
      showIconButton: true,
      iconButtonImagePath: ImageConstant.imgFrame19,
      iconButtonBackgroundColor: appTheme.color3BD81E,
      actionIcons: [ImageConstant.imgIcon9, ImageConstant.imgIconGray5032x32],
      showProfileImage: true,
      profileImagePath: ImageConstant.imgEllipse8,
      isProfileCircular: true,
    );
  }

  /// Section Widget
  Widget _buildEventCard(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);

        return CustomEventCard(
          eventTitle: state.eventTimelineViewModel?.eventTitle,
          eventDate: state.eventTimelineViewModel?.eventDate,
          isPrivate: state.eventTimelineViewModel?.isPrivate,
          iconButtonImagePath: ImageConstant.imgFrame13,
          participantImages: state.eventTimelineViewModel?.participantImages,
          onBackTap: () {
            onTapBackButton(context);
          },
          onIconButtonTap: () {
            onTapEventOptions(context);
          },
        );
      },
    );
  }

  /// Section Widget
  Widget _buildTimelineSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      child: Stack(
        children: [
          Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: appTheme.blue_gray_900,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildStoryProgress(context),
                SizedBox(height: 44.h),
                _buildTimelineDetails(context),
                SizedBox(height: 20.h),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: EdgeInsets.only(right: 16.h),
              child: CustomIconButton(
                iconPath: ImageConstant.imgButtons,
                backgroundColor: appTheme.gray_900_03,
                borderRadius: 24.h,
                height: 48.h,
                width: 48.h,
                padding: EdgeInsets.all(12.h),
                onTap: () {
                  onTapTimelineOptions(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildStoryProgress(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32.h),
      child: CustomStoryProgress(
        mainImagePath: ImageConstant.imgImage9,
        progressValue: 0.6,
        profileImagePath: ImageConstant.imgEllipse826x26,
        actionIconPath: ImageConstant.imgFrame19,
        showOverlayControls: true,
        overlayIconPath: ImageConstant.imgImagesmode,
        onActionTap: () {
          onTapHangoutCall(context);
        },
      ),
    );
  }

  /// Section Widget
  Widget _buildTimelineDetails(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);

        return TimelineDetailWidget(
          model: state.eventTimelineViewModel?.timelineDetail,
        );
      },
    );
  }

  /// Section Widget
  Widget _buildStoriesSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 20.h),
            child: Text(
              'Stories (6)',
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
          SizedBox(height: 18.h),
          _buildStoryList(context),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildStoryList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);

        return CustomStoryList(
          storyItems: state.eventTimelineViewModel?.storyItems ?? [],
          onStoryTap: (index) {
            onTapStoryItem(context, index);
          },
          itemGap: 8.h,
          margin: EdgeInsets.only(left: 20.h),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          CustomButton(
            text: 'View All',
            width: double.infinity,
            buttonStyle: CustomButtonStyle.outlineDark,
            buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
            onPressed: () {
              onTapViewAll(context);
            },
          ),
          SizedBox(height: 12.h),
          CustomButton(
            text: 'Create Story',
            width: double.infinity,
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            onPressed: () {
              onTapCreateStory(context);
            },
          ),
        ],
      ),
    );
  }

  /// Navigates back to the previous screen
  void onTapBackButton(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles icon button tap
  void onTapIconButton(BuildContext context) {
    // Handle icon button action
  }

  /// Handles profile tap
  void onTapProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.profileScreen);
  }

  /// Handles event options tap
  void onTapEventOptions(BuildContext context) {
    // Handle event options
  }

  /// Handles timeline options tap
  void onTapTimelineOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QRCodeShareScreen(),
    );
  }

  /// Navigates to hangout call
  void onTapHangoutCall(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.homeScreen);
  }

  /// Handles story item tap
  void onTapStoryItem(BuildContext context, int index) {
    NavigatorService.pushNamed(AppRoutes.videoCallScreen);
  }

  /// Handles view all tap
  void onTapViewAll(BuildContext context) {
    // Handle view all stories
  }

  /// Navigates to create story
  void onTapCreateStory(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.videoCallScreen);
  }

  /// Handles notification tap
  void onTapNotification(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }
}
