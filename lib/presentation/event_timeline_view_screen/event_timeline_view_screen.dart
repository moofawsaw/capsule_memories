import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_story_list.dart';
import '../event_stories_view_screen/models/event_stories_view_model.dart';
import '../memory_members_screen/memory_members_screen.dart';
import '../qr_timeline_share_screen/qr_timeline_share_screen.dart';
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
          // Optionally show user feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Memory data refreshed from database'),
                duration: Duration(seconds: 2),
                backgroundColor: appTheme.deep_purple_A100,
              ),
            );
          }
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
              await ref.read(eventTimelineViewNotifier.notifier).validateMemoryData(memoryId);
            }
          },
          color: appTheme.deep_purple_A100,
          backgroundColor: appTheme.gray_900_01,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildEventHeader(context),
                    _buildEventDetails(context),
                  ],
                ),
              ),
              _buildTimelineStories(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildEventHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);

        return CustomEventCard(
          eventData: CustomEventData(
            title: state.eventTimelineViewModel?.eventTitle,
            storyCountText: '${state.eventTimelineViewModel?.customStoryItems?.length ?? 0} stories',
            profileImage: state.eventTimelineViewModel?.categoryIcon ?? ImageConstant.imgFrame13,
            participantImages: state.eventTimelineViewModel?.participantImages,
          ),
          onActionTap: () {
            onTapEventOptions(context);
          },
          onMemoryTap: () {
            onTapAvatars(context);
          },
        );
      },
    );
  }

  /// Section Widget - UPDATED to conditionally show QR button
  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);
        final isCurrentUserMember = state.isCurrentUserMember;

        print(
            '🔍 TIMELINE QR BUTTON: isCurrentUserMember = $isCurrentUserMember');

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
              // CONDITIONAL QR BUTTON: Only show if current user is a member
              if (isCurrentUserMember)
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
      },
    );
  }

  /// Section Widget
  Widget _buildStoryProgress(BuildContext context) {
    return SizedBox();
  }

  /// Section Widget
  Widget _buildTimelineDetails(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);

        return TimelineDetailWidget(
          model: state.eventTimelineViewModel?.timelineDetail,
          onStoryTap: (storyId) => _handleTimelineStoryTap(context, storyId),
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
  Widget _buildEventDetails(BuildContext context) {
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

  /// Section Widget
  Widget _buildTimelineStories(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildStoriesSection(context),
          SizedBox(height: 18.h),
          _buildActionButtons(context),
          SizedBox(height: 20.h),
        ],
      ),
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
      // This ensures story viewer cycles through ONLY this memory's 3 stories
      final feedContext = FeedStoryContext(
        feedType: 'memory_timeline',
        storyIds: notifier.currentMemoryStoryIds, // Use memory-specific IDs
        initialStoryId: storyItem.navigateTo ??
            '', // Add null check with default empty string
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