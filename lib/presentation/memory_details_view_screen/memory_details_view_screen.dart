import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/timeline_widget.dart';
import '../add_memory_upload_screen/add_memory_upload_screen.dart';
import '../memory_members_screen/memory_members_screen.dart';
import 'notifier/memory_details_view_notifier.dart';

class MemoryDetailsViewScreen extends ConsumerStatefulWidget {
  MemoryDetailsViewScreen({Key? key}) : super(key: key);

  @override
  MemoryDetailsViewScreenState createState() => MemoryDetailsViewScreenState();
}

class MemoryDetailsViewScreenState
    extends ConsumerState<MemoryDetailsViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use same navigation contract as timeline screen
      final rawArgs = ModalRoute.of(context)?.settings.arguments;

      print('🚨 SEALED SCREEN: Processing navigation arguments');
      print('   - Raw type: ${rawArgs.runtimeType}');

      MemoryNavArgs? navArgs;

      if (rawArgs is MemoryNavArgs) {
        navArgs = rawArgs;
        print('✅ SEALED SCREEN: Received typed MemoryNavArgs');
      } else if (rawArgs is Map<String, dynamic>) {
        navArgs = MemoryNavArgs.fromMap(rawArgs);
        print('✅ SEALED SCREEN: Converted Map to MemoryNavArgs');
      } else {
        print(
            '❌ SEALED SCREEN: Invalid argument type - expected MemoryNavArgs or Map');
      }

      // Validate arguments
      if (navArgs == null || !navArgs.isValid) {
        print('❌ SEALED SCREEN: Missing or invalid memory ID');
        ref.read(memoryDetailsViewNotifier.notifier).setErrorState(
          'Unable to load memory. Invalid navigation arguments.',
        );
        return;
      }

      print('✅ SEALED SCREEN: Valid MemoryNavArgs received');
      print('   - Memory ID: ${navArgs.memoryId}');
      print('   - Has snapshot: ${navArgs.snapshot != null}');

      // Initialize with same approach as timeline
      ref
          .read(memoryDetailsViewNotifier.notifier)
          .initializeFromMemory(navArgs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryDetailsViewNotifier);

    // Show error UI if navigation failed
    if (state.errorMessage != null) {
      return Container(
        color: appTheme.gray_900_02,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.h,
                  color: appTheme.red_500,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Failed to Load Memory',
                  style: TextStyleHelper.instance.body16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  state.errorMessage!,
                  style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                      .copyWith(color: appTheme.gray_300),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                CustomButton(
                  text: 'Go Back',
                  width: double.infinity,
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  onPressed: () {
                    NavigatorService.goBack();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading state
    if (state.isLoading ?? false) {
      return Container(
        color: appTheme.gray_900_02,
        child: Center(
          child: CircularProgressIndicator(
            color: appTheme.deep_purple_A100,
          ),
        ),
      );
    }

    // Display content with dynamic data
    return Container(
      color: appTheme.gray_900_02,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // MATCH OPEN SCREEN: no extra top padding here
            _buildEventHeader(context),

            // MATCH OPEN SCREEN: timeline section spacing
            _buildTimelineSection(context),

            // MATCH OPEN SCREEN: stories section spacing
            _buildStoriesSection(context),

            SizedBox(height: 18.h),

            // MATCH OPEN SCREEN: action buttons spacing
            _buildActionButtons(context),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// MATCH OPEN SCREEN: Header section (no manual top padding)
  Widget _buildEventHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        return CustomEventCard(
          eventTitle: state.memoryDetailsViewModel?.eventTitle,
          eventDate: state.memoryDetailsViewModel?.eventDate,
          eventLocation: state.memoryDetailsViewModel?.eventLocation,
          isPrivate: state.memoryDetailsViewModel?.isPrivate,
          iconButtonImagePath:
          state.memoryDetailsViewModel?.categoryIcon ?? ImageConstant.imgFrame13,
          participantImages: state.memoryDetailsViewModel?.participantImages,
          onBackTap: () {
            NavigatorService.goBack();
          },
          onIconButtonTap: () {
            ref.read(memoryDetailsViewNotifier.notifier).onEventOptionsTap();
          },
          onAvatarTap: () {
            onTapAvatars(context);
          },
        );
      },
    );
  }

  /// MATCH OPEN SCREEN: Timeline section spacing and structure
  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);
        final timelineDetail = state.memoryDetailsViewModel?.timelineDetail;

        final timelineStories = timelineDetail?.timelineStories ?? [];

        // If there are no stories, render nothing (same behavior as before)
        if (timelineDetail == null || timelineStories.isEmpty) {
          return const SizedBox.shrink();
        }

        final memoryStartTime = timelineDetail.memoryStartTime;
        final memoryEndTime = timelineDetail.memoryEndTime;

        if (memoryStartTime == null || memoryEndTime == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.only(top: 6.h), // matches open screen top spacing
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: appTheme.blue_gray_900,
                      width: 1,
                    ),
                  ),
                ),
                width: double.maxFinite,
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: Column(
                  children: [
                    SizedBox(height: 44.h),
                    TimelineWidget(
                      stories: timelineStories,
                      memoryStartTime: memoryStartTime,
                      memoryEndTime: memoryEndTime,
                      variant: TimelineVariant.sealed,
                      onStoryTap: (storyId) =>
                          _handleTimelineStoryTap(context, storyId),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// MATCH OPEN SCREEN: Stories section (header + list)
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
                final state = ref.watch(memoryDetailsViewNotifier);
                final storyCount =
                    state.memoryDetailsViewModel?.customStoryItems?.length ?? 0;

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

  /// Story list (same visual behavior as open screen)
  Widget _buildStoryList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        // In your model this is List<TimelineStoryItem>?, but CustomStoryList expects List<CustomStoryItem>.
        // Your notifier should populate a CustomStoryItem list somewhere else if you want this feed.
        // Here we follow the same cast pattern you were using earlier (assumes your notifier populates CustomStoryItem).
        final dynamic storyItemsDynamic =
            state.memoryDetailsViewModel?.customStoryItems ?? [];

        // If it's not CustomStoryItem list, show empty state to avoid crashes.
        final List<CustomStoryItem> storyItems = storyItemsDynamic is List
            ? storyItemsDynamic.whereType<CustomStoryItem>().toList()
            : <CustomStoryItem>[];

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
          onStoryTap: (index) => onTapStoryItem(context, index),
          itemGap: 8.h,
          // Match open screen: don't force extra margin here (open screen commented it out)
          // margin: EdgeInsets.only(left: 20.h),
        );
      },
    );
  }

  /// MATCH OPEN SCREEN: Action buttons block spacing
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          CustomButton(
            text: 'Replay All',
            width: double.infinity,
            buttonStyle: CustomButtonStyle.outlineDark,
            buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
            onPressed: () {
              ref.read(memoryDetailsViewNotifier.notifier).onReplayAllTap();
            },
          ),
          SizedBox(height: 12.h),
          CustomButton(
            text: 'Add Media',
            width: double.infinity,
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            onPressed: () {
              final state = ref.read(memoryDetailsViewNotifier);
              final memoryId = state.memoryDetailsViewModel?.memoryId;
              final startDate = state.memoryDetailsViewModel?.timelineDetail?.memoryStartTime;
              final endDate = state.memoryDetailsViewModel?.timelineDetail?.memoryEndTime;

              if (memoryId != null && startDate != null && endDate != null) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: AddMemoryUploadScreen(
                      memoryId: memoryId,
                      memoryStartDate: startDate,
                      memoryEndDate: endDate,
                    ),
                  ),
                );
              }
            },
          ),
          SizedBox(height: 14.h),
          Text(
            'You can still add photos and videos you captured during the memory window',
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300, height: 1.21),
          ),
        ],
      ),
    );
  }

  /// ✅ FIX: Timeline story tap should pass FeedStoryContext so story viewer only cycles this memory's stories
  void _handleTimelineStoryTap(BuildContext context, String storyId) {
    final notifier = ref.read(memoryDetailsViewNotifier.notifier);

    final feedContext = FeedStoryContext(
      feedType: 'memory_timeline',
      storyIds: notifier.currentMemoryStoryIds,
      initialStoryId: storyId,
    );

    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: feedContext,
    );
  }

  /// ✅ FIX: Story list tap should also pass FeedStoryContext
  void onTapStoryItem(BuildContext context, int index) {
    final notifier = ref.read(memoryDetailsViewNotifier.notifier);
    final ids = notifier.currentMemoryStoryIds;

    if (ids.isEmpty) {
      return;
    }

    final initialId = (index >= 0 && index < ids.length) ? ids[index] : ids.first;

    final feedContext = FeedStoryContext(
      feedType: 'memory_timeline',
      storyIds: ids,
      initialStoryId: initialId,
    );

    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: feedContext,
    );
  }

  void onTapAvatars(BuildContext context) {
    final state = ref.read(memoryDetailsViewNotifier);
    final memoryId = state.memoryDetailsViewModel?.memoryId;
    final memoryTitle = state.memoryDetailsViewModel?.eventTitle;

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