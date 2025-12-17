import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
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
    extends ConsumerState<MemoriesDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoriesDashboardNotifier.notifier).initialize();
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoriesDashboardNotifier);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        appBar: _buildAppBar(),
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

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      logoImagePath: ImageConstant.imgLogo,
      showIconButton: true,
      iconButtonImagePath: ImageConstant.imgFrame19,
      iconButtonBackgroundColor: appTheme.color3BD81E,
      actionIcons: [
        ImageConstant.imgIconGray50,
        ImageConstant.imgIconGray5032x32,
      ],
      showProfileImage: true,
      profileImagePath: ImageConstant.imgEllipse8,
      isProfileCircular: true,
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
                        // Modified: Convert StoryItemModel to CustomStoryItem
                        backgroundImage: item.backgroundImage ?? '',
                        profileImage: item.profileImage ?? '',
                        timestamp: item.timestamp ?? '2 mins ago',
                        navigateTo: item.navigateTo,
                      ))
                  .toList(),
              onStoryTap: (index) => _onStoryTap(context, index),
              margin: EdgeInsets.only(left: 20.h),
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
          child: TabBar(
            controller: tabController,
            labelColor: appTheme.gray_900_02,
            unselectedLabelColor: appTheme.gray_50.withAlpha(179),
            labelStyle: TextStyleHelper.instance.body14BoldPlusJakartaSans,
            unselectedLabelStyle:
                TextStyleHelper.instance.body14RegularPlusJakartaSans,
            indicator: BoxDecoration(
              color: appTheme.deep_purple_A100,
              borderRadius: BorderRadius.circular(20.h),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding:
                EdgeInsets.symmetric(horizontal: 2.h, vertical: 2.h),
            dividerColor: appTheme.transparentCustom,
            tabs: [
              Tab(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('All'),
                      SizedBox(width: 4.h),
                      Text('${state.memoriesDashboardModel?.allCount ?? 1}'),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Live'),
                      SizedBox(width: 4.h),
                      Text('${state.memoriesDashboardModel?.liveCount ?? 1}'),
                    ],
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sealed'),
                      SizedBox(width: 4.h),
                      Text('${state.memoriesDashboardModel?.sealedCount ?? 1}'),
                    ],
                  ),
                ),
              ),
            ],
            onTap: (index) => _onTabTap(context, index),
          ),
        );
      },
    );
  }

  /// Section Widget - Memories Content
  Widget _buildMemoriesContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoriesDashboardNotifier);

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

        return Container(
          margin: EdgeInsets.fromLTRB(16.h, 20.h, 0, 0),
          child: TabBarView(
            controller: tabController,
            children: [
              _buildMemoryList(
                  context, state.memoriesDashboardModel?.memoryItems ?? []),
              _buildMemoryList(
                  context, state.memoriesDashboardModel?.liveMemoryItems ?? []),
              _buildMemoryList(context,
                  state.memoriesDashboardModel?.sealedMemoryItems ?? []),
            ],
          ),
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
    NavigatorService.pushNamed(AppRoutes.videoCallScreen);
  }

  void _onViewAllTap(BuildContext context) {
    final notifier = ref.read(memoriesDashboardNotifier.notifier);
    notifier.loadAllStories();
  }

  void _onTabTap(BuildContext context, int index) {
    final notifier = ref.read(memoriesDashboardNotifier.notifier);
    notifier.updateSelectedTabIndex(index);
  }

  void _onMemoryTap(BuildContext context, MemoryItemModel memoryItem) {
    // Conditional navigation based on memory status
    if (memoryItem.isSealed == true) {
      // Navigate to detail view screen for sealed memories
      NavigatorService.pushNamed(AppRoutes.timelineSealed);
    } else {
      // Navigate to timeline screen for open memories
      NavigatorService.pushNamed(AppRoutes.timelineScreen);
    }
  }

  void _onNotificationTap(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }
}