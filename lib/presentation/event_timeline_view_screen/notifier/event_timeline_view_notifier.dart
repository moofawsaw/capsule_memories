import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_story_list.dart';
import '../models/event_timeline_view_model.dart';
import '../models/timeline_detail_model.dart';
import '../widgets/timeline_story_widget.dart';

part 'event_timeline_view_state.dart';

final eventTimelineViewNotifier = StateNotifierProvider.autoDispose<
    EventTimelineViewNotifier, EventTimelineViewState>(
  (ref) => EventTimelineViewNotifier(),
);

class EventTimelineViewNotifier extends StateNotifier<EventTimelineViewState> {
  final _storyService = StoryService();
  final _cacheService = MemoryCacheService();

  // CRITICAL FIX: Store story IDs for cycling functionality
  List<String> _currentMemoryStoryIds = [];

  EventTimelineViewNotifier() : super(EventTimelineViewState());

  // CRITICAL FIX: Add getter for story IDs to use in navigation
  List<String> get currentMemoryStoryIds => _currentMemoryStoryIds;

  void initializeFromMemory(dynamic memoryData) async {
    print('🚨 NOTIFIER DEBUG: initializeFromMemory called');
    print('   - Argument type: ${memoryData.runtimeType}');
    print('   - Is null: ${memoryData == null}');

    if (memoryData is Map<String, dynamic>) {
      // CRITICAL: Extract memory ID - this is used to fetch actual data
      final memoryId = memoryData['id'] as String? ?? '';

      print('🔍 NOTIFIER DEBUG: Processing memory data');
      print('   - Memory ID: "$memoryId"');
      print('   - Title: "${memoryData['title']}"');
      print('   - Date: "${memoryData['date']}"');
      print('   - Location: "${memoryData['location']}"');
      print('   - Event Date: "${memoryData['eventDate']}"');
      print('   - Event Time: "${memoryData['eventTime']}"');
      print('   - End Date: "${memoryData['endDate']}"');
      print('   - End Time: "${memoryData['endTime']}"');

      // Validate memory ID before proceeding
      if (memoryId.isEmpty) {
        print('❌ TIMELINE ERROR: No memory ID provided in arguments');
        state = state.copyWith(
          isLoading: false,
          eventTimelineViewModel: EventTimelineViewModel(
            eventTitle: 'Error',
            eventDate: 'Invalid memory',
            isPrivate: false,
            participantImages: [],
            customStoryItems: [],
            timelineDetail: TimelineDetailModel(
              centerLocation: 'Unknown',
              centerDistance: '0km',
            ),
          ),
        );
        return;
      }

      print('🔍 TIMELINE DEBUG: Initializing from memory ID: $memoryId');
      print('🔍 TIMELINE DEBUG: Full memory data: $memoryData');

      final memory = memoryData;

      // Use category icon URL directly from database data
      String? categoryIcon = memory['category_icon'] as String?;

      print('🔍 TIMELINE DEBUG: Category icon = "$categoryIcon"');

      // Get contributor avatars from memory data
      final contributorAvatars = memory['contributor_avatars'];
      print(
          '🔍 TIMELINE DEBUG: Raw contributor_avatars type: ${contributorAvatars.runtimeType}');
      print(
          '🔍 TIMELINE DEBUG: Raw contributor_avatars content: $contributorAvatars');

      List<String> participantImages = [];

      if (contributorAvatars != null) {
        if (contributorAvatars is List) {
          participantImages = contributorAvatars
              .map((e) => e.toString())
              .where((url) => url.isNotEmpty)
              .toList();
          print(
              '🔍 TIMELINE DEBUG: Processed ${participantImages.length} participant images from List');
        } else if (contributorAvatars is String) {
          participantImages = [contributorAvatars];
          print('🔍 TIMELINE DEBUG: Processed 1 participant image from String');
        }
      }

      // Log each avatar URL for debugging
      for (int i = 0; i < participantImages.length; i++) {
        print(
            '🔍 TIMELINE DEBUG: Participant avatar $i: ${participantImages[i]}');
      }

      // ONLY use fallback if we have NO avatars at all
      if (participantImages.isEmpty) {
        print(
            '⚠️ TIMELINE DEBUG: No participant avatars found, using fallback images');
        participantImages = [
          ImageConstant.imgFrame2,
          ImageConstant.imgFrame1,
          ImageConstant.imgEllipse81,
        ];
      } else {
        print(
            '✅ TIMELINE DEBUG: Using ${participantImages.length} real participant images');
      }

      // Initialize timeline detail from memory data
      TimelineDetailModel timelineDetail = TimelineDetailModel(
        centerLocation: memory['location'] as String? ?? 'Unknown Location',
        centerDistance: '0km',
      );

      print('🔍 TIMELINE DEBUG: Setting initial state with memory details');
      print('   - Title: ${memory['title']}');
      print('   - Date: ${memory['date']}');
      print('   - Location: ${memory['location']}');

      // Set initial state with memory details (before loading stories)
      state = state.copyWith(
        eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
          memoryId: memoryId,
          eventTitle: memory['title'] as String? ?? 'Memory Event',
          eventDate: memory['date'] as String? ?? 'Unknown Date',
          isPrivate: false,
          categoryIcon: categoryIcon ?? ImageConstant.imgFrame13,
          participantImages: participantImages,
          customStoryItems: [],
          timelineDetail: timelineDetail,
        ),
        isLoading: true,
      );

      print('✅ TIMELINE DEBUG: Initial state set, now fetching stories...');

      // CRITICAL: Fetch actual stories from database using memory ID
      print('🔄 TIMELINE DEBUG: Fetching stories for memory $memoryId...');
      await _loadMemoryStories(memoryId);

      // CRITICAL: Trigger cache refresh after viewing timeline
      print('🔄 TIMELINE DEBUG: Triggering cache refresh for /memories screen');
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser != null) {
        await _cacheService.refreshMemoryCache(currentUser.id);
        print('✅ TIMELINE DEBUG: Cache refresh complete');
      }

      state = state.copyWith(isLoading: false);
      print('✅ TIMELINE DEBUG: Timeline initialization complete');
      print('   - Final title: ${state.eventTimelineViewModel?.eventTitle}');
      print('   - Final date: ${state.eventTimelineViewModel?.eventDate}');
      print(
          '   - Final location: ${state.eventTimelineViewModel?.timelineDetail?.centerLocation}');
      print(
          '   - Stories count: ${state.eventTimelineViewModel?.customStoryItems?.length ?? 0}');
    } else {
      print(
          '❌ TIMELINE ERROR: Invalid memory data type: ${memoryData.runtimeType}');
      print('   - Expected: Map<String, dynamic>');
      print('   - Received: ${memoryData.runtimeType}');

      // Fall back to default initialization
      initialize();
    }
  }

  Future<void> _loadMemoryStories(String memoryId) async {
    try {
      print('🔍 TIMELINE DEBUG: Loading stories for memory: $memoryId');

      // Fetch stories from database
      final storiesData = await _storyService.fetchMemoryStories(memoryId);

      print(
          '🔍 TIMELINE DEBUG: Fetched ${storiesData.length} stories from database');

      // CRITICAL FIX: Extract story IDs in order for cycling
      _currentMemoryStoryIds =
          storiesData.map((storyData) => storyData['id'] as String).toList();

      print(
          '🔍 TIMELINE DEBUG: Story IDs for cycling: $_currentMemoryStoryIds');

      // CRITICAL FIX: Use memory's actual start_time and end_time window
      // This represents the ACTUAL EVENT DURATION when stories should be positioned
      final memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('start_time, end_time')
          .eq('id', memoryId)
          .single();

      DateTime memoryStartTime;
      DateTime memoryEndTime;

      if (memoryResponse != null &&
          memoryResponse['start_time'] != null &&
          memoryResponse['end_time'] != null) {
        // Use actual event window from database
        memoryStartTime =
            DateTime.parse(memoryResponse['start_time'] as String);
        memoryEndTime = DateTime.parse(memoryResponse['end_time'] as String);

        print('✅ TIMELINE DEBUG: Using memory window timestamps:');
        print('   - Event start: $memoryStartTime');
        print('   - Event end: $memoryEndTime');
        print(
            '   - Event duration: ${memoryEndTime.difference(memoryStartTime).inMinutes} minutes');
      } else {
        // Fallback: use story timestamps if memory window not available
        if (storiesData.isNotEmpty) {
          final storyTimes = storiesData
              .map((s) => DateTime.parse(s['created_at'] as String))
              .toList();
          storyTimes.sort();

          memoryStartTime = storyTimes.first;
          memoryEndTime = storyTimes.last;

          // Add padding
          final padding = memoryEndTime.difference(memoryStartTime) * 0.1;
          memoryStartTime = memoryStartTime.subtract(padding);
          memoryEndTime = memoryEndTime.add(padding);

          print(
              '⚠️ TIMELINE DEBUG: Memory window unavailable, using story range with padding');
          print('   - Earliest story: ${storyTimes.first}');
          print('   - Latest story: ${storyTimes.last}');
        } else {
          // Ultimate fallback
          memoryEndTime = DateTime.now();
          memoryStartTime = memoryEndTime.subtract(Duration(hours: 2));
          print('⚠️ TIMELINE DEBUG: Using default 2-hour fallback window');
        }
      }

      // Convert to CustomStoryItem format for horizontal story list
      final storyItems = storiesData.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(storyData['created_at'] as String);

        final backgroundImage = _storyService.getStoryMediaUrl(storyData);
        final profileImage = AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'] as String?,
        );

        return CustomStoryItem(
          backgroundImage: backgroundImage,
          profileImage: profileImage,
          timestamp: _storyService.getTimeAgo(createdAt),
          navigateTo: storyData['id'] as String,
        );
      }).toList();

      // Create timeline story items positioned within memory window
      final timelineStories = storiesData.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(storyData['created_at'] as String);
        final storyId = storyData['id'] as String;

        final backgroundImage = _storyService.getStoryMediaUrl(storyData);
        final profileImage = AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'] as String?,
        );

        print('🔍 TIMELINE STORY: $storyId');
        print('   - Posted at: $createdAt');
        print(
            '   - Minutes after event start: ${createdAt.difference(memoryStartTime).inMinutes}');

        return TimelineStoryItem(
          backgroundImage: backgroundImage,
          userAvatar: profileImage,
          postedAt: createdAt,
          timeLabel: _storyService.getTimeAgo(createdAt),
          storyId: storyId,
        );
      }).toList();

      // Update state with memory window timeline
      state = state.copyWith(
        eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
          customStoryItems: storyItems,
          timelineDetail: TimelineDetailModel(
            centerLocation:
                state.eventTimelineViewModel?.timelineDetail?.centerLocation ??
                    'Unknown Location',
            centerDistance:
                state.eventTimelineViewModel?.timelineDetail?.centerDistance ??
                    '0km',
            memoryStartTime: memoryStartTime,
            memoryEndTime: memoryEndTime,
            timelineStories: timelineStories,
          ),
        ),
        errorMessage: null,
      );

      print('✅ TIMELINE DEBUG: Timeline updated with memory window');
      print('   - ${storyItems.length} horizontal story items');
      print('   - ${timelineStories.length} positioned timeline stories');
      print(
          '   - Timeline window: $memoryStartTime to $memoryEndTime (${memoryEndTime.difference(memoryStartTime).inMinutes} min)');
    } catch (e, stackTrace) {
      print('❌ TIMELINE DEBUG: Error loading memory stories: $e');
      print('❌ TIMELINE DEBUG: Stack trace: $stackTrace');

      // CRITICAL FIX: Set error state instead of silently failing
      state = state.copyWith(
        errorMessage: 'Failed to load memory data. Please try refreshing.',
        isLoading: false,
      );
    }
  }

  void initialize() {
    // Initialize story items as CustomStoryItem
    List<CustomStoryItem> storyItems = [
      CustomStoryItem(
        backgroundImage: ImageConstant.imgImage8202x116,
        profileImage: ImageConstant.imgEllipse826x26,
        timestamp: '5 mins ago',
      ),
      CustomStoryItem(
        backgroundImage: ImageConstant.imgImage8120x90,
        profileImage: ImageConstant.imgFrame2,
        timestamp: '12 mins ago',
      ),
      CustomStoryItem(
        backgroundImage: ImageConstant.imgImage8,
        profileImage: ImageConstant.imgFrame1,
        timestamp: '23 mins ago',
      ),
      CustomStoryItem(
        backgroundImage: ImageConstant.imgImg,
        profileImage: ImageConstant.imgEllipse81,
        timestamp: '1 hour ago',
      ),
      CustomStoryItem(
        backgroundImage: ImageConstant.imgImage81,
        profileImage: ImageConstant.imgEllipse826x26,
        timestamp: '2 hours ago',
      ),
    ];

    // Initialize timeline with positioned stories
    final now = DateTime.now();
    final memoryStart = now.subtract(Duration(hours: 2));
    final memoryEnd = now;

    final timelineStories = [
      TimelineStoryItem(
        backgroundImage: ImageConstant.imgImage9,
        userAvatar: ImageConstant.imgEllipse826x26,
        postedAt: memoryStart.add(Duration(minutes: 15)),
        onTap: () {},
      ),
      TimelineStoryItem(
        backgroundImage: ImageConstant.imgImage81,
        userAvatar: ImageConstant.imgEllipse842x42,
        postedAt: memoryStart.add(Duration(minutes: 45)),
        onTap: () {},
      ),
      TimelineStoryItem(
        backgroundImage: ImageConstant.imgImage8202x116,
        userAvatar: ImageConstant.imgEllipse8DeepOrange100,
        postedAt: memoryStart.add(Duration(minutes: 90)),
        onTap: () {},
      ),
    ];

    state = state.copyWith(
      eventTimelineViewModel: EventTimelineViewModel(
        eventTitle: 'Nixon Wedding 2025',
        eventDate: 'Dec 4, 2025',
        isPrivate: true,
        participantImages: [
          ImageConstant.imgFrame2,
          ImageConstant.imgFrame1,
          ImageConstant.imgEllipse81,
        ],
        customStoryItems: storyItems,
        timelineDetail: TimelineDetailModel(
          centerLocation: "Tillsonburg, ON",
          centerDistance: "21km",
          memoryStartTime: memoryStart,
          memoryEndTime: memoryEnd,
          timelineStories: timelineStories,
        ),
      ),
      isLoading: false,
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return 'Dec ${date.day}';
      }
    } catch (e) {
      return '2 mins ago';
    }
  }

  void updateStoriesCount(int count) {
    state = state.copyWith(
      eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(),
    );
  }

  void refreshData() {
    state = state.copyWith(isLoading: true);
    initialize();
  }
}
