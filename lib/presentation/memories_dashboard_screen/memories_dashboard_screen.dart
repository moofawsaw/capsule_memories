import '../../core/app_export.dart';
import '../../core/utils/memory_navigation_wrapper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_story_list.dart';
import '../create_memory_screen/create_memory_screen.dart';
import './models/memory_item_model.dart';
import './widgets/memory_card_widget.dart';
import 'notifier/memories_dashboard_notifier.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoriesDashboardNotifier);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          child: Column(
            children: [
              _buildMemoriesHeader(context),
              _buildLatestStoriesSection(context),
              _buildViewAllButton(context),
              _buildTabSection(context),
              Expanded(
                child: _buildMemoriesContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget - Memories Header
  Widget _buildMemoriesHeader(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.h, 24.h, 16.h, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgIcon10,
                height: 26.h,
                width: 26.h,
              ),
              SizedBox(width: 6.h),
              Text(
                'Memories',
                style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans,
              ),
            ],
          ),
          Consumer(
            builder: (context, ref, _) {
              return CustomButton(
                text: 'New',
                leftIcon: ImageConstant.imgIcon20x20,
                onPressed: () => _onCreateMemoryTap(context),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                height: 42.h,
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Section Widget - Latest Stories
  Widget _buildLatestStoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoriesDashboardNotifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(20.h, 22.h, 20.h, 0),
              child: Text(
                'Latest Stories (${state.memoriesDashboardModel?.storyItems?.length ?? 0})',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ),
            SizedBox(height: 18.h),
            CustomStoryList(
              storyItems: (state.memoriesDashboardModel?.storyItems ?? [])
                  .map((item) => CustomStoryItem(
                        backgroundImage: item.backgroundImage ?? '',
                        profileImage: item.profileImage ?? '',
                        timestamp: item.timestamp ?? '2 mins ago',
                        navigateTo: item.navigateTo,
                      ))
                  .toList(),
              onStoryTap: (index) => _onStoryTap(context, index),
            ),
          ],
        );
      },
    );
  }

  /// Section Widget - View All Button
  Widget _buildViewAllButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.h, 18.h, 20.h, 0),
      child: CustomButton(
        text: 'View All',
        onPressed: () => _onViewAllTap(context),
        width: double.infinity,
        buttonStyle: CustomButtonStyle.outlineDark,
        buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 30.h, vertical: 8.h),
      ),
    );
  }

  /// Section Widget - Tab Section
  Widget _buildTabSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoriesDashboardNotifier);
        final selectedIndex = state.selectedTabIndex ?? 0;

        return Container(
          margin: EdgeInsets.fromLTRB(16.h, 24.h, 16.h, 0),
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 4.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_02.withAlpha(128),
            borderRadius: BorderRadius.circular(24.h),
            border: Border.all(
              color: appTheme.blue_gray_300.withAlpha(51),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton(
                context: context,
                label: 'All',
                count: state.memoriesDashboardModel?.allCount ?? 0,
                isSelected: selectedIndex == 0,
                onTap: () => _onFilterTap(context, 0),
              ),
              _buildFilterButton(
                context: context,
                label: 'Live',
                count: state.memoriesDashboardModel?.liveCount ?? 0,
                isSelected: selectedIndex == 1,
                onTap: () => _onFilterTap(context, 1),
              ),
              _buildFilterButton(
                context: context,
                label: 'Sealed',
                count: state.memoriesDashboardModel?.sealedCount ?? 0,
                isSelected: selectedIndex == 2,
                onTap: () => _onFilterTap(context, 2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterButton({
    required BuildContext context,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? appTheme.deep_purple_A100
                : appTheme.transparentCustom,
            borderRadius: BorderRadius.circular(20.h),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: isSelected
                    ? TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_900_02)
                    : TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50.withAlpha(179)),
              ),
              SizedBox(width: 4.h),
              Text(
                '$count',
                style: isSelected
                    ? TextStyleHelper.instance.body14BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_900_02)
                    : TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50.withAlpha(179)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget - Memories Content
  Widget _buildMemoriesContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoriesDashboardNotifier);
        final selectedIndex = state.selectedTabIndex ?? 0;

        ref.listen(
          memoriesDashboardNotifier,
          (previous, current) {
            if (current.isLoading == false && current.isSuccess == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Memories loaded successfully'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
            }
          },
        );

        if (state.isLoading ?? false) {
          return Container(
            child: Center(
              child: CircularProgressIndicator(
                color: appTheme.deep_purple_A100,
              ),
            ),
          );
        }

        // Get filtered memories based on selected filter
        List<MemoryItemModel> filteredMemories;
        if (selectedIndex == 0) {
          filteredMemories = state.memoriesDashboardModel?.memoryItems ?? [];
        } else if (selectedIndex == 1) {
          filteredMemories =
              state.memoriesDashboardModel?.liveMemoryItems ?? [];
        } else {
          filteredMemories =
              state.memoriesDashboardModel?.sealedMemoryItems ?? [];
        }

        return Container(
          margin: EdgeInsets.fromLTRB(16.h, 20.h, 0, 0),
          child: _buildMemoryList(context, filteredMemories),
        );
      },
    );
  }

  /// Section Widget - Memory List
  Widget _buildMemoryList(
      BuildContext context, List<MemoryItemModel> memoryItems) {
    if (memoryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgIcon10,
              height: 48.h,
              width: 48.h,
              color: appTheme.blue_gray_300,
            ),
            SizedBox(height: 16.h),
            Text(
              'No memories found',
              style: TextStyleHelper.instance.title16MediumPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      physics: BouncingScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(width: 12.h),
      itemCount: memoryItems.length,
      itemBuilder: (context, index) {
        final memoryItem = memoryItems[index];
        return MemoryCardWidget(
          memoryItem: memoryItem,
          onTap: () => _onMemoryTap(context, memoryItem),
        );
      },
    );
  }

  /// Navigation Functions
  void _onCreateContentTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => CreateMemoryScreen(),
    );
  }

  void _onCreateMemoryTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => CreateMemoryScreen(),
    );
  }

  void _onStoryTap(BuildContext context, int index) {
    final state = ref.read(memoriesDashboardNotifier);
    final stories = state.memoriesDashboardModel?.storyItems ?? [];

    if (index < stories.length) {
      final story = stories[index];
      // Pass only story ID as String, matching /feed pattern
      NavigatorService.pushNamed(
        AppRoutes.appStoryView,
        arguments: story.id,
      );
    }
  }

  void _onViewAllTap(BuildContext context) {
    final notifier = ref.read(memoriesDashboardNotifier.notifier);
    notifier.loadAllStories();
  }

  void _onFilterTap(BuildContext context, int index) {
    final notifier = ref.read(memoriesDashboardNotifier.notifier);
    notifier.updateSelectedTabIndex(index);
  }

  void _onTabTap(BuildContext context, int index) {
    final notifier = ref.read(memoriesDashboardNotifier.notifier);
    notifier.updateSelectedTabIndex(index);
  }

  /// CRITICAL FIX: Use validated navigation wrapper for navigation
  void _onMemoryTap(BuildContext context, MemoryItemModel memoryItem) {
    print('🔍 NAVIGATION: Memory tapped: ${memoryItem.id}');

    // Use validated navigation wrapper
    MemoryNavigationWrapper.navigateFromMemoryItem(
      context: context,
      memoryItem: memoryItem,
    );
  }

  void _onNotificationTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }
}
