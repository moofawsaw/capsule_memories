// lib/presentation/memory_details_view_screen/memory_details_view_screen.dart

import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_event_card.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/timeline_widget.dart';
import '../../widgets/memory_details_unified_skeleton.dart';
import '../add_memory_upload_screen/add_memory_upload_screen.dart';
import '../memory_details_screen/memory_details_screen.dart';
import '../memory_members_screen/memory_members_screen.dart';
import 'notifier/memory_details_view_notifier.dart';
import '../event_timeline_view_screen/widgets/timeline_story_widget.dart';

class MemoryDetailsViewScreen extends ConsumerStatefulWidget {
  MemoryDetailsViewScreen({Key? key}) : super(key: key);

  @override
  MemoryDetailsViewScreenState createState() => MemoryDetailsViewScreenState();
}

/// Inline circle icon button (same layout concept as Open timeline buttons)
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

class MemoryDetailsViewScreenState
    extends ConsumerState<MemoryDetailsViewScreen> {
  // ✅ Prevent first-frame “blank shell” before skeleton
  bool _booting = true;

  bool _isValidUuid(String? value) {
    if (value == null) return false;
    final v = value.trim();
    if (v.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(v);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rawArgs = ModalRoute.of(context)?.settings.arguments;

      MemoryNavArgs? navArgs;

      if (rawArgs is MemoryNavArgs) {
        navArgs = rawArgs;
      } else if (rawArgs is Map<String, dynamic>) {
        navArgs = MemoryNavArgs.fromMap(rawArgs);
      }

      if (navArgs == null || !navArgs.isValid) {
        ref.read(memoryDetailsViewNotifier.notifier).setErrorState(
          'Unable to load memory. Invalid navigation arguments.',
        );

        if (mounted) setState(() => _booting = false);
        return;
      }

      // ✅ Kick init
      ref.read(memoryDetailsViewNotifier.notifier).initializeFromMemory(navArgs);

      // ✅ Ensures frame-1 renders skeleton instead of any partial/default UI
      if (mounted) setState(() => _booting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryDetailsViewNotifier);

    // Error state
    if (state.errorMessage != null) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: appTheme.gray_900_02,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.h, color: appTheme.red_500),
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
                    onPressed: NavigatorService.goBack,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final hasSnapshot = state.memoryDetailsViewModel != null;
    final isLoading = state.isLoading ?? false;

    // ✅ Single source of truth (matches Open screen behavior)
    final effectiveLoading = isLoading || (_booting && !hasSnapshot);

    // ✅ Refresh skeletons only when snapshot exists
    final showSectionSkeletons = isLoading && hasSnapshot;

    // ✅ No blank shell first frame (use unified skeleton)
    if (effectiveLoading && !hasSnapshot) {
      return SafeArea(
        child: Scaffold(
          backgroundColor: appTheme.gray_900_02,
          body: MemoryDetailsUnifiedSkeleton.fullscreen(),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildEventHeader(context),
              _buildTimelineSection(context),
              _buildStoriesSection(context),
              SizedBox(height: 18.h),
              showSectionSkeletons
                  ? _buildActionButtonsSkeleton()
                  : _buildActionButtons(context),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        final hasSnapshot = state.memoryDetailsViewModel != null;
        final isLoading = state.isLoading ?? false;
        final showSectionSkeletons = isLoading && hasSnapshot;

        // ✅ Refresh header skeleton uses unified skeleton section piece
        if (showSectionSkeletons) {
          return MemoryDetailsUnifiedSkeleton.sectionOnly(
            header: true,
            timeline: false,
            storiesTitle: false,
            storiesRow: false,
            buttons: false,
          );
        }

        return CustomEventCard(
          isLoading: false,
          eventTitle: state.memoryDetailsViewModel?.eventTitle,
          eventDate: state.memoryDetailsViewModel?.eventDate,
          eventLocation: state.memoryDetailsViewModel?.eventLocation,
          isPrivate: state.memoryDetailsViewModel?.isPrivate,
          iconButtonImagePath: (state.memoryDetailsViewModel?.categoryIcon ??
              ImageConstant.imgFrame13),
          participantImages: state.memoryDetailsViewModel?.participantImages,
          onBackTap: NavigatorService.goBack,
          onIconButtonTap: () {
            // Inline controls used on sealed
          },
          onAvatarTap: () => onTapAvatars(context),
        );
      },
    );
  }

  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        final hasSnapshot = state.memoryDetailsViewModel != null;
        final isLoading = state.isLoading ?? false;
        final showSectionSkeletons = isLoading && hasSnapshot;

        // ✅ Only show skeleton block when refreshing AND snapshot exists
        if (showSectionSkeletons) {
          return MemoryDetailsUnifiedSkeleton.sectionOnly(
            header: false,
            timeline: true,
            storiesTitle: false,
            storiesRow: false,
            buttons: false,
          );
        }

        final timelineDetail = state.memoryDetailsViewModel?.timelineDetail;
        if (timelineDetail == null) return const SizedBox.shrink();

        final List<TimelineStoryItem> timelineStories =
            timelineDetail.timelineStories ?? <TimelineStoryItem>[];

        final memoryStartTime = timelineDetail.memoryStartTime;
        final memoryEndTime = timelineDetail.memoryEndTime;

        if (memoryStartTime == null || memoryEndTime == null) {
          return const SizedBox.shrink();
        }

        final isOwner = state.isOwner == true;

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

              // INLINE BUTTONS (OWNER ONLY)
              if (isOwner)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(right: 16.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleIconButton(
                          icon: Icons.delete_outline,
                          isDestructive: true,
                          onTap: () => _onTapDeleteMemory(context),
                        ),
                        SizedBox(width: 8.h),
                        _CircleIconButton(
                          icon: Icons.edit,
                          onTap: () => _onTapEditMemory(context),
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
                final state = ref.watch(memoryDetailsViewNotifier);

                final hasSnapshot = state.memoryDetailsViewModel != null;
                final isLoading = state.isLoading ?? false;
                final showSectionSkeletons = isLoading && hasSnapshot;

                if (showSectionSkeletons) {
                  return MemoryDetailsUnifiedSkeleton.sectionOnly(
                    header: false,
                    timeline: false,
                    storiesTitle: true,
                    storiesRow: false,
                    buttons: false,
                  );
                }

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

  Widget _buildStoryList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        final hasSnapshot = state.memoryDetailsViewModel != null;
        final isLoading = state.isLoading ?? false;
        final showSectionSkeletons = isLoading && hasSnapshot;

        if (showSectionSkeletons) {
          return MemoryDetailsUnifiedSkeleton.sectionOnly(
            header: false,
            timeline: false,
            storiesTitle: false,
            storiesRow: true,
            buttons: false,
          );
        }

        final dynamic storyItemsDynamic =
            state.memoryDetailsViewModel?.customStoryItems ?? [];

        final List<CustomStoryItem> storyItems = storyItemsDynamic is List
            ? storyItemsDynamic.whereType<CustomStoryItem>().toList()
            : <CustomStoryItem>[];

        if (storyItems.isEmpty) {
          return Container(
            margin: EdgeInsets.only(left: 20.h, right: 20.h),
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.h),
            decoration: BoxDecoration(
              color: appTheme.blue_gray_300.withAlpha(77),
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

  Widget _buildActionButtonsSkeleton() {
    return MemoryDetailsUnifiedSkeleton.sectionOnly(
      header: false,
      timeline: false,
      storiesTitle: false,
      storiesRow: false,
      buttons: true,
    );
  }

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
            onPressed: () async {
              final state = ref.read(memoryDetailsViewNotifier);
              final memoryId = state.memoryDetailsViewModel?.memoryId;
              final startDate =
                  state.memoryDetailsViewModel?.timelineDetail?.memoryStartTime;
              final endDate =
                  state.memoryDetailsViewModel?.timelineDetail?.memoryEndTime;

              if (memoryId != null && startDate != null && endDate != null) {
                final didUpload = await showModalBottomSheet<bool>(
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

                if (didUpload == true) {
                  await ref
                      .read(memoryDetailsViewNotifier.notifier)
                      .refreshMemory(memoryId);
                }
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

  void onTapStoryItem(BuildContext context, int index) {
    final notifier = ref.read(memoryDetailsViewNotifier.notifier);
    final ids = notifier.currentMemoryStoryIds;

    if (ids.isEmpty) return;

    final initialId =
    (index >= 0 && index < ids.length) ? ids[index] : ids.first;

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

  // ============================
  // EDIT + DELETE (Open parity)
  // ============================

  void _onTapEditMemory(BuildContext context) {
    final state = ref.read(memoryDetailsViewNotifier);
    final memoryId = state.memoryDetailsViewModel?.memoryId;

    if (!_isValidUuid(memoryId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid memory id'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final safeId = memoryId!.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: MemoryDetailsScreen(memoryId: safeId),
      ),
    );
  }

  void _onTapDeleteMemory(BuildContext context) {
    final state = ref.read(memoryDetailsViewNotifier);
    final memoryId = state.memoryDetailsViewModel?.memoryId;
    final memoryTitle = state.memoryDetailsViewModel?.eventTitle;

    if (!_isValidUuid(memoryId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid memory id'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final safeId = memoryId!.trim();

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
                builder: (_) => Center(
                  child: CircularProgressIndicator(
                    color: appTheme.deep_purple_A100,
                  ),
                ),
              );

              try {
                await ref
                    .read(memoryDetailsViewNotifier.notifier)
                    .deleteMemory(safeId);

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
