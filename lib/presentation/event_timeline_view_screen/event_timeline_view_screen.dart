import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_button_skeleton.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/timeline_widget.dart';
import '../add_memory_upload_screen/add_memory_upload_screen.dart';
import '../memory_details_screen/memory_details_screen.dart';
import '../memory_feed_dashboard_screen/widgets/native_camera_recording_screen.dart';
import '../memory_members_screen/memory_members_screen.dart';
import '../qr_timeline_share_screen/qr_timeline_share_screen.dart';
import './notifier/event_timeline_view_notifier.dart';
import './widgets/timeline_story_widget.dart';

// lib/presentation/event_timeline_view_screen/event_timeline_view_screen.dart

class EventTimelineViewScreen extends ConsumerStatefulWidget {
  final String? memoryId;
  final String? initialStoryId;

  const EventTimelineViewScreen({
    super.key,
    this.memoryId,
    this.initialStoryId,
  });

  @override
  EventTimelineViewScreenState createState() => EventTimelineViewScreenState();
}

// ============================
// SINGLE SKELETON (MATCH SEALED VIEW)
// ============================

class _TimelineViewSkeleton extends StatelessWidget {
  const _TimelineViewSkeleton();

  // Match sealed timeline skeleton sizing (MemoryDetailsViewScreen)
  static const double _storyCardW = 90; // 90.h
  static const double _storyCardH = 120; // 120.h
  static const double _storyRadius = 12; // 12.h

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (sealed-style): CustomEventCard renders its own skeleton.
          const CustomEventCard(isLoading: true),

          SizedBox(height: 16.h),

          // Timeline section skeleton (sealed-style)
          Container(
            margin: EdgeInsets.only(top: 6.h),
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            width: double.maxFinite,
            child: Column(
              children: [
                SizedBox(height: 44.h),
                Container(
                  height: 220.h,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_01,
                    borderRadius: BorderRadius.circular(16.h),
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  width: double.maxFinite,
                  height: 1,
                  color: appTheme.blue_gray_900,
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // Stories title skeleton
          Padding(
            padding: EdgeInsets.only(left: 20.h),
            child: Container(
              height: 14.h,
              width: 120.h,
              decoration: BoxDecoration(
                color: appTheme.blue_gray_900,
                borderRadius: BorderRadius.circular(6.h),
              ),
            ),
          ),

          SizedBox(height: 14.h),

          // Stories row skeleton
          SizedBox(
            height: _storyCardH.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => SizedBox(width: 8.h),
              itemBuilder: (_, __) {
                return Container(
                  width: _storyCardW.h,
                  height: _storyCardH.h,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_01,
                    borderRadius: BorderRadius.circular(_storyRadius.h),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 24.h),

          // Button skeletons (match rest of app)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h),
            child: Column(
              children: [
                CustomButtonSkeleton(),
                SizedBox(height: 12.h),
                CustomButtonSkeleton(),
              ],
            ),
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class EventTimelineViewScreenState
    extends ConsumerState<EventTimelineViewScreen> with WidgetsBindingObserver {
  String? _pendingInitialStoryId;

  late final ProviderSubscription<EventTimelineViewState> _firstLoadSub;

  bool _hasCompletedFirstLoad = false;
  bool _booting = true;
  int _storyOpenRetryCount = 0; // NEW: Track retry attempts
  static const int _maxRetryAttempts =
  10; // NEW: Max retries (2 seconds total with 200ms delays)

  String? _resolveExpectedMemoryId(BuildContext context) {
    // Priority 1: constructor memoryId (deep link / notification)
    final direct = (widget.memoryId ?? '').trim();
    if (direct.isNotEmpty) return direct;

    // Priority 2: route arguments
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is MemoryNavArgs) {
      return (rawArgs.memoryId).trim();
    }
    if (rawArgs is Map<String, dynamic>) {
      return (MemoryNavArgs.fromMap(rawArgs).memoryId).trim();
    }
    if (rawArgs is Map) {
      return (MemoryNavArgs.fromMap(rawArgs.cast<String, dynamic>()).memoryId).trim();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _booting = false);
      } else {
        _booting = false;
      }

      // ✅ Priority 1: constructor memoryId (deep link / notification)
      MemoryNavArgs? navArgs;

      if (widget.memoryId != null && widget.memoryId!.isNotEmpty) {
        navArgs = MemoryNavArgs(memoryId: widget.memoryId!);
      }

      // ✅ Priority 2: route arguments (existing behavior)
      if (navArgs == null) {
        final rawArgs = ModalRoute.of(context)?.settings.arguments;

        if (rawArgs is MemoryNavArgs) {
          navArgs = rawArgs;
        } else if (rawArgs is Map<String, dynamic>) {
          navArgs = MemoryNavArgs.fromMap(rawArgs);
        } else if (rawArgs is Map) {
          navArgs = MemoryNavArgs.fromMap(rawArgs.cast<String, dynamic>());
        }
      }

      // ✅ Capture initialStoryId from widget or navArgs (MUST happen before any early return)
      String? initialStoryId = widget.initialStoryId;
      if (initialStoryId == null || initialStoryId.isEmpty) {
        final candidate = navArgs?.initialStoryId;
        if (candidate != null && candidate.isNotEmpty) {
          initialStoryId = candidate;
        }
      }
      _pendingInitialStoryId = initialStoryId;

      // ✅ Validate navArgs
      if (navArgs == null || !navArgs.isValid) {
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

      ref
          .read(eventTimelineViewNotifier.notifier)
          .initializeFromMemory(navArgs);
    });

    _firstLoadSub = ref.listenManual<EventTimelineViewState>(
      eventTimelineViewNotifier,
          (prev, next) {
        final prevLoading = prev?.isLoading ?? false;
        final nextLoading = next.isLoading ?? false;

        if (!_hasCompletedFirstLoad &&
            prevLoading == true &&
            nextLoading == false) {
          if (mounted) {
            setState(() => _hasCompletedFirstLoad = true);

            // ✅ Auto-open story viewer with retry mechanism
            if (_pendingInitialStoryId != null &&
                _pendingInitialStoryId!.isNotEmpty) {
              _attemptStoryOpen();
            }
          } else {
            _hasCompletedFirstLoad = true;
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _firstLoadSub.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openStoryFromDeepLink(String storyId) {
    final notifier = ref.read(eventTimelineViewNotifier.notifier);
    final storyIds = notifier.currentMemoryStoryIds;

    if (storyIds.isEmpty) {
      debugPrint('⚠️ No stories loaded yet for deep link');
      return;
    }

    final feedContext = FeedStoryContext(
      feedType: 'memory_timeline',
      storyIds: storyIds,
      initialStoryId: storyId,
    );

    Navigator.pushNamed(
      context,
      AppRoutes.appStoryView,
      arguments: feedContext,
    );
  }

  // NEW: Retry mechanism for opening story viewer
  void _attemptStoryOpen() {
    if (_pendingInitialStoryId == null || _pendingInitialStoryId!.isEmpty) {
      return;
    }

    final notifier = ref.read(eventTimelineViewNotifier.notifier);
    final storyIds = notifier.currentMemoryStoryIds;

    if (storyIds.isEmpty) {
      // Stories not loaded yet - retry with exponential backoff
      if (_storyOpenRetryCount < _maxRetryAttempts) {
        _storyOpenRetryCount++;
        debugPrint(
            '⏳ Stories not loaded yet, retry attempt $_storyOpenRetryCount/$_maxRetryAttempts');

        Future.delayed(Duration(milliseconds: 200 * _storyOpenRetryCount), () {
          if (mounted && _pendingInitialStoryId != null) {
            _attemptStoryOpen();
          }
        });
      } else {
        debugPrint(
            '❌ Max retry attempts reached, stories failed to load for deep link');
        _pendingInitialStoryId = null;
        _storyOpenRetryCount = 0;
      }
      return;
    }

    // Stories loaded successfully - open viewer
    debugPrint('✅ Stories loaded, opening story viewer for deep link');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pendingInitialStoryId != null) {
        _openStoryFromDeepLink(_pendingInitialStoryId!);
        _pendingInitialStoryId = null;
        _storyOpenRetryCount = 0;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      final memoryId = ref.read(eventTimelineViewNotifier).memoryId;
      if (memoryId != null) {
        ref
            .read(eventTimelineViewNotifier.notifier)
            .validateMemoryData(memoryId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventTimelineViewNotifier);

    // If we were routed here with a specific memory (push/deep link),
    // NEVER show any other memory snapshot first. Block UI with skeleton until
    // the expected memoryId is the one currently loaded in state.
    final expectedMemoryId = _resolveExpectedMemoryId(context);
    final currentMemoryId =
        (state.eventTimelineViewModel?.memoryId ?? state.memoryId)?.trim();
    final waitingForExpectedMemory = (expectedMemoryId != null &&
        expectedMemoryId.trim().isNotEmpty &&
        currentMemoryId != expectedMemoryId.trim());

    final isLoading = state.isLoading ?? false;
    final hasSnapshot = state.eventTimelineViewModel != null;

    // Single source of truth for initial-load skeleton
    final effectiveLoading = isLoading || (_booting && !hasSnapshot);

    if (waitingForExpectedMemory || effectiveLoading) {
      return Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: const _TimelineViewSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: RefreshIndicator(
        onRefresh: () async {
          final memoryId = ref.read(eventTimelineViewNotifier).memoryId;
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
    );
  }

  /// IMPORTANT:
  /// - If no snapshot yet, return shrink (full-screen skeleton is handled in build()).
  /// - If snapshot exists, show CustomEventCard and let it render its own internal loading state.
  Widget _buildEventHeader(BuildContext context) {
    final state = ref.watch(eventTimelineViewNotifier);
    final isLoading = state.isLoading ?? false;
    final hasSnapshot = state.eventTimelineViewModel != null;

    final effectiveLoading = isLoading || (_booting && !hasSnapshot);

    if (!hasSnapshot) return const SizedBox.shrink();

    return CustomEventCard(
      isLoading: effectiveLoading,
      eventTitle:
      effectiveLoading ? null : state.eventTimelineViewModel?.eventTitle,
      eventDate:
      effectiveLoading ? null : state.eventTimelineViewModel?.eventDate,
      eventLocation: effectiveLoading
          ? null
          : state.eventTimelineViewModel?.timelineDetail?.centerLocation,
      isPrivate:
      effectiveLoading ? null : state.eventTimelineViewModel?.isPrivate,
      iconButtonImagePath:
      effectiveLoading ? null : state.eventTimelineViewModel?.categoryIcon,
      participantImages: effectiveLoading
          ? null
          : state.eventTimelineViewModel?.participantImages,
      onBackTap: () => onTapBackButton(context),
      onIconButtonTap: () => onTapEventOptions(context),
      onAvatarTap: () => onTapAvatars(context),
    );
  }

  /// Timeline section must NEVER return a full-screen skeleton / Scaffold.
  /// If loading with snapshot => show section skeleton only.
  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);
        final hasSnapshot = state.eventTimelineViewModel != null;

        if (!hasSnapshot) {
          return const SizedBox.shrink();
        }

        final isCurrentUserMember = state.isCurrentUserMember ?? false;
        final isCurrentUserCreator = state.isCurrentUserCreator ?? false;
        final hasPendingInvite = state.hasPendingInvite ?? false;

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
              if (isCurrentUserMember || hasPendingInvite) ...[
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(right: 16.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasPendingInvite && !isCurrentUserMember) ...[
                          CustomButton(
                            text: 'Join',
                            height: 36.h,
                            width: 92.h,
                            leftIcon: Icons.check_rounded,
                            buttonStyle: CustomButtonStyle.fillPrimary,
                            buttonTextStyle: CustomButtonTextStyle.bodySmall,
                            onPressed: () => onTapAcceptInvite(context),
                          ),
                          SizedBox(width: 8.h),
                        ],
                        if (isCurrentUserMember && !isCurrentUserCreator) ...[
                          _CircleIconButton(
                            icon: Icons.logout,
                            isDestructive: true,
                            onTap: () => onTapLeaveMemory(context),
                          ),
                          SizedBox(width: 8.h),
                        ],
                        if (isCurrentUserMember && isCurrentUserCreator) ...[
                          _CircleIconButton(
                            icon: Icons.delete_outline,
                            isDestructive: true,
                            onTap: () => onTapDeleteMemory(context),
                          ),
                          SizedBox(width: 8.h),
                          _CircleIconButton(
                            icon: Icons.edit,
                            onTap: () => onTapEditMemory(context),
                          ),
                          SizedBox(width: 8.h),
                        ],
                        if (isCurrentUserMember)
                          _CircleIconButton(
                            icon: Icons.qr_code,
                            onTap: () => onTapTimelineOptions(context),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineWidget(BuildContext context) {
    final state = ref.watch(eventTimelineViewNotifier);

    if (!_hasCompletedFirstLoad) return const SizedBox.shrink();

    final timelineDetail = state.eventTimelineViewModel?.timelineDetail;

    final List<TimelineStoryItem> timelineStories =
        timelineDetail?.timelineStories ?? <TimelineStoryItem>[];

    final memoryStartTime = timelineDetail?.memoryStartTime;
    final memoryEndTime = timelineDetail?.memoryEndTime;

    if (memoryStartTime == null || memoryEndTime == null) {
      return _buildTimelineEmptyState(context);
    }
    if (timelineStories.isEmpty) {
      return _buildTimelineEmptyState(context);
    }

    return TimelineWidget(
      stories: timelineStories,
      memoryStartTime: memoryStartTime,
      memoryEndTime: memoryEndTime,
      // Ensure sealed memories show the "SEALED" countdown badge (even for non-members).
      variant: (state.isSealed ?? false)
          ? TimelineVariant.sealed
          : TimelineVariant.active,
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

  // Timeline Empty State UI (3 Pieces)
  Widget _buildDateMarkerSkeletonCompact() {
    return Column(
      children: [
        Container(
          width: 2,
          height: 8.h,
          color: appTheme.blue_gray_300.withAlpha(51),
        ),
        SizedBox(height: 6.h),
        Container(
          width: 46.h,
          height: 12.h,
          decoration: BoxDecoration(
            color: appTheme.blue_gray_300.withAlpha(51),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: 5.h),
        Container(
          width: 38.h,
          height: 10.h,
          decoration: BoxDecoration(
            color: appTheme.blue_gray_300.withAlpha(51),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSkeletonCompact() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
      child: Column(
        children: [
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: appTheme.blue_gray_300.withAlpha(51),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateMarkerSkeletonCompact(),
              _buildDateMarkerSkeletonCompact(),
              _buildDateMarkerSkeletonCompact(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEmptyState(BuildContext context) {
    final state = ref.watch(eventTimelineViewNotifier);
    final isCurrentUserMember = state.isCurrentUserMember ?? false;
    final bool isSealed =
        state.eventTimelineViewModel?.isSealed ?? state.isSealed ?? false;

    return Center(
      child: Container(
        padding: EdgeInsets.all(24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Correct skeleton for empty timeline
            _buildTimelineSkeletonCompact(),

            SizedBox(height: 20.h),

            Text(
              'No stories in timeline yet',
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 6.h),

            Text(
              isCurrentUserMember
                  ? 'Start creating stories to build your memory timeline'
                  : 'Join this memory to start creating stories',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 18.h),

            if (isCurrentUserMember)
              CustomButton(
                text: isSealed ? 'Add Media' : 'Create Story',
                leftIcon:
                    isSealed ? Icons.add_photo_alternate_outlined : Icons.add,
                onPressed:
                    isSealed ? () => onTapAddMedia(context) : () => onTapCreateStory(context),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                height: 40.h,
                width: 180.h,
                padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 10.h),
              )
            else
              CustomButton(
                text: 'Join Memory',
                onPressed: () => onTapJoinFromTimeline(context),
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

  Widget _buildStoryList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);

        if (!_hasCompletedFirstLoad) return const SizedBox.shrink();

        final List<CustomStoryItem> storyItems =
        (state.eventTimelineViewModel?.customStoryItems ??
            const <dynamic>[])
            .whereType<CustomStoryItem>()
            .toList();

        if (storyItems.isEmpty) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.h),
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.h),
            decoration: BoxDecoration(
              color: appTheme.gray_900_01,
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
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(eventTimelineViewNotifier);
        final isCurrentUserMember = state.isCurrentUserMember ?? false;
        final bool sealedKnown =
            state.isSealed != null || state.eventTimelineViewModel?.isSealed != null;
        final bool isSealed =
            state.eventTimelineViewModel?.isSealed ?? state.isSealed ?? false;

        final storyCount =
            state.eventTimelineViewModel?.customStoryItems?.length ?? 0;
        final hasStories = storyCount > 0;

        // If we somehow reached here without a resolved sealed state, avoid flashing
        // the wrong actions (common when entering via push and state is still settling).
        if (!sealedKnown) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 24.h),
            child: Column(
              children: const [
                CustomButtonSkeleton(),
                SizedBox(height: 12),
                CustomButtonSkeleton(),
              ],
            ),
          );
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasStories) ...[
                CustomButton(
                  text: 'Cinema Mode',
                  width: double.infinity,
                  buttonStyle: CustomButtonStyle.outlineDark,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  leftIcon: Icons.theaters_outlined, // ✅ Material icon
                  onPressed: () => onTapViewAll(context),
                ),

                // ✅ EXPLANATION ONLY FOR NON-MEMBERS
                if (!isCurrentUserMember) ...[
                  SizedBox(height: 10.h),
                  Padding(
                    padding: EdgeInsets.only(left: 4.h, right: 4.h),
                    child: Center(
                      child: Text(
                        'Watch every story in the full screen media player',
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                            .copyWith(color: appTheme.blue_gray_300),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

                if (isCurrentUserMember) SizedBox(height: 12.h),
              ],

              if (isCurrentUserMember)
                CustomButton(
                  text: isSealed ? 'Add Media' : 'Create Story',
                  width: double.infinity,
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  leftIcon: isSealed
                      ? Icons.add_photo_alternate_outlined
                      : Icons.videocam_outlined, // ✅ Material icon
                  onPressed:
                      isSealed ? () => onTapAddMedia(context) : () => onTapCreateStory(context),
                ),
            ],
          ),
        );
      },
    );
  }


  void onTapJoinFromTimeline(BuildContext context) {
    NavigatorService.popAndPushNamed(AppRoutes.appNotifications);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Accept the memory invite to start creating stories'),
            backgroundColor: appTheme.deep_purple_A100,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  // ignore: unused_element
  void _onJoinMemory(BuildContext context, String memoryId) async {
    try {
      final notifier = ref.read(eventTimelineViewNotifier.notifier);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
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
      await notifier.validateMemoryData(memoryId);
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

  Future<void> _onLeaveMemory(BuildContext context, String memoryId) async {
    try {
      final notifier = ref.read(eventTimelineViewNotifier.notifier);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
        ),
      );

      await notifier.leaveMemory(memoryId);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You left the memory'),
            backgroundColor: appTheme.deep_purple_A100,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 250));

      if (context.mounted) {
        NavigatorService.popAndPushNamed(AppRoutes.appMemories);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave memory: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void onTapBackButton(BuildContext context) => NavigatorService.goBack();

  void onTapEventOptions(BuildContext context) {}

  Future<void> onTapAcceptInvite(BuildContext context) async {
    final state = ref.read(eventTimelineViewNotifier);
    if ((state.isLoading ?? false) == true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
      ),
    );

    try {
      await ref.read(eventTimelineViewNotifier.notifier).acceptPendingInviteAndJoin();

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You joined the memory!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join memory: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void onTapTimelineOptions(BuildContext context) {
    final memoryId =
        ref.read(eventTimelineViewNotifier).eventTimelineViewModel?.memoryId;
    if (memoryId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QRTimelineShareScreen(memoryId: memoryId),
    );
  }

  void onTapStoryItem(BuildContext context, int index) {
    final notifier = ref.read(eventTimelineViewNotifier.notifier);
    final ids = notifier.currentMemoryStoryIds;
    if (ids.isEmpty) return;

    final initialId =
    (index >= 0 && index < ids.length) ? ids[index] : ids.first;

    final feedContext = FeedStoryContext(
      feedType: 'memory_timeline',
      storyIds: ids,
      initialStoryId: initialId,
    );

    NavigatorService.pushNamed(AppRoutes.appStoryView, arguments: feedContext);
  }

  void onTapViewAll(BuildContext context) {
    final memoryId =
        ref.read(eventTimelineViewNotifier).eventTimelineViewModel?.memoryId;
    if (memoryId == null) return;

    NavigatorService.pushNamed(
      AppRoutes.memoryTimelinePlayback,
      arguments: memoryId,
    );
  }

  void onTapCreateStory(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;
    final memoryTitle = state.eventTimelineViewModel?.eventTitle ?? '';
    final categoryIcon = state.eventTimelineViewModel?.categoryIcon;

    if (memoryId == null || memoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Missing memory. Please reopen the timeline.'),
          backgroundColor: appTheme.deep_purple_A100,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => NativeCameraRecordingScreen(
          memoryId: memoryId,
          memoryTitle: memoryTitle,
          categoryIcon: categoryIcon,
        ),
      ),
    );
  }

  void onTapAddMedia(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;
    final timeline = state.eventTimelineViewModel?.timelineDetail;

    if (memoryId == null || memoryId.trim().isEmpty) return;

    final start = timeline?.memoryStartTime?.toLocal() ?? DateTime.now();
    final end = timeline?.memoryEndTime?.toLocal() ?? DateTime.now();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemoryUploadScreen(
          memoryId: memoryId,
          memoryStartDate: start,
          memoryEndDate: end,
        ),
        settings: RouteSettings(
          arguments: {
            'memory_id': memoryId,
            'memory_title': state.eventTimelineViewModel?.eventTitle,
            'category_icon': state.eventTimelineViewModel?.categoryIcon,
          },
        ),
      ),
    );
  }

  void onTapAvatars(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;
    final memoryTitle = state.eventTimelineViewModel?.eventTitle;

    if (memoryId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          MemoryMembersScreen(memoryId: memoryId, memoryTitle: memoryTitle),
    );
  }

  void onTapEditMemory(BuildContext context) {
    final memoryId =
        ref.read(eventTimelineViewNotifier).eventTimelineViewModel?.memoryId;
    if (memoryId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: MemoryDetailsScreen(memoryId: memoryId),
      ),
    );
  }

  void onTapLeaveMemory(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;
    final memoryTitle = state.eventTimelineViewModel?.eventTitle;
    final isCreator = state.isCurrentUserCreator ?? false;
    final isMember = state.isCurrentUserMember ?? false;

    if (!isMember || memoryId == null) return;
    if (isCreator) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: appTheme.gray_900_01,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
        title: Text(
          'Leave Memory?',
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        content: Text(
          'Are you sure you want to leave "${memoryTitle ?? 'this memory'}"? You will lose access to its timeline until you re-join.',
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
              await _onLeaveMemory(context, memoryId);
            },
            child: Text(
              'Leave',
              style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                  .copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void onTapDeleteMemory(BuildContext context) {
    final state = ref.read(eventTimelineViewNotifier);
    final memoryId = state.eventTimelineViewModel?.memoryId;
    final memoryTitle = state.eventTimelineViewModel?.eventTitle;

    if (memoryId == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: appTheme.gray_900_01,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
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
                builder: (_) => Center(
                  child: CircularProgressIndicator(
                      color: appTheme.deep_purple_A100),
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
          child: Icon(icon, color: fg, size: 22.h),
        ),
      ),
    );
  }
}
