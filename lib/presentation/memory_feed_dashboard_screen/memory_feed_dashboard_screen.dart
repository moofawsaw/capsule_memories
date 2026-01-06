import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../core/utils/memory_navigation_wrapper.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_category_badge.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_public_memories.dart' as custom_widget;
import '../../widgets/custom_story_skeleton.dart';
import '../add_memory_upload_screen/add_memory_upload_screen.dart';
import '../create_memory_screen/create_memory_screen.dart';
import '../event_stories_view_screen/models/event_stories_view_model.dart';
import './widgets/happening_now_story_card.dart';
import './widgets/memory_selection_bottom_sheet.dart';
import './widgets/native_camera_recording_screen.dart';
import 'notifier/memory_feed_dashboard_notifier.dart';

class MemoryFeedDashboardScreen extends ConsumerStatefulWidget {
  const MemoryFeedDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MemoryFeedDashboardScreen> createState() =>
      _MemoryFeedDashboardScreenState();
}

class _MemoryFeedDashboardScreenState
    extends ConsumerState<MemoryFeedDashboardScreen> {
  bool _isAuthenticated = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200px from bottom
      _loadMoreContent();
    }
  }

  void _loadMoreContent() {
    final notifier = ref.read(memoryFeedDashboardProvider.notifier);
    final state = ref.read(memoryFeedDashboardProvider);

    // Load more for each section that has more data
    if (state.hasMoreHappeningNow && !state.isLoadingMore) {
      notifier.loadMoreHappeningNow();
    }
    if (state.hasMorePublicMemories && !state.isLoadingMore) {
      notifier.loadMorePublicMemories();
    }
    if (state.hasMoreTrending && !state.isLoadingMore) {
      notifier.loadMoreTrending();
    }
    if (state.hasMoreLongestStreak && !state.isLoadingMore) {
      notifier.loadMoreLongestStreak();
    }
    if (state.hasMorePopularUsers && !state.isLoadingMore) {
      notifier.loadMorePopularUsers();
    }
    if (state.hasMorePopularMemories && !state.isLoadingMore) {
      notifier.loadMorePopularMemories();
    }
  }

  Future<void> _checkAuthState() async {
    final client = SupabaseService.instance.client;
    if (client != null) {
      final session = client.auth.currentSession;
      setState(() {
        _isAuthenticated = session != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryFeedDashboardProvider);
    final notifier = ref.read(memoryFeedDashboardProvider.notifier);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: RefreshIndicator(
          color: appTheme.deep_purple_A100,
          backgroundColor: appTheme.gray_900_02,
          strokeWidth: 3.0,
          displacement: 40.0,
          onRefresh: () async {
            await notifier.refreshFeed();
          },
          child: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                  color: appTheme.gray_900_02,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    if (_isAuthenticated) _buildActionButton(context),
                    if (_isAuthenticated) SizedBox(height: 22.h),
                    if (!_isAuthenticated) SizedBox(height: 2.h),
                    _buildHappeningNowOrLatestSection(context),
                    _buildPublicMemoriesSection(context),
                    _buildTrendingStoriesSection(context),
                    if (_isAuthenticated) _buildCategoriesSection(context),
                    _buildLongestStreakSection(context),
                    _buildPopularMemoriesSection(context),
                    _buildPopularUsersSection(context),
                    if (state.isLoadingMore)
                      Padding(
                        padding: EdgeInsets.all(16.h),
                        child: CircularProgressIndicator(
                          color: appTheme.deep_purple_A100,
                        ),
                      ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgPlayCircle,
            height: 24.h,
            width: 24.h,
            color: appTheme.deep_purple_A100,
          ),
          SizedBox(width: 8.h),
          Text(
            'Start Memory',
            style: TextStyleHelper.instance.title20BoldPlusJakartaSans.copyWith(
              color: appTheme.deep_purple_A100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final activeMemories = state.activeMemories;

        if (activeMemories.isEmpty) {
          // Show "Create Memory" button when no active memories
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.h),
            child: CustomButton(
              text: 'Create Memory',
              width: double.infinity,
              leftIcon: ImageConstant.imgIcon20x20,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CreateMemoryScreen(),
                );
              },
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          );
        } else {
          // Show "Create Story" button when user has active memories
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.h),
            child: CustomButton(
              text: 'Create Story',
              width: double.infinity,
              leftIcon: ImageConstant.imgIcon20x20,
              onPressed: () => _onCreateStoryTap(context, activeMemories),
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          );
        }
      },
    );
  }

  void _onCreateStoryTap(
      BuildContext context, List<Map<String, dynamic>> activeMemories) {
    if (activeMemories.length == 1) {
      // Navigate directly to native camera with single memory
      final memory = activeMemories[0];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NativeCameraRecordingScreen(
            memoryId: memory['id'],
            memoryTitle: memory['title'],
            categoryIcon: memory['category_icon'],
          ),
        ),
      );
    } else {
      // Show memory selection bottom sheet for multiple memories
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const MemorySelectionBottomSheet(),
      );
    }
  }

  void _showMemorySelectionBottomSheet(
      BuildContext context, List<Map<String, dynamic>> activeMemories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.gray_900_02,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Memory',
                style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose which memory to post your story to',
                style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 24.h),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: activeMemories.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final memory = activeMemories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMemoryUploadScreen(),
                          settings: RouteSettings(
                            arguments: {
                              'memory_id': memory['id'],
                              'memory_title': memory['title'],
                              'category_icon': memory['category_icon'],
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.h),
                      decoration: BoxDecoration(
                        color: appTheme.blue_gray_900_01,
                        borderRadius: BorderRadius.circular(12.h),
                        border: Border.all(
                          color: appTheme.blue_gray_300.withAlpha(51),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (memory['category_icon'] != null &&
                              memory['category_icon'].toString().isNotEmpty)
                            CustomImageView(
                              imagePath: memory['category_icon'],
                              width: 32.h,
                              height: 32.h,
                              fit: BoxFit.contain,
                            ),
                          SizedBox(width: 12.h),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  memory['title'] ?? 'Untitled Memory',
                                  style: TextStyleHelper
                                      .instance.title16BoldPlusJakartaSans
                                      .copyWith(color: appTheme.gray_50),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  memory['category_name'] ?? 'Custom',
                                  style: TextStyleHelper
                                      .instance.body12MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                              ],
                            ),
                          ),
                          CustomImageView(
                            imagePath: ImageConstant.imgArrowLeft,
                            width: 20.h,
                            height: 20.h,
                            color: appTheme.gray_50,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  /// NEW METHOD: Build Happening Now or Latest Stories section based on data availability
  Widget _buildHappeningNowOrLatestSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final happeningNowStories =
            state.memoryFeedDashboardModel?.happeningNowStories ?? [];
        final latestStories =
            state.memoryFeedDashboardModel?.latestStories ?? [];
        final isLoading = state.isLoading ?? false;

        // If happening now has stories, show it
        if (happeningNowStories.isNotEmpty) {
          return _buildHappeningNowSection(context);
        }

        // Otherwise show Latest Stories
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgIconDeepPurpleA10022x22,
                    height: 22.h,
                    width: 22.h,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Latest Stories',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 240.h,
              child: isLoading
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 24.h),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 140.h,
                          margin: EdgeInsets.only(right: 12.h),
                          child: CustomStorySkeleton(),
                        );
                      },
                    )
                  : latestStories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImageView(
                                  imagePath:
                                      ImageConstant.imgIconDeepPurpleA10022x22,
                                  height: 48.h,
                                  width: 48.h,
                                  color: appTheme.blue_gray_300,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No stories yet',
                                  style: TextStyleHelper
                                      .instance.title16MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Create your first story',
                                  style: TextStyleHelper
                                      .instance.body12MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 24.h),
                          itemCount: latestStories.length,
                          itemBuilder: (context, index) {
                            final story = latestStories[index];
                            return HappeningNowStoryCard(
                              story: story,
                              onTap: () {
                                // Create feed context with all story IDs from latest stories feed
                                final feedContext = FeedStoryContext(
                                  feedType: 'latest_stories',
                                  storyIds: latestStories
                                      .map((s) => s.storyId)
                                      .where((id) => id.isNotEmpty)
                                      .toList(),
                                  initialStoryId: story.storyId,
                                );

                                NavigatorService.pushNamed(
                                  AppRoutes.appStoryView,
                                  arguments: feedContext,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHappeningNowSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final stories =
            state.memoryFeedDashboardModel?.happeningNowStories ?? [];
        final isLoading = state.isLoading ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgIconDeepPurpleA10022x22,
                    height: 22.h,
                    width: 22.h,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Happening Now',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 240.h,
              child: isLoading
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 24.h),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 140.h,
                          margin: EdgeInsets.only(right: 12.h),
                          child: CustomStorySkeleton(),
                        );
                      },
                    )
                  : stories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImageView(
                                  imagePath:
                                      ImageConstant.imgIconDeepPurpleA10022x22,
                                  height: 48.h,
                                  width: 48.h,
                                  color: appTheme.blue_gray_300,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No stories happening now',
                                  style: TextStyleHelper
                                      .instance.title16MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Check back later for new stories',
                                  style: TextStyleHelper
                                      .instance.body12MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 24.h),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return HappeningNowStoryCard(
                              story: story,
                              onTap: () {
                                // Create feed context with all story IDs from happening now feed
                                final feedContext = FeedStoryContext(
                                  feedType: 'happening_now',
                                  storyIds: stories
                                      .map((s) => s.storyId)
                                      .where((id) => id.isNotEmpty)
                                      .toList(),
                                  initialStoryId: story.storyId,
                                );

                                NavigatorService.pushNamed(
                                  AppRoutes.appStoryView,
                                  arguments: feedContext,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPublicMemoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final memories = state.memoryFeedDashboardModel?.publicMemories ?? [];
        final isLoading = state.isLoading ?? false;

        // Convert memory_feed_dashboard_model.CustomMemoryItem to custom_public_memories.CustomMemoryItem
        final convertedMemories = memories.map((memory) {
          return custom_widget.CustomMemoryItem(
            id: memory.id,
            title: memory.title,
            date: memory.date,
            iconPath: memory.iconPath,
            profileImages: memory.profileImages,
            mediaItems: memory.mediaItems?.map((item) {
              return custom_widget.CustomMediaItem(
                imagePath: item.imagePath,
                hasPlayButton: item.hasPlayButton ?? false,
              );
            }).toList(),
            startDate: memory.startDate,
            startTime: memory.startTime,
            endDate: memory.endDate,
            endTime: memory.endTime,
            location: memory.location,
            distance: memory.distance,
            isLiked: memory.isLiked,
          );
        }).toList();

        return custom_widget.CustomPublicMemories(
          sectionTitle: 'Public Memories',
          sectionIcon: ImageConstant.imgIcon22x22,
          memories: convertedMemories,
          isLoading: isLoading,
          onMemoryTap: (memory) {
            // CRITICAL FIX: Use validated navigation wrapper
            MemoryNavigationWrapper.navigateToTimeline(
              context: context,
              memoryId: memory.id ?? '',
              title: memory.title,
              date: memory.date,
              location: memory.location,
              categoryIcon: memory.iconPath,
              participantAvatars: memory.profileImages,
              isPrivate: false, // Public memories are never private
            );
          },
          margin: EdgeInsets.only(top: 30.h),
        );
      },
    );
  }

  Widget _buildPopularMemoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final memories = state.memoryFeedDashboardModel?.publicMemories ?? [];
        final isLoading = state.isLoading ?? false;

        // Convert memory_feed_dashboard_model.CustomMemoryItem to custom_public_memories.CustomMemoryItem
        final convertedMemories = memories.map((memory) {
          return custom_widget.CustomMemoryItem(
            id: memory.id,
            title: memory.title,
            date: memory.date,
            iconPath: memory.iconPath,
            profileImages: memory.profileImages,
            mediaItems: memory.mediaItems?.map((item) {
              return custom_widget.CustomMediaItem(
                imagePath: item.imagePath,
                hasPlayButton: item.hasPlayButton ?? false,
              );
            }).toList(),
            startDate: memory.startDate,
            startTime: memory.startTime,
            endDate: memory.endDate,
            endTime: memory.endTime,
            location: memory.location,
            distance: memory.distance,
            isLiked: memory.isLiked,
          );
        }).toList();

        return custom_widget.CustomPublicMemories(
          sectionTitle: 'Popular Memories',
          sectionIcon: ImageConstant.imgIconRed500,
          memories: convertedMemories,
          isLoading: isLoading,
          onMemoryTap: (memory) {
            // CRITICAL FIX: Use validated navigation wrapper
            MemoryNavigationWrapper.navigateToTimeline(
              context: context,
              memoryId: memory.id ?? '',
              title: memory.title,
              date: memory.date,
              location: memory.location,
              categoryIcon: memory.iconPath,
              participantAvatars: memory.profileImages,
              isPrivate: false, // Popular memories are public
            );
          },
          margin: EdgeInsets.only(top: 30.h),
        );
      },
    );
  }

  Widget _buildTrendingStoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final stories = state.memoryFeedDashboardModel?.trendingStories ?? [];
        final isLoading = state.isLoading ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgIconBlueA700,
                    height: 22.h,
                    width: 22.h,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Trending Stories',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 240.h,
              child: isLoading
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 24.h),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 140.h,
                          margin: EdgeInsets.only(right: 12.h),
                          child: CustomStorySkeleton(),
                        );
                      },
                    )
                  : stories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImageView(
                                  imagePath: ImageConstant.imgIconBlueA700,
                                  height: 48.h,
                                  width: 48.h,
                                  color: appTheme.blue_gray_300,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No trending stories yet',
                                  style: TextStyleHelper
                                      .instance.title16MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Check back later for trending content',
                                  style: TextStyleHelper
                                      .instance.body12MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 24.h),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return HappeningNowStoryCard(
                              story: story,
                              onTap: () {
                                // Create feed context with all story IDs from trending feed
                                final feedContext = FeedStoryContext(
                                  feedType: 'trending',
                                  storyIds: stories
                                      .map((s) => s.storyId)
                                      .where((id) => id.isNotEmpty)
                                      .toList(),
                                  initialStoryId: story.storyId,
                                );

                                NavigatorService.pushNamed(
                                  AppRoutes.appStoryView,
                                  arguments: feedContext,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final notifier = ref.read(memoryFeedDashboardProvider.notifier);

        // Trigger loading categories if not already loaded
        if (!state.isLoadingCategories && (state.categories?.isEmpty ?? true)) {
          Future.microtask(() => notifier.loadCategories());
        }

        final categories = state.categories ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgPlayCircle,
                    height: 22.h,
                    width: 22.h,
                    color: appTheme.deep_purple_A100,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Start Memory',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 100.h,
              child: state.isLoadingCategories
                  ? Center(
                      child: CircularProgressIndicator(
                        color: appTheme.deep_purple_A100,
                      ),
                    )
                  : categories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.h),
                            child: Text(
                              'No categories available',
                              style: TextStyleHelper
                                  .instance.body14MediumPlusJakartaSans
                                  .copyWith(color: appTheme.blue_gray_300),
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 24.h, right: 12.h),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return CustomCategoryBadge(
                              iconUrl: category['icon_url'] ?? '',
                              title: category['name'] ?? '',
                              description: category['tagline'] ?? '',
                              backgroundColor: appTheme.gray_900_01,
                              onTap: () {
                                // Pass selected category ID to CreateMemoryScreen
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CreateMemoryScreen(
                                    preSelectedCategoryId:
                                        category['id'] as String?,
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLongestStreakSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final stories =
            state.memoryFeedDashboardModel?.longestStreakStories ?? [];
        final isLoading = state.isLoading ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    size: 22.h,
                    color: appTheme.deep_purple_A100,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Longest Streaks',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 240.h,
              child: isLoading
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 24.h),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 140.h,
                          margin: EdgeInsets.only(right: 12.h),
                          child: CustomStorySkeleton(),
                        );
                      },
                    )
                  : stories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImageView(
                                  imagePath:
                                      ImageConstant.imgIconDeepPurpleA10022x22,
                                  height: 48.h,
                                  width: 48.h,
                                  color: appTheme.blue_gray_300,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No streak stories yet',
                                  style: TextStyleHelper
                                      .instance.title16MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Check back for consistent creators',
                                  style: TextStyleHelper
                                      .instance.body12MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 24.h),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return HappeningNowStoryCard(
                              story: story,
                              onTap: () {
                                final feedContext = FeedStoryContext(
                                  feedType: 'longest_streaks',
                                  storyIds: stories
                                      .map((s) => s.storyId)
                                      .where((id) => id.isNotEmpty)
                                      .toList(),
                                  initialStoryId: story.storyId,
                                );

                                NavigatorService.pushNamed(
                                  AppRoutes.appStoryView,
                                  arguments: feedContext,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPopularUsersSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final stories =
            state.memoryFeedDashboardModel?.popularUserStories ?? [];
        final isLoading = state.isLoading ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  CustomImageView(
                    imagePath: ImageConstant.imgIconGreen500,
                    height: 22.h,
                    width: 22.h,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Popular Users',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 240.h,
              child: isLoading
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 24.h),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 140.h,
                          margin: EdgeInsets.only(right: 12.h),
                          child: CustomStorySkeleton(),
                        );
                      },
                    )
                  : stories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImageView(
                                  imagePath: ImageConstant.imgIconGreen500,
                                  height: 48.h,
                                  width: 48.h,
                                  color: appTheme.blue_gray_300,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'No popular users yet',
                                  style: TextStyleHelper
                                      .instance.title16MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Check back for trending creators',
                                  style: TextStyleHelper
                                      .instance.body12MediumPlusJakartaSans
                                      .copyWith(color: appTheme.blue_gray_300),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: 24.h),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return HappeningNowStoryCard(
                              story: story,
                              onTap: () {
                                final feedContext = FeedStoryContext(
                                  feedType: 'popular_users',
                                  storyIds: stories
                                      .map((s) => s.storyId)
                                      .where((id) => id.isNotEmpty)
                                      .toList(),
                                  initialStoryId: story.storyId,
                                );

                                NavigatorService.pushNamed(
                                  AppRoutes.appStoryView,
                                  arguments: feedContext,
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  /// CRITICAL FIX: Use MemoryNavArgs for memory card navigation
  void _onMemoryCardTap(BuildContext context, dynamic memoryData) {
    print('🔍 FEED NAVIGATION: Memory card tapped');

    // Extract memory ID
    String? memoryId;
    if (memoryData is Map<String, dynamic>) {
      memoryId = memoryData['id'] as String?;
    }

    // Validate memory ID
    if (memoryId == null || memoryId.isEmpty) {
      print('❌ FEED NAVIGATION: Missing memory ID');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open memory - missing ID'),
          backgroundColor: appTheme.red_500,
        ),
      );
      return;
    }

    // Create MemoryNavArgs with snapshot
    final navArgs = MemoryNavArgs(
      memoryId: memoryId,
      snapshot: memoryData is Map<String, dynamic>
          ? MemorySnapshot.fromMap(memoryData)
          : null,
    );

    print('✅ FEED NAVIGATION: Passing MemoryNavArgs to timeline');
    print('   - Memory ID: ${navArgs.memoryId}');

    NavigatorService.pushNamed(
      AppRoutes.appTimeline,
      arguments: navArgs,
    );
  }
}
