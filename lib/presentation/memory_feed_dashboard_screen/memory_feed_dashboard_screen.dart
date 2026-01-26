import '../../core/app_export.dart';
import '../../core/models/feed_story_context.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../core/utils/memory_navigation_wrapper.dart';
import '../../services/network_connectivity_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_category_badge.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_public_memories.dart' as custom_widget;
import '../../widgets/custom_story_skeleton.dart';
import '../add_memory_upload_screen/add_memory_upload_screen.dart';
import '../create_memory_screen/create_memory_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  @override
  void dispose() {
    super.dispose();
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
    final notifier = ref.read(memoryFeedDashboardProvider.notifier);
    final bool offline = ref.watch(isOfflineProvider).valueOrNull ?? false;
    final hasDbConnectionError = ref.watch(
      memoryFeedDashboardProvider.select((s) => s.hasDbConnectionError),
    );

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: RefreshIndicator(
        color: appTheme.deep_purple_A100,
        backgroundColor: appTheme.gray_900_02,
        strokeWidth: 3.0,
        displacement: 40.0,
        onRefresh: () async {
          await notifier.refreshFeed();
        },
        child: SizedBox(
          width: double.maxFinite,
          child: (offline || hasDbConnectionError)
              ? LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Align(
                    alignment: const Alignment(0, -0.1), // slight upward pull
                    child: _buildNoConnectionEmptyState(),
                  ),
                ),
              );
            },
          )
              : SingleChildScrollView(
            key: const PageStorageKey<String>('memory_feed_scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: appTheme.gray_900_02,
              ),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  _buildActionButton(context),
                  SizedBox(height: 22.h),
                  _buildHappeningNowOrLatestSection(context),
                  if (_isAuthenticated) _buildFromFriendsSection(context),
                  if (_isAuthenticated) _buildForYouSection(context),
                  _buildPublicMemoriesSection(context),
                  _buildTrendingStoriesSection(context),
                  _buildPopularNowSection(context),
                  if (_isAuthenticated) _buildCategoriesSection(context),
                  _buildLongestStreakSection(context),
                  _buildPopularMemoriesSection(context),
                  _buildPopularUsersSection(context),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoConnectionEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64.h,
            color: appTheme.blue_gray_300,
          ),
          SizedBox(height: 10.h),
          Text(
            'No connection',
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans.copyWith(
              color: appTheme.blue_gray_300,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Connect to the internet and pull to refresh.',
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
              color: appTheme.blue_gray_300,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTitleBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_filled,
            size: 24.h,
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
    // ✅ If not authenticated, show login CTA
    if (!_isAuthenticated) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.h),
        child: CustomButton(
          text: 'Log in to Create Memory',
          width: double.infinity,
          onPressed: () {
            NavigatorService.pushNamed(AppRoutes.authLogin);
          },
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
        ),
      );
    }

    // ✅ Authenticated: keep existing state-dependent behavior
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final activeMemories = state.activeMemories;
        final isLoadingActiveMemories = state.isLoadingActiveMemories;

        // Show skeleton loader while loading active memories
        if (isLoadingActiveMemories) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.h),
            child: _buildActionButtonSkeleton(),
          );
        }

        if (activeMemories.isEmpty) {
          // Show "Create Memory" button when no active memories
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.h),
            child: CustomButton(
              text: 'Create Memory',
              width: double.infinity,
              leftIcon: Icons.add,
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
              leftIcon: Icons.add,
              onPressed: () => _onCreateStoryTap(context, activeMemories),
              buttonStyle: CustomButtonStyle.fillPrimary,
              buttonTextStyle: CustomButtonTextStyle.bodyMedium,
            ),
          );
        }
      },
    );
  }

  /// Build skeleton loader for action button
  Widget _buildActionButtonSkeleton() {
    return SizedBox(
      height: 56.h, // EXACT match to CustomButton
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appTheme.blue_gray_900_01,
          borderRadius: BorderRadius.circular(6.h), // match button radius
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20.h,
                height: 20.h,
                decoration: BoxDecoration(
                  color: appTheme.blue_gray_300.withAlpha(77),
                  borderRadius: BorderRadius.circular(4.h),
                ),
              ),
              SizedBox(width: 8.h),
              Container(
                width: 110.h, // closer to real text width
                height: 16.h,
                decoration: BoxDecoration(
                  color: appTheme.blue_gray_300.withAlpha(77),
                  borderRadius: BorderRadius.circular(4.h),
                ),
              ),
            ],
          ),
        ),
      ),
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

  // ignore: unused_element
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
                          builder: (context) => AddMemoryUploadScreen(
                            memoryId: memory['id'],
                            memoryStartDate: DateTime.parse(
                                memory['start_date'] ??
                                    DateTime.now().toIso8601String()),
                            memoryEndDate: DateTime.parse(memory['end_date'] ??
                                DateTime.now().toIso8601String()),
                          ),
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
                          Icon(
                            Icons.chevron_right,
                            size: 20.h,
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

        // IMPORTANT:
        // Use skeleton only for initial/empty state to prevent "hard reload" flashes
        // when other sections load.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading &&
            happeningNowStories.isEmpty &&
            latestStories.isEmpty;

        // Hide section if both feeds are empty and not loading
        if (!isLoading && happeningNowStories.isEmpty && latestStories.isEmpty) {
          return const SizedBox.shrink();
        }

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
                  Icon(
                    Icons.schedule,
                    size: 22.h,
                    color: appTheme.deep_purple_A100,
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
                key: const PageStorageKey<String>('latest_stories_list'),
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
                      Icon(
                        Icons.schedule,
                        size: 48.h,
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
                key: const PageStorageKey<String>(
                    'latest_stories_list'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 24.h),
                itemCount: latestStories.length,
                itemBuilder: (context, index) {
                  final story = latestStories[index];
                  return HappeningNowStoryCard(
                    story: story,
                    onTap: () {
                      // Navigate directly without FeedStoryContext
                      NavigatorService.pushNamed(
                        AppRoutes.appStoryView,
                        arguments: story.storyId,
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

        // IMPORTANT:
        // Use skeleton only for initial/empty state to prevent "hard reload" flashes.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && stories.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                key: const PageStorageKey<String>('happening_now_list'),
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
                      Icon(
                        Icons.flash_on,
                        size: 48.h,
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
                key: const PageStorageKey<String>(
                    'happening_now_list'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 24.h),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return HappeningNowStoryCard(
                    story: story,
                    onTap: () {
                      // ✅ FIX: Pass feed type when navigating to story viewer
                      final args = FeedStoryContext(
                        feedType: 'happening_now',
                        initialStoryId: story.storyId,
                        storyIds:
                        stories.map((s) => s.storyId).toList(),
                      );

                      NavigatorService.pushNamed(
                        AppRoutes.appStoryView,
                        arguments: args,
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

        // IMPORTANT:
        // Prevent "hard reload" flashes: only show loading skeletons when the
        // section has no data yet.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && memories.isEmpty;

        // Hide section if empty and not loading
        if (!isLoading && memories.isEmpty) {
          return const SizedBox.shrink();
        }

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
          key: const PageStorageKey<String>('public_memories_section'),
          sectionTitle: 'Public Memories',
          sectionIcon: Icons.public,
          variant: custom_widget.MemoryCardVariant.feed,
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

        // ✅ FIX: Popular section must read popularMemories (not publicMemories)
        final memories = state.memoryFeedDashboardModel?.popularMemories ?? [];

        // IMPORTANT:
        // Prevent "hard reload" flashes: only show loading skeletons when empty.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && memories.isEmpty;

        // Hide section if empty and not loading
        if (!isLoading && memories.isEmpty) {
          return const SizedBox.shrink();
        }

        // Convert dashboard model items into the widget's item type
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
          key: const PageStorageKey<String>('popular_memories_section'),
          sectionTitle: 'Popular Memories',
          sectionIcon: Icons.favorite,
          memories: convertedMemories,
          isLoading: isLoading,
          onMemoryTap: (memory) {
            // ✅ HARD GUARD: Popular Memories are always public feed cards
            MemoryNavigationWrapper.navigateToTimeline(
              context: context,
              memoryId: memory.id ?? '',
              title: memory.title,
              date: memory.date,
              location: memory.location,
              categoryIcon: memory.iconPath,
              participantAvatars: memory.profileImages,
              isPrivate: false, // ✅ FIX: don't read memory.visibility
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

        // IMPORTANT:
        // Prevent "hard reload" flashes: only show loading skeletons when empty.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && stories.isEmpty;

        // Hide section if empty and not loading
        if (!isLoading && stories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 22.h,
                    color: appTheme.blue_A700,
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
                key:
                const PageStorageKey<String>('trending_stories_list'),
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
                      Icon(
                        Icons.trending_up,
                        size: 48.h,
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
                key: const PageStorageKey<String>(
                    'trending_stories_list'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 24.h),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return HappeningNowStoryCard(
                    story: story,
                    onTap: () {
                      // Navigate directly without FeedStoryContext
                      NavigatorService.pushNamed(
                        AppRoutes.appStoryView,
                        arguments: story.storyId,
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

  Widget _buildPopularNowSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final stories = state.memoryFeedDashboardModel?.popularNowStories ?? [];

        // IMPORTANT:
        // Prevent "hard reload" flashes: only show loading skeletons when empty.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && stories.isEmpty;

        // Hide section if empty and not loading
        if (!isLoading && stories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 22.h,
                    color: appTheme.colorFFD81E,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Popular Now',
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
                key:
                const PageStorageKey<String>('popular_now_list'),
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
                      Icon(
                        Icons.local_fire_department,
                        size: 48.h,
                        color: appTheme.blue_gray_300,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No popular stories yet',
                        style: TextStyleHelper
                            .instance.title16MediumPlusJakartaSans
                            .copyWith(color: appTheme.blue_gray_300),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Check back later for popular content',
                        style: TextStyleHelper
                            .instance.body12MediumPlusJakartaSans
                            .copyWith(color: appTheme.blue_gray_300),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                key: const PageStorageKey<String>(
                    'popular_now_list'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 24.h),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return HappeningNowStoryCard(
                    story: story,
                    onTap: () {
                      // Navigate with FeedStoryContext for proper feed navigation
                      final args = FeedStoryContext(
                        feedType: 'popular_now',
                        initialStoryId: story.storyId,
                        storyIds:
                        stories.map((s) => s.storyId).toList(),
                      );

                      NavigatorService.pushNamed(
                        AppRoutes.appStoryView,
                        arguments: args,
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

  Widget _buildFromFriendsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final stories = state.memoryFeedDashboardModel?.fromFriendsStories ?? [];

        // IMPORTANT:
        // Prevent "hard reload" flashes: only show loading skeletons when empty.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && stories.isEmpty;

        // Hide section if empty and not loading
        if (!isLoading && stories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 22.h,
                    color: appTheme.deep_purple_A100,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'From Friends',
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
                key: const PageStorageKey<String>('from_friends_list'),
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
                      Icon(
                        Icons.people,
                        size: 48.h,
                        color: appTheme.blue_gray_300,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No stories from friends yet',
                        style: TextStyleHelper
                            .instance.title16MediumPlusJakartaSans
                            .copyWith(color: appTheme.blue_gray_300),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Your friends haven\'t posted recently',
                        style: TextStyleHelper
                            .instance.body12MediumPlusJakartaSans
                            .copyWith(color: appTheme.blue_gray_300),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                key: const PageStorageKey<String>(
                    'from_friends_list'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 24.h),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return HappeningNowStoryCard(
                    story: story,
                    onTap: () {
                      // Navigate with FeedStoryContext for proper feed navigation
                      final args = FeedStoryContext(
                        feedType: 'from_friends',
                        initialStoryId: story.storyId,
                        storyIds:
                        stories.map((s) => s.storyId).toList(),
                      );

                      NavigatorService.pushNamed(
                        AppRoutes.appStoryView,
                        arguments: args,
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

  Widget _buildForYouSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final stories = state.memoryFeedDashboardModel?.forYouStories ?? [];

        // IMPORTANT:
        // Prevent "hard reload" flashes: only show loading skeletons when empty.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && stories.isEmpty;

        // Hide section if empty and not loading
        if (!isLoading && stories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 22.h,
                    color: appTheme.red_500,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'For You',
                    style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  SizedBox(width: 8.h),
                  Flexible(
                    child: Text(
                      'Friends & Following',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                          .copyWith(color: appTheme.blue_gray_300),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 240.h,
              child: isLoading
                  ? ListView.builder(
                key: const PageStorageKey<String>('for_you_list'),
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
                      Icon(
                        Icons.favorite,
                        size: 48.h,
                        color: appTheme.blue_gray_300,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No stories for you yet',
                        style: TextStyleHelper
                            .instance.title16MediumPlusJakartaSans
                            .copyWith(color: appTheme.blue_gray_300),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Follow people to see their stories',
                        style: TextStyleHelper
                            .instance.body12MediumPlusJakartaSans
                            .copyWith(color: appTheme.blue_gray_300),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                key: const PageStorageKey<String>(
                    'for_you_list'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 24.h),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return HappeningNowStoryCard(
                    story: story,
                    onTap: () {
                      // Navigate with FeedStoryContext for proper feed navigation
                      final args = FeedStoryContext(
                        feedType: 'for_you',
                        initialStoryId: story.storyId,
                        storyIds:
                        stories.map((s) => s.storyId).toList(),
                      );

                      NavigatorService.pushNamed(
                        AppRoutes.appStoryView,
                        arguments: args,
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

        final categories = state.categories ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    size: 22.h,
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
                key: const PageStorageKey<String>('categories_list'),
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

        // IMPORTANT:
        // Prevent "hard reload" flashes: only show loading skeletons when empty.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && stories.isEmpty;

        // Hide section if empty and not loading
        if (!isLoading && stories.isEmpty) {
          return const SizedBox.shrink();
        }

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
                key: const PageStorageKey<String>('longest_streak_list'),
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
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 48.h,
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
                key: const PageStorageKey<String>(
                    'longest_streak_list'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 24.h),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return HappeningNowStoryCard(
                    story: story,
                    onTap: () {
                      // Navigate directly without FeedStoryContext
                      NavigatorService.pushNamed(
                        AppRoutes.appStoryView,
                        arguments: story.storyId,
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

        // IMPORTANT:
        // Prevent "hard reload" flashes: only show loading skeletons when empty.
        final bool globalLoading = state.isLoading ?? false;
        final bool isLoading = globalLoading && stories.isEmpty;

        // Hide section if empty and not loading
        if (!isLoading && stories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 22.h,
                    color: appTheme.green_500,
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
                key: const PageStorageKey<String>('popular_users_list'),
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
                      Icon(
                        Icons.people_alt_outlined,
                        size: 48.h,
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
                key: const PageStorageKey<String>(
                    'popular_users_list'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: 24.h),
                itemCount: stories.length,
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return HappeningNowStoryCard(
                    story: story,
                    onTap: () {
                      // Navigate directly without FeedStoryContext
                      NavigatorService.pushNamed(
                        AppRoutes.appStoryView,
                        arguments: story.storyId,
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
  // ignore: unused_element
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