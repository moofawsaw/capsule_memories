// lib/presentation/memories_dashboard_screen/memories_dashboard_screen.dart


import '../../core/app_export.dart';
import '../../core/utils/memory_actions_sheet.dart';
import '../../core/utils/memory_navigation_wrapper.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_public_memories.dart' as unified_widget;
import '../../widgets/custom_story_list.dart';
import '../../widgets/custom_story_skeleton.dart';
import '../create_memory_screen/create_memory_screen.dart';
import '../friends_management_screen/widgets/qr_scanner_overlay.dart';
import './notifier/memories_dashboard_notifier.dart';

class MemoriesDashboardScreen extends ConsumerStatefulWidget {
  const MemoriesDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MemoriesDashboardScreen> createState() =>
      _MemoriesDashboardScreenState();
}

class _MemoriesDashboardScreenState extends ConsumerState<MemoriesDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _livePulseController;
  late final Animation<double> _livePulseScale;
  late final Animation<double> _livePulseOpacity;

  @override
  void initState() {
    super.initState();

    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _livePulseScale = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(
        parent: _livePulseController,
        curve: Curves.easeOut,
      ),
    );

    _livePulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _livePulseController,
        curve: Curves.easeOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoriesDashboardNotifier.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _livePulseController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(memoriesDashboardNotifier.notifier).refreshMemories();
  }

  @override
  Widget build(BuildContext context) {
    // Start/stop pulse based on active filter state (no extra widgets/files)
    final dashState = ref.watch(memoriesDashboardNotifier);
    final isLiveFilterActive = dashState.showOnlyOpen;

    if (isLiveFilterActive && !_livePulseController.isAnimating) {
      _livePulseController.repeat();
    } else if (!isLiveFilterActive && _livePulseController.isAnimating) {
      _livePulseController.stop();
    }

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: RefreshIndicator(
        color: appTheme.deep_purple_A100,
        backgroundColor: appTheme.gray_900_01,
        displacement: 30,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildMemoriesHeader(context)),
            SliverToBoxAdapter(child: _buildLatestStoriesSection(context)),
            SliverToBoxAdapter(child: _buildTabsAndLiveFilterRow(context)),
            SliverToBoxAdapter(child: SizedBox(height: 6.h)),
            SliverToBoxAdapter(child: _buildMemoriesContent(context)),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildMemoriesHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 16.h, 16.h, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                size: 24.h,
                color: appTheme.deep_purple_A100,
              ),
              SizedBox(width: 6.h),
              Text(
                'Memories',
                style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans,
              ),
            ],
          ),
          Row(
            children: [
              CustomIconButton(
                height: 40.h,
                width: 40.h,
                icon: Icons.camera_alt,
                backgroundColor: appTheme.gray_900_01.withAlpha(179),
                borderRadius: 20.h,
                iconSize: 22.h,
                iconColor: Theme.of(context).colorScheme.onSurface,
                onTap: () => _onCameraButtonTap(context),
              ),
              SizedBox(width: 8.h),
              CustomButton(
                text: 'New',
                leftIcon: Icons.add,
                onPressed: () => _onCreateMemoryTap(context),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                height: 38.h,
                padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STORIES =================

  Widget _buildLatestStoriesSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(memoriesDashboardNotifier);
      final items = state.memoriesDashboardModel?.storyItems ?? [];
      final isLoading = state.isLoading ?? false;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.h, 16.h, 20.h, 0),
            child: Text(
              'Latest Stories (${items.length})',
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 121.h,
            child: isLoading
                ? ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 20.h),
              itemCount: 5,
              itemBuilder: (_, __) => Container(
                width: 90.h, // ✅ match real card width
                margin: EdgeInsets.only(right: 8.h), // ✅ match itemGap in CustomStoryList
                child: CustomStorySkeleton(isCompact: true),
              ),
            )
                : items.isEmpty
                ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: Text(
                  'No stories yet',
                  style: TextStyleHelper
                      .instance.body14RegularPlusJakartaSans
                      .copyWith(
                      color: appTheme.gray_50.withAlpha(128)),
                ),
              ),
            )
                : CustomStoryList(
              storyItems: items
                  .map(
                    (e) => CustomStoryItem(
                  backgroundImage: e.backgroundImage ?? '',
                  profileImage: e.profileImage ?? '',
                  timestamp: e.timestamp ?? '',
                  navigateTo: e.navigateTo,
                  storyId: e.id,
                  isRead: e.isRead,
                ),
              )
                  .toList(),
              onStoryTap: (i) => _onStoryTap(context, i),
            ),
          ),
        ],
      );
    });
  }

  // ================= TABS + LIVE FILTER (ONE ROW, NO WRAP) =================

  Widget _buildTabsAndLiveFilterRow(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(memoriesDashboardNotifier);
      final notifier = ref.read(memoriesDashboardNotifier.notifier);

      final user = SupabaseService.instance.client?.auth.currentUser;
      if (user == null) return const SizedBox.shrink();

      final counts = notifier.getOwnershipCounts(userId: user.id);
      final ownership = state.selectedOwnership ?? 'all';

      final isActive = state.showOnlyOpen;
      final openCount = notifier.getOpenCountAfterOwnership(user.id);

      return Container(
        margin: EdgeInsets.fromLTRB(16.h, 14.h, 16.h, 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(3.h),
                decoration: BoxDecoration(
                  color: appTheme.gray_900_02.withAlpha(128),
                  borderRadius: BorderRadius.circular(22.h),
                ),
                child: Row(
                  children: [
                    _tabWithCount(
                      label: 'All',
                      count: counts['all'] ?? 0,
                      active: ownership == 'all',
                      onTap: () => notifier.updateOwnershipFilter('all'),
                    ),
                    _tabWithCount(
                      label: 'Created',
                      count: counts['created'] ?? 0,
                      active: ownership == 'created',
                      onTap: () => notifier.updateOwnershipFilter('created'),
                    ),
                    _tabWithCount(
                      label: 'Joined',
                      count: counts['joined'] ?? 0,
                      active: ownership == 'joined',
                      onTap: () => notifier.updateOwnershipFilter('joined'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.h),
            _openToggleWithLiveDot(
              context,
              isActive: isActive,
              openCount: openCount,
              onTap: notifier.toggleOpenFilter,
            ),
          ],
        ),
      );
    });
  }

  Widget _tabWithCount({
    required String label,
    required int count,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.h),
          decoration: BoxDecoration(
            color: active ? appTheme.deep_purple_A100 : Colors.transparent,
            borderRadius: BorderRadius.circular(18.h),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$label $count',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: active
                    ? TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_900_02)
                    : TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _openToggleWithLiveDot(
      BuildContext context, {
        required bool isActive,
        required int openCount,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive
              ? appTheme.deep_purple_A100
              : appTheme.gray_900_02.withAlpha(128),
          borderRadius: BorderRadius.circular(18.h),
          border: Border.all(
            color: isActive
                ? appTheme.deep_purple_A100
                : appTheme.gray_50.withAlpha(40),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _livePulseController,
              builder: (context, _) {
                if (!isActive) {
                  return Container(
                    width: 10.h,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: appTheme.gray_50.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                  );
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: _livePulseScale.value,
                      child: Container(
                        width: 10.h,
                        height: 10.h,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent
                              .withOpacity(_livePulseOpacity.value),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Container(
                      width: 10.h,
                      height: 10.h,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(width: 6.h),
            Text(
              'Open',
              style: (isActive
                  ? TextStyleHelper.instance.body14BoldPlusJakartaSans
                  : TextStyleHelper.instance.body14RegularPlusJakartaSans)
                  .copyWith(
                color: isActive ? appTheme.gray_900_02 : appTheme.gray_50,
              ),
            ),
            SizedBox(width: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 2.h),
              decoration: BoxDecoration(
                color: isActive
                    ? appTheme.gray_900_02.withAlpha(35)
                    : appTheme.gray_50.withAlpha(30),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Text(
                '$openCount',
                style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                    .copyWith(
                  color: isActive
                      ? appTheme.gray_900_02
                      : appTheme.gray_50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


// ================= MEMORIES =================

  Widget _buildMemoriesContent(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(memoriesDashboardNotifier);
      final notifier = ref.read(memoriesDashboardNotifier.notifier);

      // ✅ LOADING: use the SAME component + SAME spacing rules as the working feeds
      if (state.isLoading ?? false) {
        return unified_widget.CustomPublicMemories(
          variant: unified_widget.MemoryCardVariant.dashboard,
          isLoading: true,
          // Match your screen’s layout (no extra top gap since you already have spacing above)
          margin: EdgeInsets.only(top: 16.h),
        );
      }

      final user = SupabaseService.instance.client?.auth.currentUser;
      if (user == null) return const SizedBox.shrink();

      final memories = notifier.getFilteredMemories(user.id);

      if (memories.isEmpty) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 40.h),
            child: Text(
              state.showOnlyOpen ? 'No open memories right now' : 'No memories yet',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50.withAlpha(128)),
            ),
          ),
        );
      }

      // ✅ IMPORTANT: do NOT wrap this in another SingleChildScrollView
      // CustomPublicMemories already scrolls horizontally and controls margins.
      return unified_widget.CustomPublicMemories(
        variant: unified_widget.MemoryCardVariant.dashboard,
        margin: EdgeInsets.only(top: 16.h),
        memories: memories.map((mm) {
          return unified_widget.CustomMemoryItem(
            id: mm.id,
            userId: mm.creatorId,
            title: mm.title,
            date: mm.date,
            iconPath: mm.categoryIconUrl,
            profileImages: mm.participantAvatars,
            startDate: mm.eventDate,
            startTime: mm.eventTime,
            endDate: mm.endDate,
            endTime: mm.endTime,
            location: mm.location,
            distance: mm.distance,
            isLiked: false,
            state: mm.state,
            visibility: mm.visibility,
          );
        }).toList(),
        onMemoryTap: (memoryItem) {
          final found = memories.firstWhere((x) => x.id == memoryItem.id);
          MemoryNavigationWrapper.navigateFromMemoryItem(
            context: context,
            memoryItem: found,
          );
        },
        onMemoryLongPress: (memoryItem) {
          final memoryId = (memoryItem.id ?? '').trim();
          if (memoryId.isEmpty) return;

          MemoryActionsSheet.show(
            context: context,
            memoryId: memoryId,
            ownerUserId: (memoryItem.userId ?? '').trim(),
            title: (memoryItem.title ?? 'Memory').trim(),
            visibility: (memoryItem.visibility ?? '').trim(),
            onDeleted: () async {
              // ✅ Update ONLY the memory card row immediately (no global loading).
              ref
                  .read(memoriesDashboardNotifier.notifier)
                  .removeMemoryLocally(memoryId);
            },
            onVisibilityChanged: (isPublic) async {
              // ✅ Update ONLY this card’s visibility (no global loading).
              ref
                  .read(memoriesDashboardNotifier.notifier)
                  .updateMemoryVisibilityLocally(
                    memoryId,
                    isPublic ? 'public' : 'private',
                  );
            },
          );
        },
      );
    });
  }

  // ignore: unused_element
  Widget _buildLoadedMemoriesList(
      BuildContext context,
      MemoriesDashboardState state,
      MemoriesDashboardNotifier notifier,
      ) {
    final user = SupabaseService.instance.client?.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final memories = notifier.getFilteredMemories(user.id);

    if (memories.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 40.h),
          child: Text(
            state.showOnlyOpen ? 'No open memories right now' : 'No memories yet',
            style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.gray_50.withAlpha(128)),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // IMPORTANT: start at same origin as skeleton list
      child: unified_widget.CustomPublicMemories(
        variant: unified_widget.MemoryCardVariant.dashboard,
        memories: memories.map((mm) {
          return unified_widget.CustomMemoryItem(
            id: mm.id,
            userId: mm.creatorId,
            title: mm.title,
            date: mm.date,
            iconPath: mm.categoryIconUrl,
            profileImages: mm.participantAvatars,
            startDate: mm.eventDate,
            startTime: mm.eventTime,
            endDate: mm.endDate,
            endTime: mm.endTime,
            location: mm.location,
            distance: mm.distance,
            isLiked: false,
            state: mm.state,
            visibility: mm.visibility,
          );
        }).toList(),
        onMemoryTap: (memoryItem) {
          final found = memories.firstWhere((x) => x.id == memoryItem.id);
          MemoryNavigationWrapper.navigateFromMemoryItem(
            context: context,
            memoryItem: found,
          );
        },
      ),
    );
  }

  // ================= NAV =================

  void _onCreateMemoryTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateMemoryScreen(),
    );
  }

  void _onCameraButtonTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QRScannerOverlay(
          scanType: 'memory',
          onSuccess: () =>
              ref.read(memoriesDashboardNotifier.notifier).refreshMemories(),
        ),
      ),
    );
  }

  void _onStoryTap(BuildContext context, int index) {
    final state = ref.read(memoriesDashboardNotifier);
    final items = state.memoriesDashboardModel?.storyItems ?? [];

    if (index >= 0 && index < items.length) {
      final story = items[index];
      if (story.id != null && story.id!.isNotEmpty) {
        NavigatorService.pushNamed(
          AppRoutes.appStoryView,
          arguments: story.id,
        );
      }
    }
  }
}
