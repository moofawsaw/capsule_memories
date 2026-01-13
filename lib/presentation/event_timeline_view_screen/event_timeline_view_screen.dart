import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_button_skeleton.dart';
import '../../widgets/custom_event_card.dart';
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
import './widgets/timeline_story_widget.dart';

class EventTimelineViewScreen extends ConsumerStatefulWidget {
  EventTimelineViewScreen({Key? key}) : super(key: key);

  @override
  EventTimelineViewScreenState createState() => EventTimelineViewScreenState();
}

class EventTimelineViewScreenState extends ConsumerState<EventTimelineViewScreen>
    with WidgetsBindingObserver {
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
          '❌ TIMELINE SCREEN: Invalid argument type - expected MemoryNavArgs or Map',
        );
      }

      // Validate arguments before proceeding
      if (navArgs == null || !navArgs.isValid) {
        print('❌ TIMELINE SCREEN: Missing or invalid memory ID');
        print('   - Redirecting to memories list...');

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            NavigatorService.popAndPushNamed(AppRoutes.appMemories);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                const Text('Please select a memory to view its timeline'),
                backgroundColor: appTheme.deep_purple_A100,
                duration: const Duration(seconds: 3),
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
      ref.read(eventTimelineViewNotifier.notifier).initializeFromMemory(navArgs);

      // DEBUG TOAST: Validate data passing after initialization completes
      Future.delayed(const Duration(milliseconds: 500), () {
        _showDebugValidationToast();
      });

      // CRITICAL: Real-time validation against Supabase
      Future.delayed(const Duration(seconds: 1), () async {
        final notifier = ref.read(eventTimelineViewNotifier.notifier);
        final isValid = await notifier.validateMemoryData(navArgs!.memoryId);

        if (!isValid) {
          print('⚠️ TIMELINE: Data validation detected mismatches');
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
                _buildEventHeader(context),
                _buildTimelineSection(context),
                _buildStoriesSection(context),
                SizedBox(height: 18.h),
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
        final isLoading = state.isLoading ?? false;

        if (isLoading) {
          return CustomTimelineHeaderSkeleton();
        }

        return CustomEventCard(
          eventTitle: state.eventTimelineViewModel?.eventTitle,
          eventDate: state.eventTimelineViewModel?.eventDate,
          eventLocation:
          state.eventTimelineViewModel?.timelineDetail?.centerLocation,
          isPrivate: state.eventTimelineViewModel?.isPrivate,
          iconButtonImagePath:
          state.eventTimelineViewModel?.categoryIcon ??
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

  /// Section Widget - Timeline section with inline icon buttons (matches MemoryDetailsView)
  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);
        final isLoading = state.isLoading ?? false;
        final isCurrentUserMember = state.isCurrentUserMember ?? false;
        final isCurrentUserCreator = state.isCurrentUserCreator ?? false;

        if (isLoading) {
          return CustomTimelineWidgetSkeleton();
        }

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
                    ),
                  ),
                ),
                width: double.maxFinite,
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: Column(
                  children: [
                    SizedBox(height: 44.h),
                    _buildTimelineWidget(context),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),

              // INLINE BUTTONS (same simple pattern as sealed view)
              if (isCurrentUserMember)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(right: 16.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrentUserCreator)
                          _CircleIconButton(
                            icon: Icons.delete_outline,
                            isDestructive: true,
                            onTap: () => onTapDeleteMemory(context),
                          ),
                        if (isCurrentUserCreator) SizedBox(width: 8.h),
                        if (isCurrentUserCreator)
                          _CircleIconButton(
                            icon: Icons.edit,
                            onTap: () => onTapEditMemory(context),
                          ),
                        if (isCurrentUserCreator) SizedBox(width: 8.h),

                        // QR button for all members
                        _CircleIconButton(
                          icon: Icons.qr_code,
                          onTap: () => onTapTimelineOptions(context),
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

    final List<TimelineStoryItem> timelineStories =
        state.eventTimelineViewModel?.timelineDetail?.timelineStories ??
            <TimelineStoryItem>[];

    final memoryStartTime =
        state.eventTimelineViewModel?.timelineDetail?.memoryStartTime;
    final memoryEndTime =
        state.eventTimelineViewModel?.timelineDetail?.memoryEndTime;

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
      return _buildTimelineEmptyState(context);
    }

    debugPrint(
        '🔍 TIMELINE WIDGET: Rendering ${timelineStories.length} stories');
    debugPrint('   - Memory window: $memoryStartTime to $memoryEndTime');
    debugPrint(
        '   - Duration: ${memoryEndTime.difference(memoryStartTime).inMinutes} minutes');

    return TimelineWidget(
      stories: timelineStories,
      memoryStartTime: memoryStartTime,
      memoryEndTime: memoryEndTime,
      onStoryTap: (storyId) {
        final notifier = ref.read(eventTimelineViewNotifier.notifier);

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

  /// Empty state for timeline matching memory cards design
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
    return SizedBox(
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
        final isLoading = state.isLoading ?? false;
        final storyItems = state.eventTimelineViewModel?.customStoryItems ?? [];

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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => Center(
          child: CircularProgressIndicator(
            color: appTheme.deep_purple_A100,
          ),
        ),
      );

      await notifier.joinMemory(memoryId);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully joined memory!'),
            backgroundColor: appTheme.deep_purple_A100,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await notifier.loadMemoryStories(memoryId);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join memory: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// CRITICAL FIX: Handle timeline story card tap - Navigate to story viewer
  void _handleTimelineStoryTap(BuildContext context, String storyId) {
    final notifier = ref.read(eventTimelineViewNotifier.notifier);

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

  void onTapBackButton(BuildContext context) {
    NavigatorService.goBack();
  }

  void onTapIconButton(BuildContext context) {
    // Handle icon button action
  }

  void onTapProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  void onTapEventOptions(BuildContext context) {
    // Handle event options
  }

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

  void onTapHangoutCall(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appHome);
  }

  void onTapStoryItem(BuildContext context, int index) {
    final notifier = ref.read(eventTimelineViewNotifier.notifier);
    final state = ref.read(eventTimelineViewNotifier);
    final storyItems = state.eventTimelineViewModel?.customStoryItems ?? [];

    if (index < storyItems.length) {
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

  void onTapViewAll(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;

    if (memoryId != null) {
      print('🔍 TIMELINE: Opening playback screen for memory: $memoryId');

      NavigatorService.pushNamed(
        AppRoutes.memoryTimelinePlayback,
        arguments: memoryId,
      );
    }
  }

  void onTapCreateStory(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appVideoCall);
  }

  void onTapNotification(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }

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
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: MemoryDetailsScreen(memoryId: memoryId),
        ),
      );
    }
  }

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
                Navigator.pop(dialogContext);

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
                  await ref
                      .read(eventTimelineViewNotifier.notifier)
                      .deleteMemory(memoryId);

                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Memory deleted successfully'),
                        backgroundColor: appTheme.deep_purple_A100,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }

                  await Future.delayed(const Duration(milliseconds: 300));

                  if (context.mounted) {
                    NavigatorService.popAndPushNamed(AppRoutes.appMemories);
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete memory: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
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

/// Inline circle icon button (matches MemoryDetailsViewScreen snippet)
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final fg = isDestructive ? appTheme.red_500 : appTheme.gray_50;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.h),
      child: Container(
        height: 48.h,
        width: 48.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.h),
        ),
        child: Center(
          child: Icon(
            icon,
            color: fg,
            size: 22.h,
          ),
        ),
      ),
    );
  }
}
