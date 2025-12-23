import '../../core/app_export.dart';
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
              child: ListView.builder(
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
            // Find the original database memory data to pass to timeline
            final originalMemory = memories.firstWhere(
              (m) => m.id == memory.id,
              orElse: () => memories.first,
            );

            // Convert back to Map<String, dynamic> for timeline notifier
            final memoryData = {
              'id': originalMemory.id,
              'title': originalMemory.title,
              'date': originalMemory.date,
              'category_icon': originalMemory.iconPath,
              'contributor_avatars': originalMemory.profileImages,
              'media_items': originalMemory.mediaItems
                      ?.map((item) => {
                            'thumbnail_url': item.imagePath,
                            'has_play_button': item.hasPlayButton ?? false,
                          })
                      .toList() ??
                  [],
              'start_date': originalMemory.startDate,
              'start_time': originalMemory.startTime,
              'end_date': originalMemory.endDate,
              'end_time': originalMemory.endTime,
              'location': originalMemory.location,
              'distance': originalMemory.distance,
            };

            // Navigate to timeline with proper database data structure
            NavigatorService.pushNamed(
              AppRoutes.appTimeline,
              arguments: memoryData,
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
}