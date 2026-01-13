// lib/presentation/memories_dashboard_screen/memories_dashboard_screen.dart

import '../../core/app_export.dart';
import '../../core/utils/memory_navigation_wrapper.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_memory_skeleton.dart';
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

class _MemoriesDashboardScreenState
    extends ConsumerState<MemoriesDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoriesDashboardNotifier.notifier).initialize();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(memoriesDashboardNotifier.notifier).refreshMemories();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
              SliverToBoxAdapter(child: _buildFilterRow(context)),
              SliverToBoxAdapter(child: SizedBox(height: 6.h)),
              SliverToBoxAdapter(child: _buildMemoriesContent(context)),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          ),
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
              CustomImageView(
                imagePath: ImageConstant.imgIcon10,
                height: 24.h,
                width: 24.h,
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
                leftIcon: ImageConstant.imgIcon20x20,
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
            height: 130.h,
            child: isLoading
                ? ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 20.h),
              itemCount: 3,
              itemBuilder: (_, __) => Container(
                width: 120.h,
                margin: EdgeInsets.only(right: 10.h),
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
                  isRead: e.isRead ?? false,
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

  // ================= FILTER ROW (Tabs + ONE toggle) =================

  Widget _buildFilterRow(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(memoriesDashboardNotifier);
      final notifier = ref.read(memoriesDashboardNotifier.notifier);

      final user = SupabaseService.instance.client?.auth.currentUser;
      if (user == null) return const SizedBox.shrink();

      final ownership = state.selectedOwnership ?? 'all';
      final counts = notifier.getOwnershipCounts(userId: user.id);

      final allCount = counts['all'] ?? 0;
      final createdCount = counts['created'] ?? 0;
      final joinedCount = counts['joined'] ?? 0;

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
                    _tab(
                      'All ($allCount)',
                      ownership == 'all',
                          () => notifier.updateOwnershipFilter('all'),
                    ),
                    _tab(
                      'Created ($createdCount)',
                      ownership == 'created',
                          () => notifier.updateOwnershipFilter('created'),
                    ),
                    _tab(
                      'Joined ($joinedCount)',
                      ownership == 'joined',
                          () => notifier.updateOwnershipFilter('joined'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.h),
            _openToggle(context),
          ],
        ),
      );
    });
  }

  Widget _tab(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: active ? appTheme.deep_purple_A100 : Colors.transparent,
            borderRadius: BorderRadius.circular(18.h),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: active
                ? TextStyleHelper.instance.body14BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_900_02)
                : TextStyleHelper.instance.body14RegularPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        ),
      ),
    );
  }

  Widget _openToggle(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(memoriesDashboardNotifier);
      final notifier = ref.read(memoriesDashboardNotifier.notifier);

      return GestureDetector(
        onTap: notifier.toggleOpenMemories,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_02.withAlpha(128),
            borderRadius: BorderRadius.circular(18.h),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.showOpenMemories ? Icons.lock_open : Icons.lock,
                size: 16.h,
                color: appTheme.gray_50,
              ),
              SizedBox(width: 6.h),
              Text(
                state.showOpenMemories ? 'Open' : 'Sealed',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ================= MEMORIES =================

  Widget _buildMemoriesContent(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(memoriesDashboardNotifier);
      final notifier = ref.read(memoriesDashboardNotifier.notifier);

      if (state.isLoading ?? false) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          child: Row(
            children: List.generate(3, (_) => CustomMemorySkeleton()),
          ),
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
              'No memories yet',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50.withAlpha(128)),
            ),
          ),
        );
      }

      // ✅ Render ONCE (your prior code accidentally rendered this list inside a loop)
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: unified_widget.CustomPublicMemories(
          variant: unified_widget.MemoryCardVariant.dashboard,
          memories: memories.map((m) {
            return unified_widget.CustomMemoryItem(
              id: m.id,
              userId: m.creatorId,
              title: m.title,
              date: m.date,
              iconPath: m.categoryIconUrl,
              profileImages: m.participantAvatars,
              startDate: m.eventDate,
              startTime: m.eventTime,
              endDate: m.endDate,
              endTime: m.endTime,
              location: m.location,
              distance: m.distance,
              isLiked: false,
              state: m.state,
              visibility: m.visibility,
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
    });
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
