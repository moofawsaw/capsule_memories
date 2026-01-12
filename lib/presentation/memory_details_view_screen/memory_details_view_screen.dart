// lib/presentation/memory_details_view_screen/memory_details_view_screen.dart

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
import '../event_timeline_view_screen/widgets/timeline_story_widget.dart';


class MemoryDetailsViewScreen extends ConsumerStatefulWidget {
  MemoryDetailsViewScreen({Key? key}) : super(key: key);

  @override
  MemoryDetailsViewScreenState createState() => MemoryDetailsViewScreenState();
}class _TimelineSkeletonBlock extends StatelessWidget {
  const _TimelineSkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      width: double.maxFinite,
      child: Container(
        height: 220.h,
        decoration: BoxDecoration(
          color: appTheme.gray_900_03,
          borderRadius: BorderRadius.circular(16.h),
        ),
      ),
    );
  }
}

class _StoriesSkeletonRow extends StatelessWidget {
  const _StoriesSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120.h,
      child: ListView.separated(
        padding: EdgeInsets.only(left: 20.h, right: 20.h),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(width: 12.h),
        itemBuilder: (_, __) {
          return Container(
            width: 110.h,
            decoration: BoxDecoration(
              color: appTheme.gray_900_03,
              borderRadius: BorderRadius.circular(14.h),
            ),
          );
        },
      ),
    );
  }
}

class _SealedMemoryDetailsSkeleton extends StatelessWidget {
  const _SealedMemoryDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12.h),

          // Header skeleton (approx CustomEventCard)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.h),
            child: Container(
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color: appTheme.gray_900_03,
                borderRadius: BorderRadius.circular(16.h),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44.h,
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: appTheme.blue_gray_900,
                          borderRadius: BorderRadius.circular(14.h),
                        ),
                      ),
                      SizedBox(width: 12.h),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14.h,
                              width: 180.h,
                              decoration: BoxDecoration(
                                color: appTheme.blue_gray_900,
                                borderRadius: BorderRadius.circular(6.h),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Container(
                              height: 12.h,
                              width: 140.h,
                              decoration: BoxDecoration(
                                color: appTheme.blue_gray_900,
                                borderRadius: BorderRadius.circular(6.h),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.h),
                      Container(
                        width: 56.h,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: appTheme.blue_gray_900,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    height: 12.h,
                    width: 220.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue_gray_900,
                      borderRadius: BorderRadius.circular(6.h),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Timeline skeleton block
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Container(
              height: 220.h,
              decoration: BoxDecoration(
                color: appTheme.gray_900_03,
                borderRadius: BorderRadius.circular(16.h),
              ),
            ),
          ),

          SizedBox(height: 18.h),

          // "Stories" title skeleton
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

          // Story cards skeleton row
          SizedBox(
            height: 140.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => SizedBox(width: 12.h),
              itemBuilder: (_, __) {
                return Container(
                  width: 120.h,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_03,
                    borderRadius: BorderRadius.circular(16.h),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 24.h),

          // Buttons skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.h),
            child: Column(
              children: [
                Container(
                  height: 48.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_03,
                    borderRadius: BorderRadius.circular(14.h),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  height: 48.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_03,
                    borderRadius: BorderRadius.circular(14.h),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class MemoryDetailsViewScreenState
    extends ConsumerState<MemoryDetailsViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        print('❌ SEALED SCREEN: Invalid argument type - expected MemoryNavArgs or Map');
      }

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

      ref.read(memoryDetailsViewNotifier.notifier).initializeFromMemory(navArgs);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryDetailsViewNotifier);
    print('🧪 SEALED UI: isLoading=${state.isLoading} error=${state.errorMessage}');

    // ✅ Trigger options sheet when notifier flips the flag.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shouldOpen = state.showEventOptions == true;

      if (!shouldOpen) return;

      // Reset FIRST so rebuilds don't re-open
      ref.read(memoryDetailsViewNotifier.notifier).hideEventOptions();

      // If you want owners only:
      if (state.isOwner != true) {
        print('⚠️ SEALED SCREEN: Options requested but user is not owner');
        return;
      }

      _showMemoryOptionsSheet(context);
    });

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

    final hasSnapshot = state.memoryDetailsViewModel != null;

// ✅ Only show a full-screen loader/skeleton if we have nothing to render yet
    if ((state.isLoading ?? false) && !hasSnapshot) {
      return Container(
        color: appTheme.gray_900_02,
        child: _SealedMemoryDetailsSkeleton(), // ✅ your skeleton goes here
      );
    }


    return Container(
      color: appTheme.gray_900_02,
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
    );
  }

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
            // ✅ Always fire; sheet will decide owner/non-owner
            ref.read(memoryDetailsViewNotifier.notifier).onEventOptionsTap();
          },
          onAvatarTap: () {
            onTapAvatars(context);
          },
        );
      },
    );
  }

  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        // ✅ SHOW SKELETON while loading, even if snapshot header exists
        if (state.isLoading == true) {
          return Container(
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
                    color: appTheme.gray_900_03,
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
          );
        }

        final timelineDetail = state.memoryDetailsViewModel?.timelineDetail;
        final List<TimelineStoryItem> timelineStories =
            state.memoryDetailsViewModel?.timelineDetail?.timelineStories ??
                <TimelineStoryItem>[];

        if (timelineDetail == null || timelineStories.isEmpty) {
          return const SizedBox.shrink();
        }

        final memoryStartTime = timelineDetail.memoryStartTime;
        final memoryEndTime = timelineDetail.memoryEndTime;

        if (memoryStartTime == null || memoryEndTime == null) {
          return const SizedBox.shrink();
        }

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
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoryList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        // ✅ SHOW SKELETON while loading, even if snapshot header exists
        if (state.isLoading == true) {
          return SizedBox(
            height: 120.h,
            child: ListView.separated(
              padding: EdgeInsets.only(left: 20.h, right: 20.h),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => SizedBox(width: 12.h),
              itemBuilder: (_, __) {
                return Container(
                  width: 110.h,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_03,
                    borderRadius: BorderRadius.circular(14.h),
                  ),
                );
              },
            ),
          );
        }

        final dynamic storyItemsDynamic =
            state.memoryDetailsViewModel?.customStoryItems ?? [];

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
        );
      },
    );
  }


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

  void _showMemoryOptionsSheet(BuildContext context) {
    final state = ref.read(memoryDetailsViewNotifier);
    final memoryId = state.memoryDetailsViewModel?.memoryId;

    if (memoryId == null || memoryId.isEmpty) {
      print('❌ SEALED SCREEN: Cannot open options (missing memoryId)');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: EdgeInsets.fromLTRB(16.h, 14.h, 16.h, 20.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44.h,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: appTheme.blue_gray_900,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 14.h),

                _OptionsRow(
                  title: 'Edit memory',
                  icon: Icons.edit,
                  onTap: () {
                    Navigator.pop(context);
                    NavigatorService.pushNamed(
                      AppRoutes.appBsDetails,
                      arguments: memoryId,
                    );
                  },
                ),

                SizedBox(height: 10.h),

                _OptionsRow(
                  title: 'Members',
                  icon: Icons.group,
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => MemoryMembersScreen(
                        memoryId: memoryId,
                        memoryTitle: state.memoryDetailsViewModel?.eventTitle,
                      ),
                    );
                  },
                ),

                SizedBox(height: 10.h),

                // Placeholder. Hook into your actual delete flow.
                _OptionsRow(
                  title: 'Delete memory',
                  icon: Icons.delete_outline,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    print('🗑️ TODO: Delete memory: $memoryId');
                  },
                ),

                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionsRow extends StatelessWidget {
  const _OptionsRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color fg = isDestructive ? appTheme.red_500 : appTheme.gray_50;

    return InkWell(
      borderRadius: BorderRadius.circular(12.h),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 12.h),
        decoration: BoxDecoration(
          color: appTheme.gray_900_03,
          borderRadius: BorderRadius.circular(12.h),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20.h),
            SizedBox(width: 10.h),
            Expanded(
              child: Text(
                title,
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: fg),
              ),
            ),
            Icon(Icons.chevron_right, color: appTheme.blue_gray_300, size: 20.h),
          ],
        ),
      ),
    );
  }
}
