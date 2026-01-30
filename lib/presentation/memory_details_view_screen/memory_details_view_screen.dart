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

// ============================
// SKELETONS (MATCH REFERENCE)
// ============================

class _OpenTimelineSkeletonSection extends StatelessWidget {
  const _OpenTimelineSkeletonSection();

  @override
  Widget build(BuildContext context) {
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
    );
  }
}

class _StoriesSkeletonRow extends StatelessWidget {
  const _StoriesSkeletonRow();

  static const double _cardW = 90;   // matches CustomStoryList width: 90.h
  static const double _cardH = 120;  // matches CustomStoryList height: 120.h
  static const double _radius = 12;  // matches CustomStoryList radius: 12.h

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardH.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.h),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(width: 8.h), // match your itemGap default
        itemBuilder: (_, __) {
          return Container(
            width: _cardW.h,
            height: _cardH.h,
            decoration: BoxDecoration(
              color: appTheme.gray_900_01,
              borderRadius: BorderRadius.circular(_radius.h),
            ),
          );
        },
      ),
    );
  }
}

class MemoryDetailsViewScreenState extends ConsumerState<MemoryDetailsViewScreen> {
  late final ProviderSubscription<MemoryDetailsViewState> _firstLoadSub;

  bool _hasCompletedFirstLoad = false;
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
      if (mounted) {
        setState(() => _booting = false);
      } else {
        _booting = false;
      }

      final rawArgs = ModalRoute.of(context)?.settings.arguments;

      MemoryNavArgs? navArgs;

      if (rawArgs is MemoryNavArgs) {
        navArgs = rawArgs;
      } else if (rawArgs is Map<String, dynamic>) {
        navArgs = MemoryNavArgs.fromMap(rawArgs);
      } else if (rawArgs is Map) {
        navArgs = MemoryNavArgs.fromMap(rawArgs.cast<String, dynamic>());
      }

      if (navArgs == null || !navArgs.isValid) {
        ref.read(memoryDetailsViewNotifier.notifier).setErrorState(
          'Unable to load memory. Invalid navigation arguments.',
        );
        return;
      }

      ref.read(memoryDetailsViewNotifier.notifier).initializeFromMemory(navArgs);
    });

    _firstLoadSub = ref.listenManual<MemoryDetailsViewState>(
      memoryDetailsViewNotifier,
          (prev, next) {
        final prevLoading = prev?.isLoading ?? false;
        final nextLoading = next.isLoading ?? false;

        if (!_hasCompletedFirstLoad &&
            prevLoading == true &&
            nextLoading == false) {
          if (mounted) {
            setState(() => _hasCompletedFirstLoad = true);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryDetailsViewNotifier);

    // Error state
    if (state.errorMessage != null) {
      return Scaffold(
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
      );
    }

    final isLoading = state.isLoading ?? false;
    final hasSnapshot = state.memoryDetailsViewModel != null;

    // ✅ EXACT SAME AS REFERENCE
    final effectiveLoading = isLoading || (_booting && !hasSnapshot);

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: RefreshIndicator(
        onRefresh: () async {
          final memoryId = ref
              .read(memoryDetailsViewNotifier)
              .memoryDetailsViewModel
              ?.memoryId;
          if (memoryId != null && memoryId.isNotEmpty) {
            await ref
                .read(memoryDetailsViewNotifier.notifier)
                .refreshMemory(memoryId);
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
              effectiveLoading
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
    );
  }

  /// IMPORTANT:
  /// - If no snapshot yet, return shrink (same as reference).
  /// - If snapshot exists, show CustomEventCard and let it render its own internal loading state.
  Widget _buildEventHeader(BuildContext context) {
    final state = ref.watch(memoryDetailsViewNotifier);

    final isLoading = state.isLoading ?? false;
    final hasSnapshot = state.memoryDetailsViewModel != null;

    final effectiveLoading = isLoading || (_booting && !hasSnapshot);

    if (!hasSnapshot) return const SizedBox.shrink();

    return CustomEventCard(
      isLoading: effectiveLoading,
      eventTitle: effectiveLoading ? null : state.memoryDetailsViewModel?.eventTitle,
      eventDate: effectiveLoading ? null : state.memoryDetailsViewModel?.eventDate,
      eventLocation: effectiveLoading ? null : state.memoryDetailsViewModel?.eventLocation,
      isPrivate: effectiveLoading ? null : state.memoryDetailsViewModel?.isPrivate,
      iconButtonImagePath: effectiveLoading
          ? null
          : (state.memoryDetailsViewModel?.categoryIcon ?? ''),
      participantImages: effectiveLoading ? null : state.memoryDetailsViewModel?.participantImages,
      onBackTap: NavigatorService.goBack,
      onIconButtonTap: () {},
      onAvatarTap: () => onTapAvatars(context),
    );
  }

  /// Timeline section must NEVER return a full-screen skeleton / Scaffold.
  /// If loading with snapshot => show section skeleton only.
  Widget _buildTimelineSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsViewNotifier);

        final isLoading = state.isLoading ?? false;
        final hasSnapshot = state.memoryDetailsViewModel != null;

        if (isLoading && hasSnapshot) {
          return const _OpenTimelineSkeletonSection();
        }

        if (!hasSnapshot) {
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
                    _buildTimelineWidget(context),
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

  Widget _buildTimelineWidget(BuildContext context) {
    final state = ref.watch(memoryDetailsViewNotifier);

    // ✅ Match reference: don't render timeline until first load completed
    if (!_hasCompletedFirstLoad) return const SizedBox.shrink();

    final timelineDetail = state.memoryDetailsViewModel?.timelineDetail;
    if (timelineDetail == null) return const SizedBox.shrink();

    final List<TimelineStoryItem> timelineStories =
        timelineDetail.timelineStories ?? <TimelineStoryItem>[];

    final memoryStartTime = timelineDetail.memoryStartTime;
    final memoryEndTime = timelineDetail.memoryEndTime;

    if (memoryStartTime == null || memoryEndTime == null) {
      return const SizedBox.shrink();
    }

    // If you want an empty-state UI like the reference, add it here.
    if (timelineStories.isEmpty) {
      return const SizedBox.shrink();
    }

    return TimelineWidget(
      stories: timelineStories,
      memoryStartTime: memoryStartTime,
      memoryEndTime: memoryEndTime,
      variant: TimelineVariant.sealed,
      onStoryTap: (storyId) => _handleTimelineStoryTap(context, storyId),
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

                final isLoading = state.isLoading ?? false;
                final hasSnapshot = state.memoryDetailsViewModel != null;

                if (isLoading && hasSnapshot) {
                  return Container(
                    height: 14.h,
                    width: 120.h,
                    decoration: BoxDecoration(
                      color: appTheme.blue_gray_900,
                      borderRadius: BorderRadius.circular(6.h),
                    ),
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

        final isLoading = state.isLoading ?? false;
        final hasSnapshot = state.memoryDetailsViewModel != null;

        if (isLoading && hasSnapshot) {
          return const _StoriesSkeletonRow();
        }

        if (!_hasCompletedFirstLoad) return const SizedBox.shrink();

        final List<CustomStoryItem> storyItems =
        (state.memoryDetailsViewModel?.customStoryItems ?? const <dynamic>[])
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
  void onTapReplayAll(BuildContext context) {
    final state = ref.read(memoryDetailsViewNotifier);
    final memoryId = state.memoryDetailsViewModel?.memoryId;

    if (memoryId == null || memoryId.isEmpty) return;

    NavigatorService.pushNamed(
      AppRoutes.memoryTimelinePlayback,
      arguments: memoryId,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          CustomButton(
            text: 'Cinema Mode',
            width: double.infinity,
            buttonStyle: CustomButtonStyle.outlineDark,
            buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            leftIcon: Icons.theaters_outlined, // ✅ Material icon
            onPressed: () => onTapReplayAll(context),
          ),
          SizedBox(height: 12.h),
          CustomButton(
            text: 'Add Media',
            width: double.infinity,
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            leftIcon: Icons.add_photo_alternate_outlined, // ✅ Material icon
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

  void _onTapEditMemory(BuildContext context) {
    final state = ref.read(memoryDetailsViewNotifier);
    final memoryId = state.memoryDetailsViewModel?.memoryId;

    if (!_isValidUuid(memoryId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid memory id'),
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
                await ref.read(memoryDetailsViewNotifier.notifier).deleteMemory(safeId);

                if (context.mounted) Navigator.pop(context);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Memory deleted successfully'),
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
