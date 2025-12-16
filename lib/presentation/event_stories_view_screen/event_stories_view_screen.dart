import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_button.dart';
import 'models/contributor_item_model.dart';
import 'models/story_item_model.dart';
import 'notifier/event_stories_view_notifier.dart';
import 'widgets/contributor_item_widget.dart';
import 'widgets/story_item_widget.dart';

class EventStoriesViewScreen extends ConsumerStatefulWidget {
  EventStoriesViewScreen({Key? key}) : super(key: key);

  @override
  EventStoriesViewScreenState createState() => EventStoriesViewScreenState();
}

class EventStoriesViewScreenState
    extends ConsumerState<EventStoriesViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: appTheme.colorFF1A1A,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.h,
            height: 4.h,
            decoration: BoxDecoration(
              color: appTheme.colorFF3A3A,
              borderRadius: BorderRadius.circular(2.h),
            ),
          ),
          SizedBox(height: 20.h),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(context),
                  SizedBox(height: 32.h),
                  _buildContributorsSection(context),
                  SizedBox(height: 32.h),
                  _buildStoriesSection(context),
                  SizedBox(height: 32.h),
                  _buildWatchAllButton(context),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Event Header Section
  Widget _buildEventHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventStoriesViewNotifier);
        return Row(
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgWeddingRing,
              height: 48.h,
              width: 48.h,
            ),
            SizedBox(width: 16.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.eventStoriesViewModel?.eventTitle ?? '',
                    style: TextStyleHelper.instance.title20BoldPlusJakartaSans,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    state.eventStoriesViewModel?.eventDate ?? '',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    state.eventStoriesViewModel?.eventLocation ?? '',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgEye,
                  height: 16.h,
                  width: 16.h,
                ),
                SizedBox(width: 4.h),
                Text(
                  state.eventStoriesViewModel?.viewCount ?? '',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
                SizedBox(width: 16.h),
                CustomIconButton(
                  iconPath: ImageConstant.imgFrame13,
                  backgroundColor: appTheme.color41C124,
                  borderRadius: 24.h,
                  height: 48.h,
                  width: 48.h,
                  padding: EdgeInsets.all(12.h),
                  onTap: () => onTapNotificationButton(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Contributors Section
  Widget _buildContributorsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventStoriesViewNotifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contributors (${state.eventStoriesViewModel?.contributorsList?.length ?? 0})',
              style: TextStyleHelper.instance.title18SemiBoldPlusJakartaSans,
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 12.h,
              runSpacing: 12.h,
              children: List.generate(
                state.eventStoriesViewModel?.contributorsList?.length ?? 0,
                (index) {
                  final contributor =
                      state.eventStoriesViewModel?.contributorsList?[index];
                  return ContributorItemWidget(
                    contributorItemModel: contributor!,
                    onTapContributor: () =>
                        onTapContributor(context, contributor),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Stories Section
  Widget _buildStoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventStoriesViewNotifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stories (${state.eventStoriesViewModel?.storiesList?.length ?? 0})',
              style: TextStyleHelper.instance.title18SemiBoldPlusJakartaSans,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 120.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                physics: BouncingScrollPhysics(),
                separatorBuilder: (context, index) {
                  return SizedBox(width: 12.h);
                },
                itemCount:
                    state.eventStoriesViewModel?.storiesList?.length ?? 0,
                itemBuilder: (context, index) {
                  final story =
                      state.eventStoriesViewModel?.storiesList?[index];
                  return StoryItemWidget(
                    storyItemModel: story!,
                    onTapStory: () => onTapStory(context, story),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Watch All Button
  Widget _buildWatchAllButton(BuildContext context) {
    return CustomButton(
      text: 'Watch All Stories',
      width: double.infinity,
      leftIcon: ImageConstant.imgPlay,
      onPressed: () => onTapWatchAllStories(context),
      buttonStyle: CustomButtonStyle.fillPrimary,
      buttonTextStyle: CustomButtonTextStyle.bodyMedium,
    );
  }

  /// Navigates to notification screen
  void onTapNotificationButton(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }

  /// Handles contributor tap
  void onTapContributor(
      BuildContext context, ContributorItemModel contributor) {
    NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  /// Handles story tap
  void onTapStory(BuildContext context, StoryItemModel story) {
    // Navigate to story details or open story viewer
    print('Story tapped: ${story.storyId}');
  }

  /// Handles watch all stories button tap
  void onTapWatchAllStories(BuildContext context) {
    // Navigate to full story viewer or start story playback
    print('Watch all stories tapped');
  }
}
