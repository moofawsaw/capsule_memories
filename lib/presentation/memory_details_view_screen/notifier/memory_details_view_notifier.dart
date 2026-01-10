import '../../../core/app_export.dart';
import '../../../core/utils/memory_nav_args.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_story_list.dart'; // CustomStoryItem lives here
import '../../../widgets/timeline_widget.dart' as timeline_widget; // TimelineStoryItem lives here
import '../models/memory_details_view_model.dart';
import '../models/timeline_detail_model.dart';

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

  /// Parse any Supabase timestamp into a UTC DateTime consistently.
  DateTime _parseUtc(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    if (value is DateTime) {
      return value.isUtc ? value : value.toUtc();
    }

    final s = value.toString().trim();
    if (s.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    final hasTz = s.endsWith('Z') || RegExp(r'[\+\-]\d\d:\d\d$').hasMatch(s);
    final dt = DateTime.parse(hasTz ? s : '${s}Z');
    return dt.toUtc();
  }

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
    // ✅ FIX: MemorySnapshot doesn't have memoryId, so don't reference it.
    state = state.copyWith(
      memoryDetailsViewModel: MemoryDetailsViewModel(
        eventTitle: snapshot.title,
        eventDate: snapshot.date,
        eventLocation: snapshot.location,
        isPrivate: snapshot.isPrivate,
        categoryIcon: snapshot.categoryIcon ?? ImageConstant.imgFrame13,
        participantImages: snapshot.participantAvatars ?? [],
        customStoryItems: const <CustomStoryItem>[],
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
      print('🔍 SEALED DEBUG: Fetched ${storiesData.length} stories from database');

      // ✅ CRITICAL FIX: Sort stories once, and build BOTH timeline + cycling IDs from same order
      final sortedStories = List<Map<String, dynamic>>.from(storiesData)
        ..sort((a, b) {
          final aTime = _parseUtc(a['created_at']);
          final bTime = _parseUtc(b['created_at']);
          return aTime.compareTo(bTime); // oldest -> newest (timeline order)
        });

      _currentMemoryStoryIds =
          sortedStories.map((s) => s['id'] as String).toList();

      print('✅ SEALED DEBUG: Story IDs (timeline order): $_currentMemoryStoryIds');

      final memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('start_time, end_time, location_name')
          .eq('id', memoryId)
          .single();

      DateTime memoryStartTime;
      DateTime memoryEndTime;
      String? memoryLocation;

      if (memoryResponse != null &&
          memoryResponse['start_time'] != null &&
          memoryResponse['end_time'] != null) {
        memoryStartTime = _parseUtc(memoryResponse['start_time']);
        memoryEndTime = _parseUtc(memoryResponse['end_time']);
        memoryLocation = memoryResponse['location_name'] as String?;

        print('✅ SEALED DEBUG: Using memory window timestamps (UTC-normalized):');
        print('   - Event start: ${memoryStartTime.toIso8601String()}');
        print('   - Event end:   ${memoryEndTime.toIso8601String()}');
        print('   - Event location: $memoryLocation');
      } else {
        if (sortedStories.isNotEmpty) {
          final storyTimes =
          sortedStories.map((s) => _parseUtc(s['created_at'])).toList()
            ..sort();

          memoryStartTime = storyTimes.first;
          memoryEndTime = storyTimes.last;

          final padding = memoryEndTime.difference(memoryStartTime) * 0.1;
          memoryStartTime = memoryStartTime.subtract(padding);
          memoryEndTime = memoryEndTime.add(padding);

          print(
              '⚠️ SEALED DEBUG: Memory window unavailable, using story range with padding (UTC-normalized)');
          print('   - Derived start: ${memoryStartTime.toIso8601String()}');
          print('   - Derived end:   ${memoryEndTime.toIso8601String()}');
        } else {
          memoryEndTime = DateTime.now().toUtc();
          memoryStartTime = memoryEndTime.subtract(const Duration(hours: 2));
        }
      }

      // ✅ This is your horizontal story list type: List<CustomStoryItem>
      final List<CustomStoryItem> storyFeedItems = sortedStories.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = _parseUtc(storyData['created_at']);

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

      // ✅ This is your timeline type: List<TimelineStoryItem>
      final List<timeline_widget.TimelineStoryItem> timelineStories =
      sortedStories.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = _parseUtc(storyData['created_at']);
        final storyId = storyData['id'] as String;

        final backgroundImage = _storyService.getStoryMediaUrl(storyData);
        final profileImage = AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'] as String?,
        );

        return timeline_widget.TimelineStoryItem(
          backgroundImage: backgroundImage,
          userAvatar: profileImage,
          postedAt: createdAt,
          timeLabel: _storyService.getTimeAgo(createdAt),
          storyId: storyId,
        );
      }).toList();

      final existing = state.memoryDetailsViewModel;

      state = state.copyWith(
        memoryDetailsViewModel: (existing ?? MemoryDetailsViewModel())
            .copyWith(
          memoryId: memoryId,
          eventLocation: memoryLocation ??
              existing?.eventLocation ??
              'Unknown Location',
          // ✅ FIX: customStoryItems expects List<CustomStoryItem>
          customStoryItems: storyFeedItems,
          timelineDetail: (existing?.timelineDetail ??
              TimelineDetailModel(
                centerLocation: memoryLocation ?? 'Unknown Location',
                centerDistance: '0km',
              ))
              .copyWith(
            centerLocation: memoryLocation ?? 'Unknown Location',
            memoryStartTime: memoryStartTime,
            memoryEndTime: memoryEndTime,
            timelineStories: timelineStories,
          ),
        ),
        errorMessage: null,
      );

      print('✅ SEALED DEBUG: Timeline + feed updated with sorted story order');
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
    state = state.copyWith(showEventOptions: true);
  }

  void onReplayAllTap() {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(isLoading: false, isReplayingAll: true);
  }

  void onAddMediaTap() {
    state = state.copyWith(isLoading: true);
    state = state.copyWith(isLoading: false);
  }

  void onStoryTap(int index) {
    state = state.copyWith(selectedStoryIndex: index);
  }

  void onProfileTap() {}

  void onNotificationTap() {}
}
