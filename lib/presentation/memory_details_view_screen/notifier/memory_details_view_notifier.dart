import '../../../core/app_export.dart';
import '../../../core/utils/memory_nav_args.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_story_list.dart';
import '../models/memory_details_view_model.dart';
import '../models/timeline_detail_model.dart';
import '../widgets/timeline_story_widget.dart';

part 'memory_details_view_state.dart';

final memoryDetailsViewNotifier = StateNotifierProvider.autoDispose<
    MemoryDetailsViewNotifier, MemoryDetailsViewState>(
  (ref) => MemoryDetailsViewNotifier(),
);

class MemoryDetailsViewNotifier extends StateNotifier<MemoryDetailsViewState> {
  final _storyService = StoryService();
  final _cacheService = MemoryCacheService();

  List<String> _currentMemoryStoryIds = [];

  MemoryDetailsViewNotifier() : super(MemoryDetailsViewState());

  List<String> get currentMemoryStoryIds => _currentMemoryStoryIds;

  void initializeFromMemory(MemoryNavArgs navArgs) async {
    print('🚨 SEALED NOTIFIER: initializeFromMemory with MemoryNavArgs');
    print('   - Memory ID: ${navArgs.memoryId}');
    print('   - Has snapshot: ${navArgs.snapshot != null}');

    if (!navArgs.isValid) {
      print('❌ SEALED NOTIFIER: Invalid memory ID');
      setErrorState('Invalid memory ID provided');
      return;
    }

    if (navArgs.snapshot != null) {
      print('✅ SEALED NOTIFIER: Displaying snapshot while loading full data');
      _displaySnapshot(navArgs.snapshot!);
    }

    state = state.copyWith(isLoading: true);

    await _loadMemoryStories(navArgs.memoryId);

    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser != null) {
      await _cacheService.refreshMemoryCache(currentUser.id);
    }

    state = state.copyWith(isLoading: false);
  }

  void _displaySnapshot(MemorySnapshot snapshot) {
    state = state.copyWith(
      memoryDetailsViewModel: MemoryDetailsViewModel(
        eventTitle: snapshot.title,
        eventDate: snapshot.date,
        isPrivate: snapshot.isPrivate,
        categoryIcon: snapshot.categoryIcon ?? ImageConstant.imgFrame13,
        participantImages: snapshot.participantAvatars ?? [],
        customStoryItems: [],
        timelineDetail: TimelineDetailModel(
          centerLocation: snapshot.location ?? 'Unknown',
          centerDistance: '0km',
        ),
      ),
    );
  }

  void setErrorState(String message) {
    state = state.copyWith(
      errorMessage: message,
      isLoading: false,
    );
  }

  Future<void> _loadMemoryStories(String memoryId) async {
    try {
      print('🔍 SEALED DEBUG: Loading stories for memory: $memoryId');

      final storiesData = await _storyService.fetchMemoryStories(memoryId);

      print(
          '🔍 SEALED DEBUG: Fetched ${storiesData.length} stories from database');

      _currentMemoryStoryIds =
          storiesData.map((storyData) => storyData['id'] as String).toList();

      print('🔍 SEALED DEBUG: Story IDs for cycling: $_currentMemoryStoryIds');

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
        memoryStartTime =
            DateTime.parse(memoryResponse['start_time'] as String);
        memoryEndTime = DateTime.parse(memoryResponse['end_time'] as String);

        print('✅ SEALED DEBUG: Using memory window timestamps:');
        print('   - Event start: $memoryStartTime');
        print('   - Event end: $memoryEndTime');
      } else {
        if (storiesData.isNotEmpty) {
          final storyTimes = storiesData
              .map((s) => DateTime.parse(s['created_at'] as String))
              .toList();
          storyTimes.sort();

          memoryStartTime = storyTimes.first;
          memoryEndTime = storyTimes.last;

          final padding = memoryEndTime.difference(memoryStartTime) * 0.1;
          memoryStartTime = memoryStartTime.subtract(padding);
          memoryEndTime = memoryEndTime.add(padding);
        } else {
          memoryEndTime = DateTime.now();
          memoryStartTime = memoryEndTime.subtract(Duration(hours: 2));
        }
      }

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

      final timelineStories = storiesData.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(storyData['created_at'] as String);
        final storyId = storyData['id'] as String;

        final backgroundImage = _storyService.getStoryMediaUrl(storyData);
        final profileImage = AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'] as String?,
        );

        return TimelineStoryItem(
          backgroundImage: backgroundImage,
          userAvatar: profileImage,
          postedAt: createdAt,
          timeLabel: _storyService.getTimeAgo(createdAt),
          storyId: storyId,
        );
      }).toList();

      state = state.copyWith(
        memoryDetailsViewModel: state.memoryDetailsViewModel?.copyWith(
          timelineDetail: TimelineDetailModel(
            centerLocation:
                state.memoryDetailsViewModel?.timelineDetail?.centerLocation ??
                    'Unknown Location',
            centerDistance:
                state.memoryDetailsViewModel?.timelineDetail?.centerDistance ??
                    '0km',
            memoryStartTime: memoryStartTime,
            memoryEndTime: memoryEndTime,
            timelineStories: timelineStories,
          ),
        ),
        errorMessage: null,
      );

      print('✅ SEALED DEBUG: Timeline updated with memory window');
    } catch (e, stackTrace) {
      print('❌ SEALED DEBUG: Error loading memory stories: $e');
      print('❌ SEALED DEBUG: Stack trace: $stackTrace');

      state = state.copyWith(
        errorMessage: 'Failed to load memory data. Please try refreshing.',
        isLoading: false,
      );
    }
  }

  void onAddContentTap() {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(isLoading: false);
  }

  void onEventOptionsTap() {
    state = state.copyWith(
      showEventOptions: true,
    );
  }

  void onReplayAllTap() {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(
      isLoading: false,
      isReplayingAll: true,
    );
  }

  void onAddMediaTap() {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(isLoading: false);
  }

  void onStoryTap(int index) {
    state = state.copyWith(
      selectedStoryIndex: index,
    );
  }

  void onProfileTap() {
    // Navigate to user profile
  }

  void onNotificationTap() {
    // Navigate to notifications
  }
}