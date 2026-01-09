import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_button_skeleton.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/custom_story_skeleton.dart';
import '../../widgets/custom_timeline_header_skeleton.dart';
import '../../widgets/custom_timeline_widget_skeleton.dart';
import '../../widgets/timeline_widget.dart';
import '../memory_details_screen/memory_details_screen.dart';
import '../memory_members_screen/memory_members_screen.dart';
import '../qr_timeline_share_screen/qr_timeline_share_screen.dart';
import './notifier/event_timeline_view_notifier.dart';

class EventTimelineViewScreen extends ConsumerStatefulWidget {
  EventTimelineViewScreen({Key? key}) : super(key: key);

  @override
  EventTimelineViewScreenState createState() => EventTimelineViewScreenState();
}

class EventTimelineViewScreenState
    extends ConsumerState<EventTimelineViewScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // CRITICAL FIX: Use typed navigation contract
      final rawArgs = ModalRoute.of(context)?.settings.arguments;

      print('🚨 TIMELINE SCREEN: Processing navigation arguments');
      print('   - Raw type: ${rawArgs.runtimeType}');

      MemoryNavArgs? navArgs;

      // Safely extract MemoryNavArgs from arguments
      if (rawArgs is MemoryNavArgs) {
        navArgs = rawArgs;
        print('✅ TIMELINE SCREEN: Received typed MemoryNavArgs');
      } else if (rawArgs is Map<String, dynamic>) {
        navArgs = MemoryNavArgs.fromMap(rawArgs);
        print('✅ TIMELINE SCREEN: Converted Map to MemoryNavArgs');
      } else {
        print(
            '❌ TIMELINE SCREEN: Invalid argument type - expected MemoryNavArgs or Map');
      }

      // Validate arguments before proceeding
      if (navArgs == null || !navArgs.isValid) {
        print('❌ TIMELINE SCREEN: Missing or invalid memory ID');
        print('   - Redirecting to memories list...');

        // Redirect to memories list if no memory ID provided
        // This handles cases where user navigates directly to /app/timeline
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            NavigatorService.popAndPushNamed(AppRoutes.appMemories);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please select a memory to view its timeline'),
                backgroundColor: appTheme.deep_purple_A100,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
        return;
      }

      print('✅ TIMELINE SCREEN: Valid MemoryNavArgs received');
      print('   - Memory ID: ${navArgs.memoryId}');
      print('   - Has snapshot: ${navArgs.snapshot != null}');

      // Initialize with typed arguments
      ref
          .read(eventTimelineViewNotifier.notifier)
          .initializeFromMemory(navArgs);

      // DEBUG TOAST: Validate data passing after initialization completes
      Future.delayed(Duration(milliseconds: 500), () {
        _showDebugValidationToast();
      });

      // CRITICAL: Real-time validation against Supabase
      Future.delayed(Duration(seconds: 1), () async {
        final notifier = ref.read(eventTimelineViewNotifier.notifier);
        final isValid = await notifier.validateMemoryData(navArgs!.memoryId);

        if (!isValid) {
          print('⚠️ TIMELINE: Data validation detected mismatches');
          // REMOVED: Toast message that was showing when clicking memory card
          // User requested to remove "Memory data refreshed from database" toast
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('Memory data refreshed from database'),
          //       duration: Duration(seconds: 2),
          //       backgroundColor: appTheme.deep_purple_A100,
          //     ),
          //   );
          // }
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh timeline data when app resumes
    if (state == AppLifecycleState.resumed) {
      final memoryId =
          ref.read(eventTimelineViewNotifier).eventTimelineViewModel?.memoryId;
      if (memoryId != null) {
        print(
            '🔄 TIMELINE: Screen resumed - refreshing data for memory: $memoryId');
        ref
            .read(eventTimelineViewNotifier.notifier)
            .validateMemoryData(memoryId);
      }
    }
  }

  /// DEBUG TOAST: Show validation results for data passing
  void _showDebugValidationToast() {
    final notifier = ref.read(eventTimelineViewNotifier.notifier);
    final validation = notifier.validateDataPassing();

    final results = validation['results'] as Map<String, dynamic>;
    final summary = validation['summary'] as String;
    final allValid = validation['allValid'] as bool;

    // Build detailed message
    final detailsBuffer = StringBuffer();
    detailsBuffer.writeln('🔍 TIMELINE DATA VALIDATION');
    detailsBuffer.writeln('─' * 30);

    results.forEach((field, isValid) {
      final icon = isValid ? '✅' : '❌';
      detailsBuffer
          .writeln('$icon $field: ${isValid ? "REAL DATA" : "STATIC/EMPTY"}');
    });

    detailsBuffer.writeln('─' * 30);
    detailsBuffer.writeln(summary);

    print(detailsBuffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventTimelineViewNotifier);
    final isLoading = state.isLoading ?? false;

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: RefreshIndicator(
          onRefresh: () async {
            final state = ref.read(eventTimelineViewNotifier);
            final memoryId = state.eventTimelineViewModel?.memoryId;
            if (memoryId != null) {
              await ref
                  .read(eventTimelineViewNotifier.notifier)
                  .validateMemoryData(memoryId);
            }
          },
          color: appTheme.deep_purple_A100,
          backgroundColor: appTheme.gray_900_01,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header skeleton or actual content
                isLoading
                    ? CustomTimelineHeaderSkeleton()
                    : _buildEventHeader(context),

                // Timeline section skeleton or actual content
                isLoading
                    ? CustomTimelineWidgetSkeleton()
                    : _buildTimelineSection(context),

                // Stories section with skeleton
                _buildStoriesSection(context),

                SizedBox(height: 18.h),

                // Action buttons skeleton or actual content
                isLoading
                    ? Container(
                        margin: EdgeInsets.symmetric(horizontal: 24.h),
                        child: Column(
                          children: [
                            CustomButtonSkeleton(),
                            SizedBox(height: 12.h),
                            CustomButtonSkeleton(),
                          ],
                        ),
                      )
                    : _buildActionButtons(context),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget - Restored original timeline header
  Widget _buildEventHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);

        return CustomEventCard(
          eventTitle: state.eventTimelineViewModel?.eventTitle,
          eventDate: state.eventTimelineViewModel?.eventDate,
          eventLocation:
              state.eventTimelineViewModel?.timelineDetail?.centerLocation,
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

  /// Section Widget - Timeline section with QR and Edit buttons
  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);
        final isCurrentUserMember = state.isCurrentUserMember ?? false;
        final isCurrentUserCreator = state.isCurrentUserCreator ?? false;

        print('🔍 TIMELINE BUTTONS: Visibility check');
        print('   - isCurrentUserMember = $isCurrentUserMember');
        print('   - isCurrentUserCreator = $isCurrentUserCreator');

        return Container(
          margin: EdgeInsets.only(top: 6.h),
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                  color: appTheme.blue_gray_900,
                  width: 1,
                ))),
                width: double.maxFinite,
                margin: EdgeInsets.fromLTRB(
                  0,
                  0,
                  0,
                  16,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 44.h),
                    _buildTimelineWidget(context),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
              // CONDITIONAL BUTTONS: Show based on user permissions
              if (isCurrentUserMember)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(right: 16.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8.h,
                      children: [
                        // DELETE BUTTON: Only show if current user is creator
                        if (isCurrentUserCreator)
                          CustomIconButton(
                            iconPath: ImageConstant.imgIconRed50026x26,
                            backgroundColor: appTheme.gray_900_03,
                            borderRadius: 24.h,
                            height: 48.h,
                            width: 48.h,
                            padding: EdgeInsets.all(12.h),
                            onTap: () {
                              onTapDeleteMemory(context);
                            },
                          ),
                        // EDIT BUTTON: Only show if current user is creator
                        if (isCurrentUserCreator)
                          CustomIconButton(
                            iconPath: ImageConstant.imgEdit,
                            backgroundColor: appTheme.gray_900_03,
                            borderRadius: 24.h,
                            height: 48.h,
                            width: 48.h,
                            padding: EdgeInsets.all(12.h),
                            onTap: () {
                              onTapEditMemory(context);
                            },
                          ),
                        // QR BUTTON: Show for all members
                        CustomIconButton(
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
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget - Timeline widget displaying memory stories
  Widget _buildTimelineWidget(BuildContext context) {
    final state = ref.watch(eventTimelineViewNotifier);

    if (state.isLoading ?? false) {
      return const Center(child: CircularProgressIndicator());
    }

    // Extract timeline stories from state
    final timelineStories =
        state.eventTimelineViewModel?.timelineDetail?.timelineStories ?? [];

    // CRITICAL FIX: Get memory window times from state, with proper fallback
    final memoryStartTime =
        state.eventTimelineViewModel?.timelineDetail?.memoryStartTime;
    final memoryEndTime =
        state.eventTimelineViewModel?.timelineDetail?.memoryEndTime;

    // CRITICAL: If memory times are null, don't render timeline
    if (memoryStartTime == null || memoryEndTime == null) {
      debugPrint(
          '⚠️ TIMELINE: Memory time window not available, showing loading state');
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: appTheme.deep_purple_A100),
              SizedBox(height: 12.h),
              Text(
                'Loading timeline...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // UPDATED: Show empty state matching memory cards design when no stories
    if (timelineStories.isEmpty) {
      return _buildTimelineEmptyState(context);
    }

    // Debug logging for timeline window
    debugPrint(
        '🔍 TIMELINE WIDGET: Rendering ${timelineStories.length} stories');
    debugPrint('   - Memory window: $memoryStartTime to $memoryEndTime');
    debugPrint(
        '   - Duration: ${memoryEndTime.difference(memoryStartTime).inMinutes} minutes');

    // Use the unified TimelineWidget - Convert stories to match widget's expected type
    return TimelineWidget(
      stories: timelineStories
          .map((story) => TimelineStoryItem(
                backgroundImage: story.backgroundImage,
                userAvatar: story.userAvatar,
                postedAt: story.postedAt,
                timeLabel: story.timeLabel,
                storyId: story.storyId,
                isVideo: story.isVideo,
              ))
          .toList(),
      memoryStartTime: memoryStartTime,
      memoryEndTime: memoryEndTime,
      onStoryTap: (storyId) {
        // Navigate to story viewer
        final notifier = ref.read(eventTimelineViewNotifier.notifier);

        // Get memory-specific story array for proper cycling
        final feedContext = FeedStoryContext(
          feedType: 'memory_timeline',
          storyIds: notifier.currentMemoryStoryIds,
          initialStoryId: storyId,
        );

        Navigator.pushNamed(
          context,
          AppRoutes.appStoryView,
          arguments: feedContext,
        );
      },
    );
  }

  /// NEW: Empty state for timeline matching memory cards design
  Widget _buildTimelineEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgIcon10,
              height: 56.h,
              width: 56.h,
              color: appTheme.blue_gray_300,
            ),
            SizedBox(height: 18.h),
            Text(
              'No stories in timeline yet',
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            SizedBox(height: 6.h),
            Text(
              'Start creating stories to build your memory timeline',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18.h),
            CustomButton(
              text: 'Create Story',
              leftIcon: ImageConstant.imgIcon20x20,
              onPressed: () => onTapCreateStory(context),
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
              height: 40.h,
              width: 180.h,
              padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 10.h),
            ),
          ],
        ),
      ),
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
                final isLoading = state.isLoading ?? false;
                final storyCount =
                    state.eventTimelineViewModel?.customStoryItems?.length ?? 0;

                return isLoading
                    ? Container(
                        width: 100.h,
                        height: 16.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: appTheme.blue_gray_300.withAlpha(77),
                        ),
                      )
                    : Text(
                        'Stories ($storyCount)',
                        style: TextStyleHelper
                            .instance.body14BoldPlusJakartaSans
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
        final isLoading = state.isLoading ?? false;
        final storyItems = state.eventTimelineViewModel?.customStoryItems ?? [];

        // Show skeleton loaders during loading
        if (isLoading) {
          return Container(
            margin: EdgeInsets.only(left: 20.h),
            height: 202.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (context, index) => SizedBox(width: 8.h),
              itemBuilder: (context, index) {
                return CustomStorySkeleton();
              },
            ),
          );
        }

        // Show empty state when no stories
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

        // Show actual story list
        return CustomStoryList(
          storyItems: (storyItems as List).cast<CustomStoryItem>(),
          onStoryTap: (index) {
            onTapStoryItem(context, index);
          },
          itemGap: 8.h,
          // margin: EdgeInsets.only(left: 20.h),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);
        final isCurrentUserMember = state.isCurrentUserMember ?? false;
        final memoryId = state.eventTimelineViewModel?.memoryId;
        final memoryName = state.eventTimelineViewModel?.eventTitle;

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
              // CONDITIONAL BUTTON: Show Create Story if member, else Join Memory button
              if (isCurrentUserMember)
                CustomButton(
                  text: 'Create Story',
                  width: double.infinity,
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  onPressed: () {
                    onTapCreateStory(context);
                  },
                )
              else
                CustomButton(
                  text: 'Join Memory',
                  width: double.infinity,
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  onPressed: () {
                    if (memoryId != null) {
                      _onJoinMemory(context, memoryId);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Handle join memory action
  void _onJoinMemory(BuildContext context, String memoryId) async {
    try {
      final notifier = ref.read(eventTimelineViewNotifier.notifier);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => Center(
          child: CircularProgressIndicator(
            color: appTheme.deep_purple_A100,
          ),
        ),
      );

      // Add user as contributor
      await notifier.joinMemory(memoryId);

      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined memory!'),
            backgroundColor: appTheme.deep_purple_A100,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Reload timeline to show create story button
      await notifier.loadMemoryStories(memoryId);
    } catch (e) {
      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join memory: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// CRITICAL FIX: Handle timeline story card tap - Navigate to story viewer
  void _handleTimelineStoryTap(BuildContext context, String storyId) {
    final notifier = ref.read(eventTimelineViewNotifier.notifier);

    // Get memory-specific story array for proper cycling
    final feedContext = FeedStoryContext(
      feedType: 'memory_timeline',
      storyIds: notifier.currentMemoryStoryIds,
      initialStoryId: storyId,
    );

    print('🔍 TIMELINE NAV: Opening story from timeline card');
    print('   - Story ID: $storyId');
    print('   - Context IDs: ${feedContext.storyIds}');
    print('   - Total stories: ${feedContext.storyIds.length}');

    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: feedContext,
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
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;

    if (memoryId != null) {
      print('🔍 TIMELINE: Opening QR share bottom sheet');
      print('   - Memory ID: $memoryId');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => QRTimelineShareScreen(memoryId: memoryId),
      );
    }
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
      // This ensures story viewer cycles through ONLY this memory's stories
      final feedContext = FeedStoryContext(
        feedType: 'memory_timeline',
        storyIds: notifier.currentMemoryStoryIds,
        initialStoryId: index < notifier.currentMemoryStoryIds.length
            ? notifier.currentMemoryStoryIds[index]
            : '',
      );

      NavigatorService.pushNamed(
        AppRoutes.appStoryView,
        arguments: feedContext,
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

  /// Handles edit memory button tap - opens Memory Details bottom sheet
  void onTapEditMemory(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;

    if (memoryId != null) {
      print('🔍 TIMELINE: Opening Memory Details bottom sheet for editing');
      print('   - Memory ID: $memoryId');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          child: MemoryDetailsScreen(memoryId: memoryId),
        ),
      );
    }
  }

  /// Handles delete memory button tap - shows confirmation dialog
  void onTapDeleteMemory(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;
    final memoryTitle = state.eventTimelineViewModel?.eventTitle;

    if (memoryId != null) {
      print('🔍 TIMELINE: Opening delete confirmation dialog');
      print('   - Memory ID: $memoryId');
      print('   - Memory Title: $memoryTitle');

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: appTheme.gray_900_01,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.h),
          ),
          title: Text(
            'Delete Memory?',
            style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          content: Text(
            'Are you sure you want to delete "${memoryTitle ?? 'this memory'}"? This action cannot be undone.',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Close confirmation dialog first
                Navigator.pop(dialogContext);

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => Center(
                    child: CircularProgressIndicator(
                      color: appTheme.deep_purple_A100,
                    ),
                  ),
                );

                try {
                  // Call delete method from notifier
                  await ref
                      .read(eventTimelineViewNotifier.notifier)
                      .deleteMemory(memoryId);

                  // Close loading indicator
                  if (context.mounted) Navigator.pop(context);

                  // Show success toast
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Memory deleted successfully'),
                        backgroundColor: appTheme.deep_purple_A100,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  // Wait briefly for toast to appear, then navigate
                  await Future.delayed(Duration(milliseconds: 300));

                  // Navigate back to memories list
                  if (context.mounted) {
                    NavigatorService.popAndPushNamed(AppRoutes.appMemories);
                  }
                } catch (e) {
                  // Close loading indicator
                  if (context.mounted) Navigator.pop(context);

                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Failed to delete memory: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Delete',
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
  }
}
