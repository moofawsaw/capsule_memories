import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/timeline_widget.dart';
import '../event_stories_view_screen/models/event_stories_view_model.dart';
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
    extends ConsumerState<EventTimelineViewScreen> {
  @override
  void initState() {
    super.initState();
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
                _buildEventHeader(context),
                _buildTimelineSection(context),
                _buildStoriesSection(context),
                SizedBox(height: 18.h),
                _buildActionButtons(context),
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

    if (timelineStories.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Text(
            'No stories in this memory timeline yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16.sp,
            ),
          ),
        ),
      );
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
          storyItems: (storyItems as List).cast<CustomStoryItem>(),
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
}
