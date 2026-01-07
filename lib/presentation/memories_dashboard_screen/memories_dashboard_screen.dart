import '../../core/app_export.dart';
import '../../core/utils/memory_navigation_wrapper.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_memory_skeleton.dart';
import '../../widgets/custom_public_memories.dart' as unified_widget;
import '../../widgets/custom_story_list.dart';
import '../../widgets/custom_story_skeleton.dart';
import '../create_memory_screen/create_memory_screen.dart';
import '../friends_management_screen/widgets/qr_scanner_overlay.dart';
import './models/memory_item_model.dart';
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
    // CRITICAL: Call initialize() for authenticated screens to load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoriesDashboardNotifier.notifier).initialize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // CRITICAL FIX: Force refresh when screen becomes visible again
    // This ensures deleted memories don't appear after deletion + redirect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(memoriesDashboardNotifier.notifier).refreshMemories();
      }
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
        body: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(memoriesDashboardNotifier.notifier)
                .refreshMemories();
          },
          color: appTheme.deep_purple_A100,
          backgroundColor: appTheme.gray_900_01,
          child: Column(
            children: [
              _buildMemoriesHeader(context),
              Expanded(
                child: Column(
                  children: [
                    _buildLatestStoriesSection(context),
                    _buildTabSection(context),
                    Expanded(
                      child: _buildMemoriesContent(context),
                    ),
                  ],
                ),
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
      margin: EdgeInsets.fromLTRB(16.h, 16.h, 16.h, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Consumer(
            builder: (context, ref, _) {
              return Row(
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
                  ),
                ],
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
        final storyItems = state.memoriesDashboardModel?.storyItems ?? [];
        final isLoading = state.isLoading ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(20.h, 14.h, 20.h, 0),
              child: Text(
                'Latest Stories (${storyItems.length})',
                style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ),
            SizedBox(height: 12.h),
            isLoading
                ? SizedBox(
                    height: 140.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 20.h),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 120.h,
                          margin: EdgeInsets.only(right: 10.h),
                          child: CustomStorySkeleton(isCompact: true),
                        );
                      },
                    ),
                  )
                : storyItems.isEmpty
                    ? SizedBox(
                        height: 140.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 20.h),
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 120.h,
                              margin: EdgeInsets.only(right: 10.h),
                              child: CustomStorySkeleton(isCompact: true),
                            );
                          },
                        ),
                      )
                    : SizedBox(
                        height: 140.h,
                        child: CustomStoryList(
                          storyItems: storyItems
                              .map((item) => CustomStoryItem(
                                    backgroundImage: item.backgroundImage ?? '',
                                    profileImage: item.profileImage ?? '',
                                    timestamp: item.timestamp ?? '2 mins ago',
                                    navigateTo: item.navigateTo,
                                    storyId: item.id,
                                    isRead: item.isRead ?? false,
                                  ))
                              .toList(),
                          onStoryTap: (index) => _onStoryTap(context, index),
                        ),
                      ),
          ],
        );
      },
    );
  }

  /// Empty State - Stories Feed
  // REMOVED: Empty state widget no longer used - replaced with skeleton loaders

  /// Section Widget - Tab Section
  Widget _buildTabSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoriesDashboardNotifier);
        final notifier = ref.read(memoriesDashboardNotifier.notifier);
        final selectedOwnership = state.selectedOwnership ?? 'created';
        final selectedState = state.selectedState ?? 'all';

        // FIXED: Calculate counts for ownership tabs
        final currentUser = SupabaseService.instance.client?.auth.currentUser;
        final userId = currentUser?.id ?? '';

        final createdCount = userId.isNotEmpty
            ? notifier.getOwnershipCount(userId, 'created')
            : 0;
        final joinedCount = userId.isNotEmpty
            ? notifier.getOwnershipCount(userId, 'joined')
            : 0;

        return Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.fromLTRB(16.h, 14.h, 16.h, 0),
          child: Row(
            children: [
              // Ownership Toggle (left side) - wrapped in Flexible instead of Expanded
              Flexible(
                flex: 7,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.h, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_02.withAlpha(128),
                    borderRadius: BorderRadius.circular(22.h),
                    border: Border.all(
                      color: appTheme.blue_gray_300.withAlpha(51),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onOwnershipTap(context, 'created'),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.h,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: selectedOwnership == 'created'
                                  ? appTheme.deep_purple_A100
                                  : appTheme.transparentCustom,
                              borderRadius: BorderRadius.circular(19.h),
                            ),
                            child: Text(
                              'Created by Me ($createdCount)',
                              textAlign: TextAlign.center,
                              style: selectedOwnership == 'created'
                                  ? TextStyleHelper
                                      .instance.body14BoldPlusJakartaSans
                                      .copyWith(color: appTheme.gray_900_02)
                                  : TextStyleHelper
                                      .instance.body14RegularPlusJakartaSans
                                      .copyWith(
                                          color:
                                              appTheme.gray_50.withAlpha(179)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onOwnershipTap(context, 'joined'),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.h,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: selectedOwnership == 'joined'
                                  ? appTheme.deep_purple_A100
                                  : appTheme.transparentCustom,
                              borderRadius: BorderRadius.circular(19.h),
                            ),
                            child: Text(
                              'Joined ($joinedCount)',
                              textAlign: TextAlign.center,
                              style: selectedOwnership == 'joined'
                                  ? TextStyleHelper
                                      .instance.body14BoldPlusJakartaSans
                                      .copyWith(color: appTheme.gray_900_02)
                                  : TextStyleHelper
                                      .instance.body14RegularPlusJakartaSans
                                      .copyWith(
                                          color:
                                              appTheme.gray_50.withAlpha(179)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 10.h),

              // State Dropdown (right side)
              GestureDetector(
                onTap: () => _showStateDropdown(context),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_02.withAlpha(128),
                    borderRadius: BorderRadius.circular(22.h),
                    border: Border.all(
                      color: appTheme.blue_gray_300.withAlpha(51),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getStateLabel(selectedState),
                        style: TextStyleHelper
                            .instance.body14RegularPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                      ),
                      SizedBox(width: 6.h),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16.h,
                        color: appTheme.gray_50,
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

  /// Section Widget - Memories Content
  Widget _buildMemoriesContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoriesDashboardNotifier);
        final notifier = ref.read(memoriesDashboardNotifier.notifier);

        ref.listen(
          memoriesDashboardNotifier,
          (previous, current) {
            if (current.isLoading == false && current.isSuccess == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Memories refreshed'),
                  backgroundColor: appTheme.colorFF52D1,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        );

        if (state.isLoading ?? false) {
          return Container(
            margin: EdgeInsets.fromLTRB(16.h, 14.h, 16.h, 16.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(3, (index) {
                  return CustomMemorySkeleton();
                }),
              ),
            ),
          );
        }

        // Get filtered memories based on BOTH ownership and state filters
        final currentUser = SupabaseService.instance.client?.auth.currentUser;
        if (currentUser == null) {
          return Center(
            child: Text(
              'Please log in to view memories',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          );
        }

        final filteredMemories = notifier.getFilteredMemories(currentUser.id);

        return Container(
          margin: EdgeInsets.fromLTRB(0, 14.h, 0, 16.h),
          child: _buildMemoryList(context, filteredMemories),
        );
      },
    );
  }

  /// Section Widget - Memory List
  Widget _buildMemoryList(
      BuildContext context, List<MemoryItemModel> memoryItems) {
    if (memoryItems.isEmpty) {
      final state = ref.read(memoriesDashboardNotifier);
      final ownership = state.selectedOwnership ?? 'created';
      final stateFilter = state.selectedState ?? 'all';
      return _buildMemoriesEmptyState(context, ownership, stateFilter);
    }

    // Convert MemoryItemModel to unified CustomMemoryItem format
    final convertedMemories = memoryItems.map((memoryItem) {
      return unified_widget.CustomMemoryItem(
        id: memoryItem.id,
        title: memoryItem.title,
        date: memoryItem.date,
        iconPath: memoryItem.categoryIconUrl,
        profileImages: memoryItem.participantAvatars,
        mediaItems: null,
        startDate: memoryItem.eventDate,
        startTime: memoryItem.eventTime,
        endDate: memoryItem.endDate,
        endTime: memoryItem.endTime,
        location: memoryItem.location,
        distance: memoryItem.distance,
        isLiked: false,
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(bottom: 14.h),
      physics: BouncingScrollPhysics(),
      child: Row(
        children: List.generate(convertedMemories.length, (index) {
          final memory = convertedMemories[index];
          final memoryItem = memoryItems[index];
          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 20.h : 0,
              right: 10.h,
            ),
            child: unified_widget.CustomPublicMemories(
              sectionTitle: null,
              sectionIcon: null,
              memories: [memory],
              onMemoryTap: (tappedMemory) => _onMemoryTap(context, memoryItem),
              margin: EdgeInsets.zero,
            ),
          );
        }),
      ),
    );
  }

  /// Empty State - Memories Feed
  Widget _buildMemoriesEmptyState(
      BuildContext context, String ownership, String stateFilter) {
    String title;
    String subtitle;
    String iconPath = ImageConstant.imgIcon10;

    // Generate appropriate empty state message based on filters
    if (ownership == 'created') {
      if (stateFilter == 'all') {
        title = 'No memories created yet';
        subtitle = 'Start creating memories to preserve your moments';
      } else if (stateFilter == 'live') {
        title = 'No live memories created';
        subtitle = 'Create a memory to start capturing moments';
      } else {
        title = 'No sealed memories created';
        subtitle = 'Sealed memories you created will appear here';
      }
    } else {
      // joined
      if (stateFilter == 'all') {
        title = 'No joined memories yet';
        subtitle = 'Memories you join will appear here';
      } else if (stateFilter == 'live') {
        title = 'No live joined memories';
        subtitle = 'Join a live memory to see it here';
      } else {
        title = 'No sealed joined memories';
        subtitle = 'Sealed memories you joined will appear here';
      }
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(24.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomImageView(
              imagePath: iconPath,
              height: 56.h,
              width: 56.h,
              color: appTheme.blue_gray_300,
            ),
            SizedBox(height: 18.h),
            Text(
              title,
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18.h),
            CustomButton(
              text: 'Create Memory',
              leftIcon: ImageConstant.imgIcon20x20,
              onPressed: () => _onCreateMemoryTap(context),
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

  /// Handle camera action for memory QR scanning
  void _onCameraButtonTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QRScannerOverlay(
          scanType: 'memory',
          onSuccess: () {
            ref.read(memoriesDashboardNotifier.notifier).refreshMemories();
          },
        ),
      ),
    );
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

  /// Handle ownership toggle tap
  void _onOwnershipTap(BuildContext context, String ownership) {
    final notifier = ref.read(memoriesDashboardNotifier.notifier);
    notifier.updateOwnershipFilter(ownership);
  }

  /// Show state dropdown menu
  void _showStateDropdown(BuildContext context) {
    final notifier = ref.read(memoriesDashboardNotifier.notifier);
    final currentState =
        ref.read(memoriesDashboardNotifier).selectedState ?? 'all';

    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.gray_900_01,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter by State',
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            SizedBox(height: 20.h),
            _buildStateOption(context, 'all', 'All', currentState, notifier),
            SizedBox(height: 12.h),
            _buildStateOption(context, 'live', 'Live', currentState, notifier),
            SizedBox(height: 12.h),
            _buildStateOption(
                context, 'sealed', 'Sealed', currentState, notifier),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// Build state dropdown option
  Widget _buildStateOption(
    BuildContext context,
    String value,
    String label,
    String currentState,
    MemoriesDashboardNotifier notifier,
  ) {
    final isSelected = currentState == value;

    return GestureDetector(
      onTap: () {
        notifier.updateStateFilter(value);
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? appTheme.deep_purple_A100.withAlpha(26)
              : appTheme.gray_900_02.withAlpha(128),
          borderRadius: BorderRadius.circular(12.h),
          border: Border.all(
            color: isSelected
                ? appTheme.deep_purple_A100
                : appTheme.blue_gray_300.withAlpha(51),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20.h,
                color: appTheme.deep_purple_A100,
              ),
            if (isSelected) SizedBox(width: 12.h),
            Text(
              label,
              style: isSelected
                  ? TextStyleHelper.instance.body16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50)
                  : TextStyleHelper.instance.body16RegularPlusJakartaSans
                      .copyWith(color: appTheme.gray_50.withAlpha(179)),
            ),
          ],
        ),
      ),
    );
  }

  /// Get state label for dropdown display
  String _getStateLabel(String state) {
    switch (state) {
      case 'live':
        return 'Live';
      case 'sealed':
        return 'Sealed';
      default:
        return 'All';
    }
  }
}
