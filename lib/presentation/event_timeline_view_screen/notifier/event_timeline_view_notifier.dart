import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Store story IDs for cycling functionality
  List<String> _currentMemoryStoryIds = [];

  // Real-time subscription to memories table
  RealtimeChannel? _memorySubscription;

  EventTimelineViewNotifier() : super(EventTimelineViewState());

  List<String> get currentMemoryStoryIds => _currentMemoryStoryIds;

  bool get isCurrentUserMember => state.isCurrentUserMember ?? false;

  /// Parse any Supabase timestamp into a UTC DateTime consistently.
  /// Handles:
  /// - DateTime objects (keeps UTC)
  /// - ISO strings with timezone (Z or +/-HH:MM)
  /// - "naive" ISO strings (no timezone) -> treat as UTC by appending "Z"
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

  /// DEBUG: Validate data passing to UI elements
  Map<String, dynamic> validateDataPassing() {
    final model = state.eventTimelineViewModel;

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

  bool _validateField(dynamic actual, dynamic staticDefault) {
    if (actual == null) return false;
    if (actual == staticDefault) return false;
    if (actual is String && actual.isEmpty) return false;
    return true;
  }

  bool _validateList(List<dynamic>? list) {
    if (list == null) return false;
    return list.isNotEmpty;
  }

  /// Real-time validation against Supabase data
  Future<bool> validateMemoryData(String memoryId) async {
    try {
      print(
          '🔍 VALIDATION: Starting real-time validation for memory: $memoryId');

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

      final storiesResponse = await SupabaseService.instance.client
          ?.from('stories')
          .select('id')
          .eq('memory_id', memoryId);

      final storyCount = (storiesResponse as List?)?.length ?? 0;

      final currentModel = state.eventTimelineViewModel;
      final validationResults = <String, bool>{};

      final dbTitle = memoryResponse['title'] as String?;
      validationResults['title'] = currentModel?.eventTitle == dbTitle &&
          dbTitle != null &&
          dbTitle.isNotEmpty;

      validationResults['memoryId'] = currentModel?.memoryId == memoryId;

      final dbLocation = memoryResponse['location_name'] as String?;
      validationResults['location'] =
          currentModel?.timelineDetail?.centerLocation == dbLocation &&
              dbLocation != null;

      final dbVisibility = memoryResponse['visibility'] as String?;
      validationResults['visibility'] =
          currentModel?.isPrivate == (dbVisibility == 'private');

      validationResults['contributorCount'] =
          (currentModel?.participantImages?.length ?? 0) ==
              contributorAvatars.length;

      validationResults['storiesCount'] =
          (currentModel?.customStoryItems?.length ?? 0) == storyCount;

      final passedCount =
          validationResults.values.where((v) => v == true).length;
      final totalCount = validationResults.length;

      print('📊 VALIDATION RESULTS: $passedCount/$totalCount checks passed');
      validationResults.forEach((field, isValid) {
        print(
            '   ${isValid ? "✅" : "❌"} $field: ${isValid ? "MATCH" : "MISMATCH"}');
      });

      if (!validationResults['memoryId']! || !validationResults['title']!) {
        print('⚠️ CRITICAL MISMATCH: Refreshing memory data from database');
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
      final title = memoryData['title'] as String?;
      final createdAt = memoryData['created_at'];
      final startTime = memoryData['start_time'];
      final endTime = memoryData['end_time'];
      final visibility = memoryData['visibility'] as String?;
      final location = memoryData['location_name'] as String?;

      final category = memoryData['memory_categories'] as Map<String, dynamic>?;
      final iconName = category?['icon_name'] as String?;
      final categoryIconUrl = iconName != null
          ? StorageUtils.resolveMemoryCategoryIconUrl(iconName)
          : (category?['icon_url'] as String? ?? ImageConstant.imgFrame13);

      // Date display
      String dateDisplay = 'Unknown Date';
      if (createdAt != null) {
        final date = _parseUtc(createdAt).toLocal();
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

      state = state.copyWith(
        memoryId: memoryId,
        eventTimelineViewModel: EventTimelineViewModel(
          memoryId: memoryId,
          eventTitle: title ?? 'Unknown Memory',
          eventDate: dateDisplay,
          isPrivate: visibility == 'private',
          categoryIcon: categoryIconUrl,
          participantImages: contributorAvatars,
          customStoryItems:
              state.eventTimelineViewModel?.customStoryItems ?? [],
          timelineDetail: TimelineDetailModel(
            centerLocation: location ?? 'Unknown Location',
            centerDistance: '0km',
            memoryStartTime: startTime != null ? _parseUtc(startTime) : null,
            memoryEndTime: endTime != null ? _parseUtc(endTime) : null,
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

  /// Accept only MemoryNavArgs
  void initializeFromMemory(MemoryNavArgs navArgs) async {
    try {
      print('🔍 TIMELINE NOTIFIER: Initializing from MemoryNavArgs');
      print('   - Memory ID: ${navArgs.memoryId}');

      // CRITICAL FIX: Set loading state TRUE immediately to trigger skeleton loading
      state = state.copyWith(
        isLoading: true,
        memoryId: navArgs.memoryId,
        eventTimelineViewModel:
            EventTimelineViewModel(memoryId: navArgs.memoryId),
      );

      final client = SupabaseService.instance.client;
      if (client == null) {
        print('❌ ERROR: Supabase client is null');
        return;
      }

      final isCreator = await _checkCurrentUserIsCreator(navArgs.memoryId);
      final isMember = await _checkCurrentUserMembership(navArgs.memoryId);

      print('🔍 TIMELINE NOTIFIER: User permissions');
      print('   - Is Creator: $isCreator');
      print('   - Is Member: $isMember');

      final memoryResponse = await client.from('memories').select('''
            id,
            title,
            visibility,
            created_at,
            start_time,
            end_time,
            state,
            location_name,
            memory_categories(name, icon_name)
          ''').eq('id', navArgs.memoryId).single();

      print('✅ TIMELINE NOTIFIER: Memory data fetched');
      print('   - Memory title: ${memoryResponse['title']}');
      print('   - Memory state: ${memoryResponse['state']}');
      print('   - Visibility: ${memoryResponse['visibility']}');

      final categoryData = memoryResponse['memory_categories'];
      final iconName = categoryData?['icon_name'] as String?;
      final categoryIconUrl = iconName != null
          ? StorageUtils.resolveMemoryCategoryIconUrl(iconName)
          : null;

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

      // Normalize memory window times to UTC
      final DateTime? startUtc = memoryResponse['start_time'] != null
          ? _parseUtc(memoryResponse['start_time'])
          : null;
      final DateTime? endUtc = memoryResponse['end_time'] != null
          ? _parseUtc(memoryResponse['end_time'])
          : null;

      state = state.copyWith(
        memoryId: navArgs.memoryId,
        eventTimelineViewModel: EventTimelineViewModel(
          memoryId: navArgs.memoryId,
          eventTitle: memoryResponse['title'] ?? 'Memory',
          eventDate: _formatTimestamp(memoryResponse['created_at'] ?? ''),
          isPrivate: memoryResponse['visibility'] == 'private',
          categoryIcon: categoryIconUrl,
          participantImages: contributorAvatars,
          timelineDetail: TimelineDetailModel(
            centerLocation: (memoryResponse['location_name'] as String?) ??
                (state.eventTimelineViewModel?.timelineDetail?.centerLocation ??
                    'Unknown Location'),
            centerDistance:
                state.eventTimelineViewModel?.timelineDetail?.centerDistance ??
                    '0km',
            memoryStartTime: startUtc,
            memoryEndTime: endUtc,
            timelineStories: [],
          ),
          customStoryItems: [],
        ),
        isCurrentUserMember: isMember,
        isCurrentUserCreator: isCreator,
        // Keep loading true until stories are loaded
        isLoading: true,
      );

      print('✅ TIMELINE NOTIFIER: State updated with all data');

      print('🔍 TIMELINE NOTIFIER: Loading stories for memory...');
      await loadMemoryStories(navArgs.memoryId);
      print('✅ TIMELINE NOTIFIER: Stories loading complete');

      // CRITICAL: Set up real-time subscription for memory updates
      _setupRealtimeSubscription(navArgs.memoryId);
    } catch (e, stackTrace) {
      print('❌ ERROR in initializeFromMemory: $e');
      print('Stack trace: $stackTrace');
      // Set loading false on error
      state = state.copyWith(isLoading: false);
    }
  }

  /// Set up real-time subscription to memories table for the specific memory
  void _setupRealtimeSubscription(String memoryId) {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        print(
            '⚠️ REALTIME: Supabase client is null, cannot setup subscription');
        return;
      }

      // Remove existing subscription if any
      if (_memorySubscription != null) {
        print('🔄 REALTIME: Removing existing subscription');
        _memorySubscription!.unsubscribe();
        _memorySubscription = null;
      }

      print('🔗 REALTIME: Setting up subscription for memory: $memoryId');

      // Create channel for memory updates
      _memorySubscription = client
          .channel('memory-updates-$memoryId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'memories',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: memoryId,
            ),
            callback: (payload) {
              print('🔔 REALTIME: Memory update detected');
              print('   - Memory ID: $memoryId');
              print(
                  '   - Changed fields: ${payload.newRecord.keys.join(", ")}');

              // Reload memory data with updated information
              _handleMemoryUpdate(memoryId, payload.newRecord);
            },
          )
          .subscribe();

      print('✅ REALTIME: Subscription active for memory: $memoryId');
    } catch (e, stackTrace) {
      print('❌ REALTIME ERROR: Failed to setup subscription: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  /// Handle real-time memory update
  Future<void> _handleMemoryUpdate(
      String memoryId, Map<String, dynamic> updatedData) async {
    try {
      print('🔄 REALTIME: Processing memory update');
      print('   - Memory ID: $memoryId');

      // Extract updated fields
      final title = updatedData['title'] as String?;
      final visibility = updatedData['visibility'] as String?;
      final startTime = updatedData['start_time'];
      final endTime = updatedData['end_time'];
      final location = updatedData['location_name'] as String?;
      final state = updatedData['state'] as String?;

      print('🔍 REALTIME: Updated fields:');
      print('   - Title: $title');
      print('   - End Time: $endTime');
      print('   - Start Time: $startTime');
      print('   - Location: $location');
      print('   - State: $state');

      // Normalize times to UTC
      final DateTime? startUtc =
          startTime != null ? _parseUtc(startTime) : null;
      final DateTime? endUtc = endTime != null ? _parseUtc(endTime) : null;

      // Update state with new data
      this.state = this.state.copyWith(
            eventTimelineViewModel: this.state.eventTimelineViewModel?.copyWith(
                  eventTitle:
                      title ?? this.state.eventTimelineViewModel?.eventTitle,
                  isPrivate: visibility == 'private',
                  timelineDetail: TimelineDetailModel(
                    centerLocation: location ??
                        this
                            .state
                            .eventTimelineViewModel
                            ?.timelineDetail
                            ?.centerLocation ??
                        'Unknown Location',
                    centerDistance: this
                            .state
                            .eventTimelineViewModel
                            ?.timelineDetail
                            ?.centerDistance ??
                        '0km',
                    memoryStartTime: startUtc ??
                        this
                            .state
                            .eventTimelineViewModel
                            ?.timelineDetail
                            ?.memoryStartTime,
                    memoryEndTime: endUtc ??
                        this
                            .state
                            .eventTimelineViewModel
                            ?.timelineDetail
                            ?.memoryEndTime,
                    timelineStories: this
                            .state
                            .eventTimelineViewModel
                            ?.timelineDetail
                            ?.timelineStories ??
                        [],
                  ),
                ),
          );

      print('✅ REALTIME: Timeline state updated with new memory data');
    } catch (e, stackTrace) {
      print('❌ REALTIME ERROR: Failed to handle memory update: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  /// Clean up subscription when notifier is disposed
  @override
  void dispose() {
    print('🧹 REALTIME: Cleaning up memory subscription');
    if (_memorySubscription != null) {
      _memorySubscription!.unsubscribe();
      _memorySubscription = null;
    }
    super.dispose();
  }

  /// Public loader used by initializeFromMemory
  Future<void> loadMemoryStories(String memoryId) async {
    try {
      print('🔍 TIMELINE DEBUG: Loading stories for memory: $memoryId');

      // Fetch stories
      final storiesData = await _storyService.fetchMemoryStories(memoryId);

      print(
          '🔍 TIMELINE DEBUG: Fetched ${storiesData.length} stories from database');

      if (storiesData.isEmpty) {
        print('⚠️ TIMELINE DEBUG: Memory exists but has no stories yet');

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

      // Story IDs for cycling
      _currentMemoryStoryIds =
          storiesData.map((storyData) => storyData['id'] as String).toList();

      // Load memory window timestamps (UTC-normalized)
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
        memoryStartTime = _parseUtc(memoryResponse['start_time']);
        memoryEndTime = _parseUtc(memoryResponse['end_time']);

        print(
            '✅ TIMELINE DEBUG: Using memory window timestamps (UTC-normalized):');
        print('   - Event start: ${memoryStartTime.toIso8601String()}');
        print('   - Event end:   ${memoryEndTime.toIso8601String()}');
      } else {
        // Fallback based on story timestamps (UTC-normalized)
        final storyTimes =
            storiesData.map((s) => _parseUtc(s['created_at'])).toList();
        storyTimes.sort();

        memoryStartTime = storyTimes.first;
        memoryEndTime = storyTimes.last;

        final padding = memoryEndTime.difference(memoryStartTime) * 0.1;
        memoryStartTime = memoryStartTime.subtract(padding);
        memoryEndTime = memoryEndTime.add(padding);

        print(
            '⚠️ TIMELINE DEBUG: Memory window unavailable, using story range with padding (UTC-normalized)');
        print('   - Derived start: ${memoryStartTime.toIso8601String()}');
        print('   - Derived end:   ${memoryEndTime.toIso8601String()}');
      }

      // Horizontal story list items
      final storyItems = storiesData.map((storyData) {
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

      // Timeline positioned stories (UTC-normalized postedAt)
      final timelineStories = storiesData.map((storyData) {
        final contributor = storyData['user_profiles'] as Map<String, dynamic>?;
        final createdAt = _parseUtc(storyData['created_at']);
        final storyId = storyData['id'] as String;

        final backgroundImage = _storyService.getStoryMediaUrl(storyData);
        final profileImage = AvatarHelperService.getAvatarUrl(
          contributor?['avatar_url'] as String?,
        );

        final diffMin = createdAt.difference(memoryStartTime).inMinutes;
        print(
            '🧭 TIMELINE DIFF: story=$storyId diffMin=$diffMin createdAt=${createdAt.toIso8601String()} start=${memoryStartTime.toIso8601String()}');

        return TimelineStoryItem(
          backgroundImage: backgroundImage,
          userAvatar: profileImage,
          postedAt: createdAt,
          timeLabel: _storyService.getTimeAgo(createdAt),
          storyId: storyId,
        );
      }).toList();

      state = state.copyWith(
        timelineStories: timelineStories,
        memoryStartTime: memoryStartTime,
        memoryEndTime: memoryEndTime,
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
        isLoading: false,
      );

      print('✅ TIMELINE DEBUG: Timeline updated with memory window');
      print('   - ${storyItems.length} horizontal story items');
      print('   - ${timelineStories.length} positioned timeline stories');
    } catch (e, stackTrace) {
      print('❌ TIMELINE DEBUG: Error loading memory stories: $e');
      print('❌ TIMELINE DEBUG: Stack trace: $stackTrace');

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

  void setErrorState(String message) {
    state = state.copyWith(
      errorMessage: message,
      isLoading: false,
    );
  }

  @Deprecated('Use initializeFromMemory with MemoryNavArgs instead')
  void initialize() {
    print('⚠️ DEPRECATED: initialize() called - this should not happen');
    setErrorState('Invalid initialization - missing memory data');
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

  /// DELETE MEMORY: Remove memory and all associated data
  Future<void> deleteMemory(String memoryId) async {
    try {
      print('🔍 DELETE MEMORY: Starting deletion process');
      print('   - Memory ID: $memoryId');

      final client = SupabaseService.instance.client;
      if (client == null) {
        throw Exception('Supabase client is not initialized');
      }

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final memoryResponse = await client
          .from('memories')
          .select('creator_id')
          .eq('id', memoryId)
          .single();

      if (memoryResponse['creator_id'] != currentUser.id) {
        throw Exception('Only the memory creator can delete this memory');
      }

      print('✅ DELETE MEMORY: User verified as creator');

      await client.from('memories').delete().eq('id', memoryId);

      print('✅ DELETE MEMORY: Memory deleted successfully');

      await _cacheService.refreshMemoryCache(currentUser.id);

      print('✅ DELETE MEMORY: Cache cleared');
    } catch (e, stackTrace) {
      print('❌ DELETE MEMORY ERROR: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// JOIN MEMORY: Add current user as a contributor to the memory
  Future<void> joinMemory(String memoryId) async {
    try {
      print('🔍 JOIN MEMORY: Starting join process');
      print('   - Memory ID: $memoryId');

      final client = SupabaseService.instance.client;
      if (client == null) {
        throw Exception('Supabase client is not initialized');
      }

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Check if user is already a member
      final existingContributor = await client
          .from('memory_contributors')
          .select('id')
          .eq('memory_id', memoryId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingContributor != null) {
        print('⚠️ JOIN MEMORY: User is already a member');

        // Update membership status in state
        state = state.copyWith(isCurrentUserMember: true);
        return;
      }

      // Add user as contributor
      await client.from('memory_contributors').insert({
        'memory_id': memoryId,
        'user_id': currentUser.id,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });

      print('✅ JOIN MEMORY: User added as contributor');

      // Update membership status in state
      state = state.copyWith(isCurrentUserMember: true);

      // Refresh cache
      await _cacheService.refreshMemoryCache(currentUser.id);

      print('✅ JOIN MEMORY: Successfully joined memory');
    } catch (e, stackTrace) {
      print('❌ JOIN MEMORY ERROR: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}
