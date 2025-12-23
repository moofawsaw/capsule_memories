import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/custom_story_progress.dart';
import '../event_stories_view_screen/models/event_stories_view_model.dart';
import '../memory_members_screen/memory_members_screen.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Extract memory data from route arguments
      final memory = ModalRoute.of(context)?.settings.arguments;

      if (memory != null) {
        // Initialize notifier with memory data
        ref
            .read(eventTimelineViewNotifier.notifier)
            .initializeFromMemory(memory);
      } else {
        // Initialize with default data if no arguments
        ref.read(eventTimelineViewNotifier.notifier).initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This screen is rendered inside `AppShell`, which already provides
    // a `Scaffold` with a persistent `CustomAppBar`. To avoid showing
    // two app bars and to prevent bottom overflow on smaller screens,
    // we render only the content here and make it scrollable.
    return Container(
      color: appTheme.gray_900_02,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildEventCard(context),
            _buildTimelineSection(context),
            SizedBox(height: 18.h),
            _buildStoriesSection(context),
            SizedBox(height: 18.h),
            _buildActionButtons(context),
            SizedBox(height: 20.h),
          ],
        ),
      ),
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
          iconButtonImagePath: state.eventTimelineViewModel?.categoryIcon ??
              ImageConstant.imgFrame13,
          participantImages: state.eventTimelineViewModel?.participantImages,
          onBackTap: () {
            onTapBackButton(context);
          },
          onIconButtonTap: () {
            onTapEventOptions(context);
          },
          onAvatarTap: () {
            onTapAvatars(context);
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
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(eventTimelineViewNotifier);
                final storyCount =
                    state.eventTimelineViewModel?.customStoryItems?.length ?? 0;

                return Text(
                  'Stories ($storyCount)',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                );
              },
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
        final storyItems = state.eventTimelineViewModel?.customStoryItems ?? [];

        if (storyItems.isEmpty) {
          return Container(
            margin: EdgeInsets.only(left: 20.h),
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.h),
            decoration: BoxDecoration(
              color: appTheme.gray_900_03,
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Center(
              child: Text(
                'No stories yet',
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.gray_300),
              ),
            ),
          );
        }

        return CustomStoryList(
          storyItems: storyItems,
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
    NavigatorService.pushNamed(AppRoutes.appProfile);
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
    NavigatorService.pushNamed(AppRoutes.appHome);
  }

  /// Handles story item tap
  void onTapStoryItem(BuildContext context, int index) {
    final notifier = ref.read(eventTimelineViewNotifier.notifier);
    final state = ref.read(eventTimelineViewNotifier);
    final storyItems = state.eventTimelineViewModel?.customStoryItems ?? [];

    if (index < storyItems.length) {
      final storyItem = storyItems[index];

      // CRITICAL FIX: Pass FeedStoryContext with memory-specific story array
      // This ensures story viewer cycles through ONLY this memory's 3 stories
      final feedContext = FeedStoryContext(
        feedType: 'memory_timeline',
        storyIds: notifier.currentMemoryStoryIds, // Use memory-specific IDs
        initialStoryId: storyItem.navigateTo ?? '', // Add null check with default empty string
      );

      print('🔍 TIMELINE DEBUG: Opening story viewer with context:');
      print('   - Story IDs: ${feedContext.storyIds}');
      print('   - Initial story: ${feedContext.initialStoryId}');
      print('   - Total stories: ${feedContext.storyIds.length}');

      NavigatorService.pushNamed(
        AppRoutes.appStoryView,
        arguments: feedContext, // Pass context instead of just ID
      );
    }
  }

  /// Handles view all tap
  void onTapViewAll(BuildContext context) {
    // Handle view all stories
  }

  /// Navigates to create story
  void onTapCreateStory(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appVideoCall);
  }

  /// Handles notification tap
  void onTapNotification(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }

  /// Handles avatar cluster tap - opens members bottom sheet
  void onTapAvatars(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;
    final memoryTitle = state.eventTimelineViewModel?.eventTitle;

    if (memoryId != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MemoryMembersScreen(
          memoryId: memoryId,
          memoryTitle: memoryTitle,
        ),
      );
    }
  }
}