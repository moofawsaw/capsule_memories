// lib/presentation/event_timeline_view_screen/notifier/event_timeline_view_notifier.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/memory_nav_args.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/storage_utils.dart';
import '../../../widgets/custom_story_list.dart';
import '../models/event_timeline_view_model.dart';
import '../models/timeline_detail_model.dart';
import '../widgets/timeline_story_widget.dart';

part 'event_timeline_view_state.dart';

final eventTimelineViewNotifier =
StateNotifierProvider.autoDispose<EventTimelineViewNotifier, EventTimelineViewState>(
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

  // ----------------------------
  // NEW: normalize memory state
  // ----------------------------
  String _normalizeState(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    return s;
  }

  bool _isSealedState(String state) => state == 'sealed';

  Future<String?> _fetchPendingInviteId(String memoryId) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return null;

      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      final resp = await client
          .from('memory_invites')
          .select('id,status')
          .eq('memory_id', memoryId)
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      final inviteId = (resp?['id'] as String?)?.trim();
      return (inviteId != null && inviteId.isNotEmpty) ? inviteId : null;
    } catch (_) {
      return null;
    }
  }

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

  /// CHECK USER MEMBERSHIP: Verify if current user is a member of the memory
  Future<bool> _checkCurrentUserMembership(String memoryId) async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;

      if (currentUser == null) {
        print('❌ MEMBERSHIP CHECK: No authenticated user');
        return false;
      }

      print('🔍 MEMBERSHIP CHECK: Verifying user ${currentUser.id} for memory $memoryId');

      // Check if user is the creator
      final memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('creator_id')
          .eq('id', memoryId)
          .single();

      if (memoryResponse != null && memoryResponse['creator_id'] == currentUser.id) {
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
      print('${isMember ? "✅" : "❌"} MEMBERSHIP CHECK: User ${isMember ? "is" : "is NOT"} a contributor');

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

      print('🔍 CREATOR CHECK: Verifying user ${currentUser.id} for memory $memoryId');

      final memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('creator_id')
          .eq('id', memoryId)
          .single();

      final isCreator =
          memoryResponse != null && memoryResponse['creator_id'] == currentUser.id;

      print('${isCreator ? "✅" : "❌"} CREATOR CHECK: User ${isCreator ? "is" : "is NOT"} the creator');

      return isCreator;
    } catch (e, stackTrace) {
      print('❌ CREATOR CHECK ERROR: $e');
      print('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Real-time validation against Supabase data
  ///
  /// ✅ FIX:
  /// - Validate and refresh on state/sealed mismatch too (not just title/id).
  Future<bool> validateMemoryData(String memoryId) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
      );

      print('🔍 VALIDATION: Starting real-time validation for memory: $memoryId');

      final memoryResponse = await SupabaseService.instance.client?.from('memories').select('''
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
          currentModel?.timelineDetail?.centerLocation == dbLocation && dbLocation != null;

      final dbVisibility = memoryResponse['visibility'] as String?;
      validationResults['visibility'] =
          currentModel?.isPrivate == (dbVisibility == 'private');

      validationResults['contributorCount'] =
          (currentModel?.participantImages?.length ?? 0) == contributorAvatars.length;

      validationResults['storiesCount'] =
          (currentModel?.customStoryItems?.length ?? 0) == storyCount;

      // NEW: validate state/sealed
      final dbState = _normalizeState(memoryResponse['state']);
      final dbIsSealed = _isSealedState(dbState);
      validationResults['state'] = (currentModel?.isSealed ?? state.isSealed) == dbIsSealed;

      final passedCount = validationResults.values.where((v) => v == true).length;
      final totalCount = validationResults.length;

      print('📊 VALIDATION RESULTS: $passedCount/$totalCount checks passed');
      validationResults.forEach((field, isValid) {
        print('   ${isValid ? "✅" : "❌"} $field: ${isValid ? "MATCH" : "MISMATCH"}');
      });

      // ✅ Reload if critical mismatches OR sealed/state mismatch.
      final criticalMismatch = !validationResults['memoryId']! ||
          !validationResults['title']! ||
          !validationResults['state']!;

      if (criticalMismatch) {
        print('⚠️ CRITICAL MISMATCH: Refreshing memory data from database');
        await _reloadValidatedData(memoryId, memoryResponse, contributorAvatars);

        state = state.copyWith(isLoading: false, errorMessage: null);
        return true;
      }

      state = state.copyWith(isLoading: false, errorMessage: null);
      return passedCount == totalCount;
    } catch (e, stackTrace) {
      print('❌ VALIDATION ERROR: $e');
      print('   Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to validate memory data',
      );
      return false;
    }
  }

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

      // NEW: state/sealed
      final normalizedState = _normalizeState(memoryData['state']);
      final sealed = _isSealedState(normalizedState);

      final category = memoryData['memory_categories'] as Map<String, dynamic>?;
      final iconNameRaw = category?['icon_name'] as String?;
      final iconName = (iconNameRaw ?? '').trim();
      final iconUrl = (category?['icon_url'] as String?)?.trim();

      String categoryIconUrl = '';

      if (iconName.isNotEmpty) {
        final resolved = StorageUtils.resolveMemoryCategoryIconUrl(iconName);
        if (resolved.trim().isNotEmpty) {
          categoryIconUrl = resolved.trim();
        } else if (iconUrl != null && iconUrl.isNotEmpty) {
          categoryIconUrl = iconUrl;
        }
      } else if (iconUrl != null && iconUrl.isNotEmpty) {
        categoryIconUrl = iconUrl;
      }

      print('🧩 CATEGORY ICON DEBUG (reload): '
          'icon_name="$iconNameRaw" icon_url="$iconUrl" final="$categoryIconUrl"');

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

      final existingStories = state.eventTimelineViewModel?.customStoryItems ?? [];
      final existingTimelineStories =
          state.eventTimelineViewModel?.timelineDetail?.timelineStories ?? [];
      final existingCenterDistance =
          state.eventTimelineViewModel?.timelineDetail?.centerDistance ?? '0km';

      state = state.copyWith(
        memoryId: memoryId,
        isSealed: sealed,
        memoryState: normalizedState,
        eventTimelineViewModel:
        (state.eventTimelineViewModel ?? EventTimelineViewModel(memoryId: memoryId)).copyWith(
          memoryId: memoryId,
          eventTitle: title ?? 'Unknown Memory',
          eventDate: dateDisplay,
          isPrivate: visibility == 'private',
          categoryIcon: categoryIconUrl,
          participantImages: contributorAvatars,

          // NEW
          memoryState: normalizedState,
          isSealed: sealed,

          customStoryItems: existingStories,
          timelineDetail: TimelineDetailModel(
            centerLocation: location ?? 'Unknown Location',
            centerDistance: existingCenterDistance,
            memoryStartTime: startTime != null ? _parseUtc(startTime) : null,
            memoryEndTime: endTime != null ? _parseUtc(endTime) : null,
            timelineStories: existingTimelineStories,
          ),
        ),
        errorMessage: null,
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

      // IMPORTANT:
      // If coming from notification/invite, we must NOT reuse a prior memory model snapshot
      // for a different memory. If memory id changes, reset minimal fields.
      final prevMemoryId = state.memoryId;
      final switchingMemory = prevMemoryId != null && prevMemoryId != navArgs.memoryId;

      state = state.copyWith(
        isLoading: true,
        memoryId: navArgs.memoryId,
        errorMessage: null,
        // keep snapshot if same memory; otherwise create fresh model shell
        eventTimelineViewModel: (!switchingMemory && state.eventTimelineViewModel != null)
            ? state.eventTimelineViewModel
            : EventTimelineViewModel(memoryId: navArgs.memoryId),
      );

      // ✅ If caller provided a snapshot (e.g. from story viewer header click),
      // render it immediately so category icon + member avatars appear even when
      // DB joins are restricted or slow. The DB load below will refine fields.
      if (navArgs.snapshot != null) {
        _displaySnapshot(navArgs.snapshot!);
      }

      final client = SupabaseService.instance.client;
      if (client == null) {
        print('❌ ERROR: Supabase client is null');
        state = state.copyWith(isLoading: false);
        return;
      }

      final isCreator = await _checkCurrentUserIsCreator(navArgs.memoryId);
      final isMember = await _checkCurrentUserMembership(navArgs.memoryId);
      final pendingInviteId =
          !isMember ? await _fetchPendingInviteId(navArgs.memoryId) : null;
      final hasPendingInvite =
          pendingInviteId != null && pendingInviteId.trim().isNotEmpty;

      print('🔍 TIMELINE NOTIFIER: User permissions');
      print('   - Is Creator: $isCreator');
      print('   - Is Member: $isMember');
      print('   - Has Pending Invite: $hasPendingInvite');

      final memoryResponse = await client.from('memories').select('''
  id,
  title,
  visibility,
  created_at,
  start_time,
  end_time,
  state,
  location_name,
  memory_categories(name, icon_name, icon_url)
''').eq('id', navArgs.memoryId).single();

      final normalizedState = _normalizeState(memoryResponse['state']);
      final sealed = _isSealedState(normalizedState);

      print('✅ TIMELINE NOTIFIER: Memory data fetched');
      print('   - Memory title: ${memoryResponse['title']}');
      print('   - Memory state: ${memoryResponse['state']}');
      print('   - Visibility: ${memoryResponse['visibility']}');
      print('   - isSealed: $sealed');

      final categoryData = memoryResponse['memory_categories'] as Map<String, dynamic>?;

      final iconNameRaw = categoryData?['icon_name'] as String?;
      final iconName = (iconNameRaw ?? '').trim();
      final iconUrl = (categoryData?['icon_url'] as String?)?.trim();

      String categoryIconFinal = '';

      if (iconName.isNotEmpty) {
        final resolved = StorageUtils.resolveMemoryCategoryIconUrl(iconName);
        if (resolved.trim().isNotEmpty) {
          categoryIconFinal = resolved.trim();
        } else if (iconUrl != null && iconUrl.isNotEmpty) {
          categoryIconFinal = iconUrl;
        }
      } else if (iconUrl != null && iconUrl.isNotEmpty) {
        categoryIconFinal = iconUrl;
      }

      print('🧩 CATEGORY ICON DEBUG: '
          'icon_name="$iconNameRaw" '
          'icon_url="$iconUrl" '
          'final="$categoryIconFinal"');

      // Best-effort contributors list (can be blocked by RLS for non-members).
      List<String> contributorAvatars = [];
      try {
        final contributorsResponse = await client
            .from('memory_contributors')
            .select('user_id, user_profiles(avatar_url)')
            .eq('memory_id', navArgs.memoryId);

        contributorAvatars = (contributorsResponse as List?)
                ?.map((c) {
                  final profile = c['user_profiles'] as Map<String, dynamic>?;
                  return AvatarHelperService.getAvatarUrl(
                    profile?['avatar_url'] as String?,
                  );
                })
                .whereType<String>()
                .where((u) => u.trim().isNotEmpty)
                .toList() ??
            <String>[];
      } catch (_) {
        contributorAvatars = <String>[];
      }

      final DateTime? startUtc =
      memoryResponse['start_time'] != null ? _parseUtc(memoryResponse['start_time']) : null;
      final DateTime? endUtc =
      memoryResponse['end_time'] != null ? _parseUtc(memoryResponse['end_time']) : null;

      final existingTimelineDetail = state.eventTimelineViewModel?.timelineDetail;
      final existingTitle = (state.eventTimelineViewModel?.eventTitle ?? '').trim();
      final existingLocation =
          (state.eventTimelineViewModel?.timelineDetail?.centerLocation ?? '').trim();
      final existingCategoryIcon =
          (state.eventTimelineViewModel?.categoryIcon ?? '').trim();
      final existingParticipants =
          state.eventTimelineViewModel?.participantImages ?? const <String>[];

      state = state.copyWith(
        memoryId: navArgs.memoryId,
        isSealed: sealed,
        memoryState: normalizedState,
        eventTimelineViewModel:
        (state.eventTimelineViewModel ?? EventTimelineViewModel(memoryId: navArgs.memoryId)).copyWith(
          memoryId: navArgs.memoryId,
          eventTitle: ((memoryResponse['title'] as String?)?.trim().isNotEmpty ?? false)
              ? (memoryResponse['title'] as String?)!
              : (existingTitle.isNotEmpty ? existingTitle : 'Memory'),
          eventDate: _formatTimestamp(memoryResponse['created_at'] ?? ''),
          isPrivate: memoryResponse['visibility'] == 'private',
          categoryIcon: categoryIconFinal.trim().isNotEmpty
              ? categoryIconFinal
              : (existingCategoryIcon.isNotEmpty ? existingCategoryIcon : ''),
          participantImages: contributorAvatars.isNotEmpty
              ? contributorAvatars
              : (existingParticipants.isNotEmpty ? existingParticipants : []),

          // NEW
          memoryState: normalizedState,
          isSealed: sealed,

          timelineDetail: TimelineDetailModel(
            centerLocation: ((memoryResponse['location_name'] as String?)?.trim().isNotEmpty ?? false)
                ? (memoryResponse['location_name'] as String?)!
                : (existingTimelineDetail?.centerLocation ??
                    (existingLocation.isNotEmpty ? existingLocation : 'Unknown Location')),
            centerDistance: existingTimelineDetail?.centerDistance ?? '0km',
            memoryStartTime: startUtc,
            memoryEndTime: endUtc,
            timelineStories: existingTimelineDetail?.timelineStories ?? [],
          ),
          customStoryItems: state.eventTimelineViewModel?.customStoryItems ?? [],
        ),
        isCurrentUserMember: isMember,
        isCurrentUserCreator: isCreator,
        hasPendingInvite: hasPendingInvite,
        pendingInviteId: pendingInviteId,
        isLoading: true,
        errorMessage: null,
      );

      print('✅ TIMELINE NOTIFIER: State updated with all data');
      print('🔍 TIMELINE NOTIFIER: Loading stories for memory...');
      await loadMemoryStories(navArgs.memoryId);
      print('✅ TIMELINE NOTIFIER: Stories loading complete');

      _setupRealtimeSubscription(navArgs.memoryId);
    } catch (e, stackTrace) {
      print('❌ ERROR in initializeFromMemory: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Accepts a pending invite (if present) and joins the memory.
  /// Sealed-safe: if invite accept/pending check fails, falls back to joining by memory id.
  Future<void> acceptPendingInviteAndJoin() async {
    final memoryId =
        (state.eventTimelineViewModel?.memoryId ?? state.memoryId)?.trim();
    if (memoryId == null || memoryId.isEmpty) {
      throw Exception('Missing memory id');
    }

    final inviteId = (state.pendingInviteId ?? '').trim();

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      bool joined = false;

      if (inviteId.isNotEmpty) {
        try {
          final isPending =
              await NotificationService.instance.isInviteStillPending(inviteId);
          if (isPending) {
            await NotificationService.instance.acceptMemoryInvite(inviteId);
            joined = true;
          } else {
            await NotificationService.instance.joinMemoryById(memoryId);
            joined = true;
          }
        } catch (_) {
          await NotificationService.instance.joinMemoryById(memoryId);
          joined = true;
        }
      } else {
        await NotificationService.instance.joinMemoryById(memoryId);
        joined = true;
      }

      if (!joined) {
        throw Exception('Unable to join memory');
      }

      final isCreator = await _checkCurrentUserIsCreator(memoryId);

      // Flip UI to member mode immediately.
      state = state.copyWith(
        isCurrentUserMember: true,
        isCurrentUserCreator: isCreator,
        hasPendingInvite: false,
        pendingInviteId: null,
      );

      // Keep cache consistent for other screens that rely on it.
      final client = SupabaseService.instance.client;
      final userId = client?.auth.currentUser?.id;
      if (userId != null) {
        await _cacheService.refreshMemoryCache(userId);
      }

      // Refresh timeline data now that the user is a member.
      await loadMemoryStories(memoryId);
      await validateMemoryData(memoryId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void _setupRealtimeSubscription(String memoryId) {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        print('⚠️ REALTIME: Supabase client is null, cannot setup subscription');
        return;
      }

      if (_memorySubscription != null) {
        print('🔄 REALTIME: Removing existing subscription');
        _memorySubscription!.unsubscribe();
        _memorySubscription = null;
      }

      print('🔗 REALTIME: Setting up subscription for memory: $memoryId');

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
          print('   - Changed fields: ${payload.newRecord.keys.join(", ")}');

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

  Future<void> _handleMemoryUpdate(String memoryId, Map<String, dynamic> updatedData) async {
    try {
      print('🔄 REALTIME: Processing memory update');
      print('   - Memory ID: $memoryId');

      final title = updatedData['title'] as String?;
      final visibility = updatedData['visibility'] as String?;
      final startTime = updatedData['start_time'];
      final endTime = updatedData['end_time'];
      final location = updatedData['location_name'] as String?;

      // NEW: state/sealed updates
      final normalizedState = _normalizeState(updatedData['state']);
      final sealed = normalizedState.isNotEmpty ? _isSealedState(normalizedState) : (state.isSealed ?? false);

      final DateTime? startUtc = startTime != null ? _parseUtc(startTime) : null;
      final DateTime? endUtc = endTime != null ? _parseUtc(endTime) : null;

      state = state.copyWith(
        isSealed: sealed,
        memoryState: normalizedState.isNotEmpty ? normalizedState : state.memoryState,
        eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
          eventTitle: title ?? state.eventTimelineViewModel?.eventTitle,
          isPrivate: visibility == 'private',

          // NEW
          memoryState: normalizedState.isNotEmpty ? normalizedState : state.eventTimelineViewModel?.memoryState,
          isSealed: sealed,

          timelineDetail: TimelineDetailModel(
            centerLocation: location ??
                state.eventTimelineViewModel?.timelineDetail?.centerLocation ??
                'Unknown Location',
            centerDistance: state.eventTimelineViewModel?.timelineDetail?.centerDistance ?? '0km',
            memoryStartTime: startUtc ?? state.eventTimelineViewModel?.timelineDetail?.memoryStartTime,
            memoryEndTime: endUtc ?? state.eventTimelineViewModel?.timelineDetail?.memoryEndTime,
            timelineStories: state.eventTimelineViewModel?.timelineDetail?.timelineStories ?? [],
          ),
        ),
      );

      print('✅ REALTIME: Timeline state updated with new memory data');
    } catch (e, stackTrace) {
      print('❌ REALTIME ERROR: Failed to handle memory update: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    print('🧹 REALTIME: Cleaning up memory subscription');
    if (_memorySubscription != null) {
      _memorySubscription!.unsubscribe();
      _memorySubscription = null;
    }
    super.dispose();
  }

  Future<void> loadMemoryStories(String memoryId) async {
    try {
      print('🔍 TIMELINE DEBUG: Loading stories for memory: $memoryId');

      state = state.copyWith(isLoading: true, errorMessage: null);

      final storiesData = await _storyService.fetchMemoryStories(memoryId);

      print('🔍 TIMELINE DEBUG: Fetched ${storiesData.length} stories from database');

      if (storiesData.isEmpty) {
        print('⚠️ TIMELINE DEBUG: Memory exists but has no stories yet');

        final existingTimelineDetail = state.eventTimelineViewModel?.timelineDetail;

        state = state.copyWith(
          eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
            customStoryItems: [],
            timelineDetail: TimelineDetailModel(
              centerLocation: existingTimelineDetail?.centerLocation ?? 'Unknown Location',
              centerDistance: existingTimelineDetail?.centerDistance ?? '0km',
              memoryStartTime: existingTimelineDetail?.memoryStartTime,
              memoryEndTime: existingTimelineDetail?.memoryEndTime,
              timelineStories: [],
            ),
          ),
          errorMessage: null,
          isLoading: false,
        );
        return;
      }

      _currentMemoryStoryIds = storiesData.map((storyData) => storyData['id'] as String).toList();

      final memoryResponse = await SupabaseService.instance.client
          ?.from('memories')
          .select('start_time, end_time, state')
          .eq('id', memoryId)
          .single();

      // NEW: refresh state/sealed while loading stories too (covers invite race)
      if (memoryResponse != null) {
        final normalizedState = _normalizeState(memoryResponse['state']);
        final sealed = _isSealedState(normalizedState);
        state = state.copyWith(
          isSealed: sealed,
          memoryState: normalizedState,
          eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
            memoryState: normalizedState,
            isSealed: sealed,
          ),
        );
      }

      DateTime memoryStartTime;
      DateTime memoryEndTime;

      if (memoryResponse != null &&
          memoryResponse['start_time'] != null &&
          memoryResponse['end_time'] != null) {
        memoryStartTime = _parseUtc(memoryResponse['start_time']);
        memoryEndTime = _parseUtc(memoryResponse['end_time']);

        print('✅ TIMELINE DEBUG: Using memory window timestamps (UTC-normalized):');
        print('   - Event start: ${memoryStartTime.toIso8601String()}');
        print('   - Event end:   ${memoryEndTime.toIso8601String()}');
      } else {
        final storyTimes = storiesData.map((s) => _parseUtc(s['created_at'])).toList();
        storyTimes.sort();

        memoryStartTime = storyTimes.first;
        memoryEndTime = storyTimes.last;

        final padding = memoryEndTime.difference(memoryStartTime) * 0.1;
        memoryStartTime = memoryStartTime.subtract(padding);
        memoryEndTime = memoryEndTime.add(padding);

        print('⚠️ TIMELINE DEBUG: Memory window unavailable, using story range with padding (UTC-normalized)');
        print('   - Derived start: ${memoryStartTime.toIso8601String()}');
        print('   - Derived end:   ${memoryEndTime.toIso8601String()}');
      }

      final storyItems = storiesData.map((storyData) {
        final contributor =
            (storyData['user_profiles_public'] as Map<String, dynamic>?) ??
                (storyData['user_profiles'] as Map<String, dynamic>?);

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
          storyId: storyData['id'] as String,
        );
      }).toList();

      final timelineStories = storiesData.map((storyData) {
        final contributor =
            (storyData['user_profiles_public'] as Map<String, dynamic>?) ??
                (storyData['user_profiles'] as Map<String, dynamic>?);

        final createdAt = _parseUtc(storyData['created_at']);
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

      final existingTimelineDetail = state.eventTimelineViewModel?.timelineDetail;

      state = state.copyWith(
        timelineStories: timelineStories,
        memoryStartTime: memoryStartTime,
        memoryEndTime: memoryEndTime,
        eventTimelineViewModel: state.eventTimelineViewModel?.copyWith(
          customStoryItems: storyItems,
          timelineDetail: TimelineDetailModel(
            centerLocation: existingTimelineDetail?.centerLocation ?? 'Unknown Location',
            centerDistance: existingTimelineDetail?.centerDistance ?? '0km',
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
  // ignore: unused_element
  void _displaySnapshot(MemorySnapshot snapshot) {
    // Keep using the state's memoryId (it is set before snapshot display),
    // because MemorySnapshot in this project does not expose memoryId.
    final String? effectiveMemoryId = state.memoryId;

    state = state.copyWith(
      eventTimelineViewModel: EventTimelineViewModel(
        eventTitle: snapshot.title,
        eventDate: snapshot.date,
        isPrivate: snapshot.isPrivate,
        categoryIcon: snapshot.categoryIcon ?? '',
        participantImages: snapshot.participantAvatars ?? [],
        customStoryItems: [],
        timelineDetail: TimelineDetailModel(
          centerLocation: snapshot.location ?? 'Unknown',
          centerDistance: '0km',
        ),
        memoryId: effectiveMemoryId,

        // Do NOT set memoryState/isSealed here because MemorySnapshot
        // does not include state in this codebase.
        // These get set from DB in initializeFromMemory/loadMemoryStories/realtime updates.
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

      final memoryResponse =
      await client.from('memories').select('creator_id').eq('id', memoryId).single();

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

      final existingContributor = await client
          .from('memory_contributors')
          .select('id')
          .eq('memory_id', memoryId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingContributor != null) {
        print('⚠️ JOIN MEMORY: User is already a member');
        state = state.copyWith(isCurrentUserMember: true);
        return;
      }

      await client.from('memory_contributors').insert({
        'memory_id': memoryId,
        'user_id': currentUser.id,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });

      print('✅ JOIN MEMORY: User added as contributor');

      state = state.copyWith(isCurrentUserMember: true);

      await _cacheService.refreshMemoryCache(currentUser.id);

      print('✅ JOIN MEMORY: Successfully joined memory');
    } catch (e, stackTrace) {
      print('❌ JOIN MEMORY ERROR: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> leaveMemory(String memoryId) async {
    try {
      print('🔍 LEAVE MEMORY: Starting leave process');
      print('   - Memory ID: $memoryId');

      final client = SupabaseService.instance.client;
      if (client == null) {
        throw Exception('Supabase client is not initialized');
      }

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final memoryResponse =
      await client.from('memories').select('creator_id').eq('id', memoryId).single();

      final creatorId = memoryResponse['creator_id'] as String?;
      if (creatorId != null && creatorId == currentUser.id) {
        throw Exception('Memory creator cannot leave their own memory');
      }

      final existingContributor = await client
          .from('memory_contributors')
          .select('id')
          .eq('memory_id', memoryId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingContributor == null) {
        print('⚠️ LEAVE MEMORY: User is not a contributor (already left)');
        state = state.copyWith(
          isCurrentUserMember: false,
          isCurrentUserCreator: false,
        );
        return;
      }

      await client
          .from('memory_contributors')
          .delete()
          .eq('memory_id', memoryId)
          .eq('user_id', currentUser.id);

      print('✅ LEAVE MEMORY: Contributor row deleted');

      state = state.copyWith(
        isCurrentUserMember: false,
        isCurrentUserCreator: false,
      );

      await _cacheService.refreshMemoryCache(currentUser.id);

      print('✅ LEAVE MEMORY: Successfully left memory');
    } catch (e, stackTrace) {
      print('❌ LEAVE MEMORY ERROR: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }
}