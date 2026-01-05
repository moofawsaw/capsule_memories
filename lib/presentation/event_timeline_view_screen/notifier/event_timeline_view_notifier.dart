import '../../../core/app_export.dart';
import '../../../core/utils/memory_nav_args.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/storage_utils.dart';
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

  // CRITICAL FIX: Add missing getter for checking if current user is a member
  bool get isCurrentUserMember => state.isCurrentUserMember ?? false;

  /// CHECK USER MEMBERSHIP: Verify if current user is a member of the memory
  Future<bool> _checkCurrentUserMembership(String memoryId) async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;

      if (currentUser == null) {
        print('❌ MEMBERSHIP CHECK: No authenticated user');
        return false;
      }

      print(
          '🔍 MEMBERSHIP CHECK: Verifying user ${currentUser.id} for memory $memoryId');

      // Check if user is the creator
      final memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('creator_id')
          .eq('id', memoryId)
          .single();

      if (memoryResponse != null &&
          memoryResponse['creator_id'] == currentUser.id) {
        print('✅ MEMBERSHIP CHECK: User is memory creator');
        return true;
      }

      // Check if user is a contributor
      final contributorResponse = await SupabaseService.instance.client
          ?.from('memory_contributors')
          .select('id')
          .eq('memory_id', memoryId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      final isMember = contributorResponse != null;
      print(
          '${isMember ? "✅" : "❌"} MEMBERSHIP CHECK: User ${isMember ? "is" : "is NOT"} a contributor');

      return isMember;
    } catch (e, stackTrace) {
      print('❌ MEMBERSHIP CHECK ERROR: $e');
      print('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// CHECK IF CREATOR: Verify if current user is the creator of the memory
  Future<bool> _checkCurrentUserIsCreator(String memoryId) async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;

      if (currentUser == null) {
        print('❌ CREATOR CHECK: No authenticated user');
        return false;
      }

      print(
          '🔍 CREATOR CHECK: Verifying user ${currentUser.id} for memory $memoryId');

      // Check if user is the creator
      final memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('creator_id')
          .eq('id', memoryId)
          .single();

      final isCreator = memoryResponse != null &&
          memoryResponse['creator_id'] == currentUser.id;

      print(
          '${isCreator ? "✅" : "❌"} CREATOR CHECK: User ${isCreator ? "is" : "is NOT"} the creator');

      return isCreator;
    } catch (e, stackTrace) {
      print('❌ CREATOR CHECK ERROR: $e');
      print('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// DEBUG TOAST: Validate data passing to UI elements
  Map<String, dynamic> validateDataPassing() {
    final model = state.eventTimelineViewModel;

    // Check each UI element for real vs static data
    final validationResults = {
      'eventTitle': _validateField(model?.eventTitle, 'Beach Day Adventure'),
      'eventDate': _validateField(model?.eventDate, 'Dec 22'),
      'memoryId': _validateField(model?.memoryId, ''),
      'categoryIcon':
          _validateField(model?.categoryIcon, ImageConstant.imgFrame13),
      'participantImages': _validateList(model?.participantImages),
      'customStoryItems': _validateList(model?.customStoryItems),
      'location': _validateField(
          model?.timelineDetail?.centerLocation, 'Unknown Location'),
      'timelineStories': _validateList(model?.timelineDetail?.timelineStories),
    };

    // Count successful validations
    final passedCount = validationResults.values.where((v) => v == true).length;
    final totalCount = validationResults.length;

    return {
      'results': validationResults,
      'summary': '$passedCount/$totalCount UI elements have real data',
      'passed': passedCount,
      'total': totalCount,
      'allValid': passedCount == totalCount,
    };
  }

  /// Validate if field contains real data (not default/static)
  bool _validateField(dynamic actual, dynamic staticDefault) {
    if (actual == null) return false;
    if (actual == staticDefault) return false;
    if (actual is String && actual.isEmpty) return false;
    return true;
  }

  /// Validate if list contains real data (not empty)
  bool _validateList(List<dynamic>? list) {
    if (list == null) return false;
    return list.isNotEmpty;
  }

  /// CRITICAL: Real-time validation against Supabase data
  /// Called before rendering any UI element to ensure data integrity
  Future<bool> validateMemoryData(String memoryId) async {
    try {
      print(
          '🔍 VALIDATION: Starting real-time validation for memory: $memoryId');

      // Fetch fresh memory data from Supabase
      final memoryResponse =
          await SupabaseService.instance.client?.from('memories').select('''
            id, title, created_at, start_time, end_time,
            visibility, state, location_name,
            category_id, creator_id,
            memory_categories(icon_name, icon_url),
            user_profiles!memories_creator_id_fkey(
              id, avatar_url, display_name
            )
          ''').eq('id', memoryId).single();

      if (memoryResponse == null) {
        print('❌ VALIDATION FAILED: Memory does not exist in database');
        setErrorState('Memory not found in database');
        return false;
      }

      // Fetch memory contributors for avatar list
      final contributorsResponse = await SupabaseService.instance.client
          ?.from('memory_contributors')
          .select('user_id, user_profiles(avatar_url)')
          .eq('memory_id', memoryId);

      final contributorAvatars = (contributorsResponse as List?)
              ?.map((c) {
                final profile = c['user_profiles'] as Map<String, dynamic>?;
                return AvatarHelperService.getAvatarUrl(
                  profile?['avatar_url'] as String?,
                );
              })
              .whereType<String>()
              .toList() ??
          [];

      // Fetch stories count for validation
      final storiesResponse = await SupabaseService.instance.client
          ?.from('stories')
          .select('id')
          .eq('memory_id', memoryId);

      final storyCount = (storiesResponse as List?)?.length ?? 0;

      // Validate against current state data
      final currentModel = state.eventTimelineViewModel;
      final validationResults = <String, bool>{};

      // Compare title
      final dbTitle = memoryResponse['title'] as String?;
      validationResults['title'] = currentModel?.eventTitle == dbTitle &&
          dbTitle != null &&
          dbTitle.isNotEmpty;

      // Compare memory ID
      validationResults['memoryId'] = currentModel?.memoryId == memoryId;

      // Compare location
      final dbLocation = memoryResponse['location_name'] as String?;
      validationResults['location'] =
          currentModel?.timelineDetail?.centerLocation == dbLocation &&
              dbLocation != null;

      // Compare visibility
      final dbVisibility = memoryResponse['visibility'] as String?;
      validationResults['visibility'] =
          currentModel?.isPrivate == (dbVisibility == 'private');

      // Compare contributors count
      validationResults['contributorCount'] =
          (currentModel?.participantImages?.length ?? 0) ==
              contributorAvatars.length;

      // Compare stories count
      validationResults['storiesCount'] =
          (currentModel?.customStoryItems?.length ?? 0) == storyCount;

      // Log validation results
      final passedCount =
          validationResults.values.where((v) => v == true).length;
      final totalCount = validationResults.length;

      print('📊 VALIDATION RESULTS: $passedCount/$totalCount checks passed');
      validationResults.forEach((field, isValid) {
        print(
            '   ${isValid ? "✅" : "❌"} $field: ${isValid ? "MATCH" : "MISMATCH"}');
      });

      // If critical fields mismatch, refresh data
      if (!validationResults['memoryId']! || !validationResults['title']!) {
        print('⚠️ CRITICAL MISMATCH: Refreshing memory data from database');

        // Force reload from database with validated data
        await _reloadValidatedData(
            memoryId, memoryResponse, contributorAvatars);
        return true;
      }

      return passedCount == totalCount;
    } catch (e, stackTrace) {
      print('❌ VALIDATION ERROR: $e');
      print('   Stack trace: $stackTrace');
      setErrorState('Failed to validate memory data');
      return false;
    }
  }

  /// Reload memory data with validated Supabase data
  Future<void> _reloadValidatedData(
    String memoryId,
    Map<String, dynamic> memoryData,
    List<String> contributorAvatars,
  ) async {
    try {
      // Extract validated data
      final title = memoryData['title'] as String?;
      final createdAt = memoryData['created_at'] as String?;
      final startTime = memoryData['start_time'] as String?;
      final endTime = memoryData['end_time'] as String?;
      final visibility = memoryData['visibility'] as String?;
      final location = memoryData['location_name'] as String?;

      final category = memoryData['memory_categories'] as Map<String, dynamic>?;
      final categoryIcon =
          category?['icon_url'] as String? ?? ImageConstant.imgFrame13;

      // Calculate date display
      String dateDisplay = 'Unknown Date';
      if (createdAt != null) {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inDays < 1) {
          dateDisplay = 'Today';
        } else if (difference.inDays == 1) {
          dateDisplay = 'Yesterday';
        } else {
          dateDisplay = 'Dec ${date.day}';
        }
      }

      // Update state with validated database data
      state = state.copyWith(
        eventTimelineViewModel: EventTimelineViewModel(
          memoryId: memoryId,
          eventTitle: title ?? 'Unknown Memory',
          eventDate: dateDisplay,
          isPrivate: visibility == 'private',
          categoryIcon: categoryIcon,
          participantImages: contributorAvatars,
          customStoryItems:
              state.eventTimelineViewModel?.customStoryItems ?? [],
          timelineDetail: TimelineDetailModel(
            centerLocation: location ?? 'Unknown Location',
            centerDistance: '0km',
            memoryStartTime:
                startTime != null ? DateTime.parse(startTime) : null,
            memoryEndTime: endTime != null ? DateTime.parse(endTime) : null,
            timelineStories:
                state.eventTimelineViewModel?.timelineDetail?.timelineStories ??
                    [],
          ),
        ),
      );

      print('✅ VALIDATION: Memory data reloaded with validated Supabase data');
    } catch (e, stackTrace) {
      print('❌ RELOAD ERROR: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  /// CRITICAL FIX: Accept only MemoryNavArgs - no more raw Map
  void initializeFromMemory(MemoryNavArgs navArgs) async {
    try {
      print('🔍 TIMELINE NOTIFIER: Initializing from MemoryNavArgs');
      print('   - Memory ID: ${navArgs.memoryId}');

      // IMMEDIATE: Store memory ID in state before any async operations
      state = state.copyWith(
        eventTimelineViewModel:
            EventTimelineViewModel(memoryId: navArgs.memoryId),
      );

      print('✅ TIMELINE NOTIFIER: Memory ID stored in state immediately');

      final client = SupabaseService.instance.client;
      if (client == null) {
        print('❌ ERROR: Supabase client is null');
        return;
      }

      // Check if current user is creator and member
      final isCreator = await _checkCurrentUserIsCreator(navArgs.memoryId);
      final isMember = await _checkCurrentUserMembership(navArgs.memoryId);

      print('🔍 TIMELINE NOTIFIER: User permissions');
      print('   - Is Creator: $isCreator');
      print('   - Is Member: $isMember');

      // Fetch memory details with category join
      final memoryResponse = await client.from('memories').select('''
            id,
            title,
            visibility,
            created_at,
            start_time,
            end_time,
            state,
            memory_categories(name, icon_name)
          ''').eq('id', navArgs.memoryId).single();

      print('✅ TIMELINE NOTIFIER: Memory data fetched');
      print('   - Memory title: ${memoryResponse['title']}');
      print(
          '   - Memory state: ${memoryResponse['state']}'); // Log state from DB
      print('   - Visibility: ${memoryResponse['visibility']}');

      // Extract category data
      final categoryData = memoryResponse['memory_categories'];
      final categoryName = categoryData?['name'] as String?;
      final iconName = categoryData?['icon_name'] as String?;

      // CRITICAL FIX: Generate database icon URL using StorageUtils
      final categoryIconUrl = iconName != null
          ? StorageUtils.resolveMemoryCategoryIconUrl(iconName)
          : null;

      print('🔍 TIMELINE NOTIFIER: Category icon details:');
      print('   - Category name: $categoryName');
      print('   - Icon name: $iconName');
      print('   - Generated URL: $categoryIconUrl');

      // Fetch memory contributors for avatar list
      final contributorsResponse = await client
          .from('memory_contributors')
          .select('user_id, user_profiles(avatar_url)')
          .eq('memory_id', navArgs.memoryId);

      final contributorAvatars = (contributorsResponse as List?)
              ?.map((c) {
                final profile = c['user_profiles'] as Map<String, dynamic>?;
                return AvatarHelperService.getAvatarUrl(
                  profile?['avatar_url'] as String?,
                );
              })
              .whereType<String>()
              .toList() ??
          [];

      // Update state with fetched data including creator status
      state = state.copyWith(
        eventTimelineViewModel: EventTimelineViewModel(
          memoryId: navArgs.memoryId,
          eventTitle: memoryResponse['title'] ?? 'Memory',
          eventDate: _formatTimestamp(memoryResponse['created_at'] ?? ''),
          isPrivate: memoryResponse['visibility'] == 'private',
          categoryIcon: categoryIconUrl, // Use database icon URL
          participantImages: contributorAvatars,
          timelineDetail: TimelineDetailModel(
            centerLocation:
                state.eventTimelineViewModel?.timelineDetail?.centerLocation ??
                    'Unknown Location',
            centerDistance:
                state.eventTimelineViewModel?.timelineDetail?.centerDistance ??
                    '0km',
            memoryStartTime: memoryResponse['start_time'] != null
                ? DateTime.parse(memoryResponse['start_time'] as String)
                : null,
            memoryEndTime: memoryResponse['end_time'] != null
                ? DateTime.parse(memoryResponse['end_time'] as String)
                : null,
            timelineStories: [],
          ),
          customStoryItems: [],
        ),
        isCurrentUserMember: isMember,
        isCurrentUserCreator: isCreator,
      );

      print('✅ TIMELINE NOTIFIER: State updated with all data');
      print(
          '   - Memory ID in state: ${state.eventTimelineViewModel?.memoryId}');
      print('   - Event title: ${state.eventTimelineViewModel?.eventTitle}');
      print(
          '   - Category icon URL: ${state.eventTimelineViewModel?.categoryIcon}');
      print('   - Is Creator: $isCreator');
      print('   - Is Member: $isMember');

      // CRITICAL FIX: Properly await story loading to ensure stories appear
      print('🔍 TIMELINE NOTIFIER: Loading stories for memory...');
      print('   - IMPORTANT: This works for ALL memory states (open & sealed)');
      await loadMemoryStories(navArgs.memoryId);
      print('✅ TIMELINE NOTIFIER: Stories loading complete');
    } catch (e, stackTrace) {
      print('❌ ERROR in initializeFromMemory: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // CRITICAL FIX: Make _loadMemoryStories public so it can be called from initializeFromMemory
  Future<void> loadMemoryStories(String memoryId) async {
    try {
      print('🔍 TIMELINE DEBUG: Loading stories for memory: $memoryId');

      // CRITICAL FIX: Store memory ID in state immediately for debugging
      state = state.copyWith(
        eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
          memoryId: memoryId,
        ),
      );

      // Fetch stories from database
      final storiesData = await _storyService.fetchMemoryStories(memoryId);

      print(
          '🔍 TIMELINE DEBUG: Fetched ${storiesData.length} stories from database');

      // CRITICAL FIX: If no stories found, log detailed error and keep loading state
      if (storiesData.isEmpty) {
        print('❌ TIMELINE DEBUG: No stories found for memory $memoryId');

        // Verify memory exists
        final memoryExists = await SupabaseService.instance.client
            ?.from('memories')
            .select('id')
            .eq('id', memoryId)
            .maybeSingle();

        if (memoryExists == null) {
          print(
              '❌ TIMELINE DEBUG: Memory $memoryId does not exist in database');
          state = state.copyWith(
            errorMessage: 'Memory not found',
            isLoading: false,
          );
          return;
        }

        print('✅ TIMELINE DEBUG: Memory exists but has no stories yet');

        // Set empty state but no error - memory exists, just no stories
        state = state.copyWith(
          eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
            customStoryItems: [],
            timelineDetail: TimelineDetailModel(
              centerLocation: state
                      .eventTimelineViewModel?.timelineDetail?.centerLocation ??
                  'Unknown Location',
              centerDistance: '0km',
              timelineStories: [],
            ),
          ),
          errorMessage: null,
          isLoading: false,
        );
        return;
      }

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

  /// Display snapshot data immediately
  void _displaySnapshot(MemorySnapshot snapshot) {
    state = state.copyWith(
      eventTimelineViewModel: EventTimelineViewModel(
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

  /// Set error state
  void setErrorState(String message) {
    state = state.copyWith(
      errorMessage: message,
      isLoading: false,
    );
  }

  // CRITICAL FIX: Remove or mark as deprecated the old initialize() method
  @Deprecated('Use initializeFromMemory with MemoryNavArgs instead')
  void initialize() {
    print('⚠️ DEPRECATED: initialize() called - this should not happen');
    setErrorState('Invalid initialization - missing memory data');
  }

  Future<void> _loadMemoryStories(String memoryId) async {
    try {
      print('🔍 TIMELINE DEBUG: Loading stories for memory: $memoryId');

      // CRITICAL FIX: Store memory ID in state immediately for debugging
      state = state.copyWith(
        eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
          memoryId: memoryId,
        ),
      );

      // Fetch stories from database
      final storiesData = await _storyService.fetchMemoryStories(memoryId);

      print(
          '🔍 TIMELINE DEBUG: Fetched ${storiesData.length} stories from database');

      // CRITICAL FIX: If no stories found, log detailed error and keep loading state
      if (storiesData.isEmpty) {
        print('❌ TIMELINE DEBUG: No stories found for memory $memoryId');

        // Verify memory exists
        final memoryExists = await SupabaseService.instance.client
            ?.from('memories')
            .select('id')
            .eq('id', memoryId)
            .maybeSingle();

        if (memoryExists == null) {
          print(
              '❌ TIMELINE DEBUG: Memory $memoryId does not exist in database');
          state = state.copyWith(
            errorMessage: 'Memory not found',
            isLoading: false,
          );
          return;
        }

        print('✅ TIMELINE DEBUG: Memory exists but has no stories yet');

        // Set empty state but no error - memory exists, just no stories
        state = state.copyWith(
          eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
            customStoryItems: [],
            timelineDetail: TimelineDetailModel(
              centerLocation: state
                      .eventTimelineViewModel?.timelineDetail?.centerLocation ??
                  'Unknown Location',
              centerDistance: '0km',
              timelineStories: [],
            ),
          ),
          errorMessage: null,
          isLoading: false,
        );
        return;
      }

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