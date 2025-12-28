import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../core/utils/memory_navigation_wrapper.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_public_memories.dart' as custom_widget;
import '../create_memory_screen/create_memory_screen.dart';
import '../event_stories_view_screen/models/event_stories_view_model.dart';
import './widgets/happening_now_story_card.dart';
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

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: appTheme.gray_900_02,
              ),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  if (_isAuthenticated) _buildCreateMemoryButton(context),
                  if (_isAuthenticated) SizedBox(height: 22.h),
                  if (!_isAuthenticated) SizedBox(height: 2.h),
                  _buildHappeningNowSection(context),
                  _buildPublicMemoriesSection(context),
                  _buildTrendingStoriesSection(context),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateMemoryButton(BuildContext context) {
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
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.h),
                        child: CircularProgressIndicator(
                          color: appTheme.deep_purple_A100,
                        ),
                      ),
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
                                      .map((s) => s.id ?? '')
                                      .where((id) => id.isNotEmpty)
                                      .toList(),
                                  initialStoryId: story.id ?? '',
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
          margin: EdgeInsets.only(top: 30.h, left: 24.h),
        );
      },
    );
  }

  Widget _buildTrendingStoriesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryFeedDashboardProvider);
        final stories = state.memoryFeedDashboardModel?.trendingStories ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              child: ListView.builder(
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
                            .map((s) => s.id ?? '')
                            .where((id) => id.isNotEmpty)
                            .toList(),
                        initialStoryId: story.id ?? '',
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
