import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './avatar_helper_service.dart';
import './story_service.dart';
import './supabase_service.dart';

/// Service for fetching feed data from Supabase
class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  SupabaseClient? get _client => SupabaseService.instance.client;

  // Pagination constants
  static const int _pageSize = 10;

  // Keep StoryService instance for any non-static helpers you may already use elsewhere.
  // ignore: unused_field
  final _storyService = StoryService();

  // NEW: Real-time subscription management
  RealtimeChannel? _storyViewsChannel;

  // Toggle verbose logs without ripping out print() everywhere.
  static const bool _debugFeed = false;
  void _log(String msg) {
    if (_debugFeed) debugPrint(msg);
  }

  bool _isMissingColumn(PostgrestException e, String columnName) {
    final msg = (e.message).toLowerCase();
    final details = (e.details ?? '').toString().toLowerCase();
    final hint = (e.hint ?? '').toString().toLowerCase();
    final code = (e.code ?? '').toString();
    final col = columnName.toLowerCase();

    // Postgres undefined_column is 42703
    if (code == '42703') return true;
    if (msg.contains('column') && msg.contains(col) && msg.contains('does not exist')) {
      return true;
    }
    if (details.contains('column') && details.contains(col) && details.contains('does not exist')) {
      return true;
    }
    if (hint.contains('column') && hint.contains(col) && hint.contains('does not exist')) {
      return true;
    }
    return false;
  }

  // -----------------------------
  // BATCH HELPERS (PERFORMANCE)
  // -----------------------------

  /// Batch fetch story_ids viewed by a user for a given list of storyIds.
  Future<Set<String>> _fetchViewedStoryIdsForUser({
    required String userId,
    required List<String> storyIds,
  }) async {
    if (_client == null) return {};
    if (storyIds.isEmpty) return {};

    try {
      final views = await _client!
          .from('story_views')
          .select('story_id')
          .eq('user_id', userId)
          .inFilter('story_id', storyIds);

      final viewedIds = <String>{};
      for (final row in (views as List)) {
        final id = row['story_id'] as String?;
        if (id != null) viewedIds.add(id);
      }
      return viewedIds;
    } catch (e) {
      _log('❌ ERROR fetching viewed story IDs: $e');
      return {};
    }
  }

  /// Batch fetch up to [perMemoryLimit] contributor avatars for multiple memories.
  Future<Map<String, List<String>>> _fetchContributorAvatarsForMemories({
    required List<String> memoryIds,
    int perMemoryLimit = 3,
  }) async {
    if (_client == null) return {};
    if (memoryIds.isEmpty) return {};

    try {
      final rows = await _client!
          .from('memory_contributors')
          .select('memory_id, user_profiles_public!inner(avatar_url)')
          .inFilter('memory_id', memoryIds)
          .order('created_at', ascending: false);

      final Map<String, List<String>> byMemory = {};

      for (final r in (rows as List)) {
        final memoryId = r['memory_id'] as String?;
        if (memoryId == null) continue;

        final profile = r['user_profiles_public'] as Map<String, dynamic>?;
        final avatar = AvatarHelperService.getAvatarUrl(profile?['avatar_url']);

        if (avatar.isEmpty) continue;

        byMemory.putIfAbsent(memoryId, () => []);
        if (byMemory[memoryId]!.length < perMemoryLimit) {
          byMemory[memoryId]!.add(avatar);
        }
      }

      return byMemory;
    } catch (e) {
      _log('❌ ERROR fetching contributor avatars batch: $e');
      return {};
    }
  }

  /// Resolve a thumbnail path (storage path or URL) into a proper URL.
  /// IMPORTANT: This intentionally resolves ONLY the thumbnail (not video/image primary media),
  /// so you don't accidentally put video URLs into `thumbnail_url`.
  String _resolveThumbnailUrl(dynamic raw) {
    final rawStr = (raw ?? '').toString().trim();
    if (rawStr.isEmpty) return '';
    return StoryService.resolveStoryMediaUrl(rawStr) ?? rawStr;
  }

  // -----------------------------
  // RELATIONSHIP HELPERS (FRIENDS + FOLLOWING)
  // -----------------------------

  /// Returns friend user IDs for the current user.
  /// Requires: friendships(user_id, friend_id, status='accepted')
  Future<Set<String>> _fetchFriendUserIds(String currentUserId) async {
    if (_client == null) return {};

    try {
      final response = await _client!
          .from('friends')
          .select('user_id, friend_id')
          .or('user_id.eq.$currentUserId,friend_id.eq.$currentUserId');

      final Set<String> ids = {};

      for (final row in (response as List)) {
        final userId = row['user_id'] as String?;
        final friendId = row['friend_id'] as String?;

        if (userId == currentUserId && friendId != null) {
          ids.add(friendId);
        } else if (friendId == currentUserId && userId != null) {
          ids.add(userId);
        }
      }

      ids.remove(currentUserId);
      return ids;
    } catch (e) {
      _log('❌ ERROR fetching friend IDs: $e');
      return {};
    }
  }

  /// Returns user IDs that the current user is following.
  /// Requires: follows(follower_id, following_id)
  Future<Set<String>> _fetchFollowingUserIds(String currentUserId) async {
    if (_client == null) return {};

    try {
      final response = await _client!
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final Set<String> ids = {};
      for (final row in (response as List)) {
        final id = row['following_id'] as String?;
        if (id != null) ids.add(id);
      }

      ids.remove(currentUserId);
      return ids;
    } catch (e) {
      _log('❌ ERROR fetching following IDs: $e');
      return {};
    }
  }

  /// For You author set = friends ∪ following
  Future<Set<String>> _fetchForYouAuthorIds(String currentUserId) async {
    final friends = await _fetchFriendUserIds(currentUserId);
    final following = await _fetchFollowingUserIds(currentUserId);
    return {...friends, ...following};
  }

// ----------------------------------
// FOR YOU: GATING HELPERS (REPLACEMENT)
// ----------------------------------

  /// Returns true if user has 1+ (friends OR following)
  /// AND there is at least one matching story from those authors.
  /// REPLACEMENT: removed the past-24-hours filter (all-time).
  Future<bool> shouldServeForYouStoriesFeed() async {
    if (_client == null) return false;

    final currentUserId = _client!.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final authorIds = await _fetchForYouAuthorIds(currentUserId);
    if (authorIds.isEmpty) return false;

    return _hasForYouAuthorStories(authorIds: authorIds);
  }

  /// Cheap exists-check (limit 1) for whether any For You story exists.
  /// REPLACEMENT: removed the past-24-hours filter (all-time).
  Future<bool> _hasForYouAuthorStories({required Set<String> authorIds}) async {
    if (_client == null) return false;
    if (authorIds.isEmpty) return false;

    try {
      final response = await _client!
          .from('stories')
          .select(
        'id, created_at, contributor_id, memory_id, memories!inner(visibility, state)',
      )
          .eq('memories.visibility', 'public')
          .eq('memories.state', 'open')
      // ✅ removed: .gte('created_at', since)
          .inFilter('contributor_id', authorIds.toList())
          .order('created_at', ascending: false)
          .limit(1);

      final rows = (response as List);
      return rows.isNotEmpty;
    } catch (e) {
      _log('❌ ERROR checking For You author stories: $e');
      return false;
    }
  }


// ----------------------------------
// FROM FRIENDS: GATING HELPERS (REPLACEMENT)
// ----------------------------------

  /// Returns true if user has 1+ friends AND there is at least one story
  /// from any friend that matches criteria.
  /// REPLACEMENT: removed the past-24-hours filter (all-time).
  Future<bool> shouldServeFromFriendsFeed() async {
    if (_client == null) return false;

    final currentUserId = _client!.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final friendIds = await _fetchFriendUserIds(currentUserId);
    if (friendIds.isEmpty) return false;

    return _hasActiveFriendStories(friendIds: friendIds);
  }

  /// Cheap existence check (limit 1): does at least 1 matching friend story exist?
  /// REPLACEMENT: removed the past-24-hours filter (all-time).
  Future<bool> _hasActiveFriendStories({required Set<String> friendIds}) async {
    if (_client == null) return false;
    if (friendIds.isEmpty) return false;

    try {
      final response = await _client!
          .from('stories')
          .select(
        'id, created_at, contributor_id, memory_id, memories!inner(visibility, state)',
      )
          .eq('memories.visibility', 'public')
          .eq('memories.state', 'open')
      // ✅ removed: .gte('created_at', since)
          .inFilter('contributor_id', friendIds.toList())
          .order('created_at', ascending: false)
          .limit(1);

      final rows = (response as List);
      return rows.isNotEmpty;
    } catch (e) {
      _log('❌ ERROR checking active friend stories: $e');
      return false;
    }
  }





  // -----------------------------
  // VALIDATION (MEMORIES)
  // -----------------------------

  /// 🛡️ VALIDATION: Validates memory data completeness before rendering
  /// UPDATED: Use stories_count (DB enforced) instead of relying on joined stories list.
  bool _validateMemoryData(Map<String, dynamic> memory, String context) {
    final category = memory['memory_categories'] as Map<String, dynamic>?;
    final categoryIconUrl = category?['icon_url'] as String?;
    final categoryName = category?['name'] as String?;
    final title = memory['title'] as String?;

    final int storiesCount = (memory['stories_count'] is int)
        ? (memory['stories_count'] as int)
        : int.tryParse('${memory['stories_count'] ?? 0}') ?? 0;

    final validationErrors = <String>[];

    if (title == null || title.isEmpty) {
      validationErrors.add('Memory title is missing');
    }

    if (category == null) {
      validationErrors.add('Category join failed');
    }

    if (categoryIconUrl == null || categoryIconUrl.isEmpty) {
      validationErrors.add('Category icon_url is missing for "$categoryName"');
    }

    // Require stories_count > 0 (matches your DB rule)
    if (storiesCount <= 0) {
      validationErrors
          .add('Memory has no stories (stories_count=$storiesCount)');
    }

    if (validationErrors.isNotEmpty) {
      _log('❌ VALIDATION FAILED [$context] for memory "${memory['id']}":');
      for (final error in validationErrors) {
        _log('  - $error');
      }
      return false;
    }

    return true;
  }

  // -----------------------------
  // REALTIME: story_views
  // -----------------------------

  /// Subscribe to real-time story_views inserts
  RealtimeChannel? subscribeToStoryViews({
    required Function(String storyId, String userId) onStoryViewed,
  }) {
    if (_client == null) {
      _log('❌ ERROR: Cannot subscribe to story views - client is null');
      return null;
    }

    try {
      _storyViewsChannel?.unsubscribe();

      _storyViewsChannel = _client!
          .channel('story_views_realtime')
          .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'story_views',
        callback: (payload) {
          final storyId = payload.newRecord['story_id'] as String?;
          final userId = payload.newRecord['user_id'] as String?;

          if (storyId != null && userId != null) {
            onStoryViewed(storyId, userId);
          }
        },
      )
          .subscribe();

      _log('✅ SUCCESS: Subscribed to real-time story views');
      return _storyViewsChannel;
    } catch (e) {
      _log('❌ ERROR subscribing to story views: $e');
      return null;
    }
  }

  void unsubscribeFromStoryViews() {
    if (_storyViewsChannel != null) {
      _storyViewsChannel!.unsubscribe();
      _storyViewsChannel = null;
      _log('✅ SUCCESS: Unsubscribed from real-time story views');
    }
  }

// ----------------------------------
// STORIES: From Friends (FETCH) (REPLACEMENT)
// ----------------------------------

  /// Fetch public stories where the contributor is a friend of current user.
  /// REPLACEMENT: removed the past-24-hours filter (all-time).
  Future<List<Map<String, dynamic>>> fetchFromFriendsStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;
      if (currentUserId == null) {
        _log('❌ ERROR: No authenticated user');
        return [];
      }

      final friendIds = await _fetchFriendUserIds(currentUserId);
      if (friendIds.isEmpty) return [];

      final response = await _client!
          .from('stories')
          .select('''
          id,
          video_url,
          thumbnail_url,
          created_at,
          contributor_id,
          memory_id,
          view_count,
          memories!inner(
            title,
            state,
            visibility,
            category_id,
            memory_categories:category_id(
              id,
              name,
              icon_url
            )
          ),
          user_profiles_public!stories_contributor_id_fkey(
            id,
            display_name,
            avatar_url
          )
        ''')
          .eq('memories.visibility', 'public')
          .eq('memories.state', 'open')
      // ✅ removed: .gte('created_at', since)
          .inFilter('contributor_id', friendIds.toList())
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = (response as List);

      final storyIds = rows
          .map((r) => r['id'] as String?)
          .whereType<String>()
          .toList();

      final viewedIds = await _fetchViewedStoryIdsForUser(
        userId: currentUserId,
        storyIds: storyIds,
      );

      final validatedStories = <Map<String, dynamic>>[];

      for (final item in rows) {
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        final memoryTitle = (memory?['title'] as String?)?.trim();
        final contributorName = (contributor['display_name'] as String?)?.trim();
        final rawThumb = item['thumbnail_url'];

        if (memoryTitle == null ||
            memoryTitle.isEmpty ||
            contributorName == null ||
            contributorName.isEmpty ||
            rawThumb == null ||
            rawThumb.toString().trim().isEmpty) {
          continue;
        }

        final isRead = viewedIds.contains(item['id']);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': _resolveThumbnailUrl(rawThumb),
          'created_at': item['created_at'] ?? '',
          'view_count': item['view_count'] ?? 0,
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributorName,
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'memory_title': memoryTitle,
          'category_name': (category?['name'] as String?)?.trim() ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead,
        });
      }

      return validatedStories;
    } catch (e) {
      _log('❌ ERROR fetching From Friends stories: $e');
      return [];
    }
  }


  // -----------------------------
  // STORIES: For You (NEW)
  // -----------------------------

  /// Fetch public stories where contributor is a friend OR followed by current user.
  Future<List<Map<String, dynamic>>> fetchForYouStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;
      if (currentUserId == null) {
        _log('❌ ERROR: No authenticated user');
        return [];
      }

      final authorIds = await _fetchForYouAuthorIds(currentUserId);
      if (authorIds.isEmpty) return [];

      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            contributor_id,
            memory_id,
            view_count,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id(
                id,
                name,
                icon_url
              )
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('memories.visibility', 'public')
          .inFilter('contributor_id', authorIds.toList())
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = (response as List);

      final storyIds =
      rows.map((r) => r['id'] as String?).whereType<String>().toList();

      final viewedIds = await _fetchViewedStoryIdsForUser(
        userId: currentUserId,
        storyIds: storyIds,
      );

      final validatedStories = <Map<String, dynamic>>[];

      for (final item in rows) {
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        final memoryTitle = (memory?['title'] as String?)?.trim();
        final contributorName =
        (contributor['display_name'] as String?)?.trim();
        final rawThumb = item['thumbnail_url'];

        if (memoryTitle == null ||
            memoryTitle.isEmpty ||
            contributorName == null ||
            contributorName.isEmpty ||
            rawThumb == null ||
            rawThumb.toString().trim().isEmpty) {
          continue;
        }

        final isRead = viewedIds.contains(item['id']);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': _resolveThumbnailUrl(rawThumb),
          'created_at': item['created_at'] ?? '',
          'view_count': item['view_count'] ?? 0,
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributorName,
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'memory_title': memoryTitle,
          'category_name': (category?['name'] as String?)?.trim() ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead,
        });
      }

      return validatedStories;
    } catch (e) {
      _log('❌ ERROR fetching For You stories: $e');
      return [];
    }
  }

  // -----------------------------
  // MEMORIES: For You (NEW)
  // -----------------------------

  /// Fetch public memories where creator is a friend OR followed by current user.
  Future<List<Map<String, dynamic>>> fetchForYouMemories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;
      if (currentUserId == null) {
        _log('❌ ERROR: No authenticated user');
        return [];
      }

      final authorIds = await _fetchForYouAuthorIds(currentUserId);
      if (authorIds.isEmpty) return [];

      dynamic response;
      try {
        response = await _client!
            .from('memories')
            .select('''
            id,
            title,
            created_at,
            expires_at,
            location_name,
            contributor_count,
            state,
            visibility,
            creator_id,
            category_id,
            stories_count,
            memory_categories:category_id(
              name,
              icon_url
            ),
            stories(
              thumbnail_url,
              video_url
            )
          ''')
            .eq('visibility', 'public')
            .eq('is_daily_capsule', false)
            .gt('stories_count', 0)
            .eq('state', 'open')
            .inFilter('creator_id', authorIds.toList())
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
      } on PostgrestException catch (e) {
        // Backward-compat: if migration not applied yet, retry without is_daily_capsule.
        if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
        response = await _client!
            .from('memories')
            .select('''
            id,
            title,
            created_at,
            expires_at,
            location_name,
            contributor_count,
            state,
            visibility,
            creator_id,
            category_id,
            stories_count,
            memory_categories:category_id(
              name,
              icon_url
            ),
            stories(
              thumbnail_url,
              video_url
            )
          ''')
            .eq('visibility', 'public')
            .gt('stories_count', 0)
            .eq('state', 'open')
            .inFilter('creator_id', authorIds.toList())
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
      }

      final rows = (response as List);

      final memoryIds =
      rows.map((m) => m['id'] as String?).whereType<String>().toList();

      final avatarsByMemory = await _fetchContributorAvatarsForMemories(
        memoryIds: memoryIds,
        perMemoryLimit: 3,
      );

      final List<Map<String, dynamic>> transformedMemories = [];

      for (final memory in rows) {
        if (!_validateMemoryData(memory, 'ForYouMemories')) continue;

        final category = memory['memory_categories'] as Map<String, dynamic>?;
        final categoryIconUrl = category?['icon_url'] ?? '';

        final stories = memory['stories'] as List? ?? [];
        final mediaItems = stories
            .where((s) =>
        s['thumbnail_url'] != null &&
            s['thumbnail_url'].toString().trim().isNotEmpty)
            .take(2)
            .map((s) => {
          'thumbnail_url': _resolveThumbnailUrl(s['thumbnail_url']),
          'video_url': s['video_url'],
        })
            .toList();

        if (mediaItems.isEmpty) {
          continue;
        }

        final createdAt = DateTime.parse(memory['created_at']);
        final expiresAt = DateTime.parse(memory['expires_at']);

        final memoryId = memory['id'] as String? ?? '';

        transformedMemories.add({
          'id': memoryId,
          'title': memory['title'] ?? 'Untitled Memory',
          'date': _formatDate(createdAt),
          'category_icon': categoryIconUrl,
          'contributor_avatars': avatarsByMemory[memoryId] ?? <String>[],
          'media_items': mediaItems,
          'start_date': _formatDate(createdAt),
          'start_time': _formatTime(createdAt),
          'end_date': _formatDate(expiresAt),
          'end_time': _formatTime(expiresAt),
          'location': memory['location_name'] ?? '',
          'state': memory['state'] ?? 'open',
          'visibility': memory['visibility'] ?? 'public',
          'stories_count': memory['stories_count'] ?? 0,
        });
      }

      return transformedMemories;
    } catch (e) {
      _log('❌ ERROR fetching For You memories: $e');
      return [];
    }
  }

  // -----------------------------
  // STORIES: Happening Now
  // -----------------------------

  /// Fetch recent stories for "Happening Now" section with pagination
  /// Returns stories from the last 24 hours sorted by creation time
  Future<List<Map<String, dynamic>>> fetchHappeningNowStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;

      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            contributor_id,
            memory_id,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id(
                id,
                name,
                icon_url
              )
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte(
        'created_at',
        DateTime.now()
            .subtract(const Duration(hours: 24))
            .toIso8601String(),
      )
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = (response as List);

      // Batch view status
      final storyIds =
      rows.map((r) => r['id'] as String?).whereType<String>().toList();

      final viewedIds = (currentUserId != null)
          ? await _fetchViewedStoryIdsForUser(
        userId: currentUserId,
        storyIds: storyIds,
      )
          : <String>{};

      final validatedStories = <Map<String, dynamic>>[];

      for (final item in rows) {
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        // Required fields
        final memoryTitle = (memory?['title'] as String?)?.trim();
        final contributorName =
        (contributor['display_name'] as String?)?.trim();
        final rawThumb = item['thumbnail_url'];

        if (memoryTitle == null ||
            memoryTitle.isEmpty ||
            contributorName == null ||
            contributorName.isEmpty ||
            rawThumb == null ||
            rawThumb.toString().trim().isEmpty) {
          _log(
            '⚠️ Skipping story "${item['id']}" - missing required fields',
          );
          continue;
        }

        final isRead =
            (currentUserId != null) && viewedIds.contains(item['id']);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': _resolveThumbnailUrl(rawThumb),
          'created_at': item['created_at'] ?? '',
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributorName,
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'memory_title': memoryTitle,
          'category_name': (category?['name'] as String?)?.trim() ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead,
        });
      }

      return validatedStories;
    } catch (e) {
      _log('❌ ERROR fetching happening now stories: $e');
      return [];
    }
  }

  // -----------------------------
  // MEMORIES: Public Memories
  // -----------------------------

  /// Fetch public memories for "Public Memories" section with pagination
  Future<List<Map<String, dynamic>>> fetchPublicMemories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      dynamic response;
      try {
        response = await _client!
            .from('memories')
            .select('''
          id,
          title,
          created_at,
          expires_at,
          location_name,
          contributor_count,
          state,
          visibility,
          creator_id,
          category_id,
          stories_count,
          memory_categories:category_id(
            name,
            icon_url
          ),
          stories(
            thumbnail_url,
            video_url
          )
        ''')
            .eq('visibility', 'public')
            .eq('is_daily_capsule', false)
            .gt('stories_count', 0)
            .eq('state', 'open')
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
      } on PostgrestException catch (e) {
        if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
        response = await _client!
            .from('memories')
            .select('''
          id,
          title,
          created_at,
          expires_at,
          location_name,
          contributor_count,
          state,
          visibility,
          creator_id,
          category_id,
          stories_count,
          memory_categories:category_id(
            name,
            icon_url
          ),
          stories(
            thumbnail_url,
            video_url
          )
        ''')
            .eq('visibility', 'public')
            .gt('stories_count', 0)
            .eq('state', 'open')
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
      }

      final rows = (response as List);

      // Batch contributor avatars for these memories
      final memoryIds =
      rows.map((m) => m['id'] as String?).whereType<String>().toList();

      final avatarsByMemory = await _fetchContributorAvatarsForMemories(
        memoryIds: memoryIds,
        perMemoryLimit: 3,
      );

      final List<Map<String, dynamic>> transformedMemories = [];

      for (final memory in rows) {
        if (!_validateMemoryData(memory, 'PublicMemories')) continue;

        final category = memory['memory_categories'] as Map<String, dynamic>?;
        final categoryIconUrl = category?['icon_url'] ?? '';

        final stories = memory['stories'] as List? ?? [];
        final mediaItems = stories
            .where((s) =>
        s['thumbnail_url'] != null &&
            s['thumbnail_url'].toString().trim().isNotEmpty)
            .take(2)
            .map((s) => {
          'thumbnail_url': _resolveThumbnailUrl(s['thumbnail_url']),
          'video_url': s['video_url'],
        })
            .toList();

        if (mediaItems.isEmpty) {
          _log(
              '⚠️ Skipping memory "${memory['title']}" - no valid media items');
          continue;
        }

        final createdAt = DateTime.parse(memory['created_at']);
        final expiresAt = DateTime.parse(memory['expires_at']);

        final memoryId = memory['id'] as String? ?? '';

        transformedMemories.add({
          'id': memoryId,
          'title': memory['title'] ?? 'Untitled Memory',
          'date': _formatDate(createdAt),
          'category_icon': categoryIconUrl,
          'contributor_avatars': avatarsByMemory[memoryId] ?? <String>[],
          'media_items': mediaItems,
          'start_date': _formatDate(createdAt),
          'start_time': _formatTime(createdAt),
          'end_date': _formatDate(expiresAt),
          'end_time': _formatTime(expiresAt),
          'location': memory['location_name'] ?? '',
          'state': memory['state'] ?? 'open',
          'visibility': memory['visibility'] ?? 'public',
          'stories_count': memory['stories_count'] ?? 0,
        });
      }

      return transformedMemories;
    } catch (e) {
      _log('❌ ERROR fetching public memories: $e');
      return [];
    }
  }

  // -----------------------------
  // STORIES: Trending
  // -----------------------------

  /// Fetch trending stories with pagination
  Future<List<Map<String, dynamic>>> fetchTrendingStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;

      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            view_count,
            contributor_id,
            memory_id,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id!inner(
                name,
                icon_url
              )
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte(
        'created_at',
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      )
          .order('view_count', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = (response as List);

      // Batch view status
      final storyIds =
      rows.map((r) => r['id'] as String?).whereType<String>().toList();

      final viewedIds = (currentUserId != null)
          ? await _fetchViewedStoryIdsForUser(
        userId: currentUserId,
        storyIds: storyIds,
      )
          : <String>{};

      final validatedStories = <Map<String, dynamic>>[];

      for (final item in rows) {
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        final memoryTitle = (memory?['title'] as String?)?.trim();
        final contributorName =
        (contributor['display_name'] as String?)?.trim();
        final rawThumb = item['thumbnail_url'];

        if (memoryTitle == null ||
            memoryTitle.isEmpty ||
            contributorName == null ||
            contributorName.isEmpty ||
            rawThumb == null ||
            rawThumb.toString().trim().isEmpty) {
          continue;
        }

        final isRead =
            (currentUserId != null) && viewedIds.contains(item['id']);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': _resolveThumbnailUrl(rawThumb),
          'created_at': item['created_at'] ?? '',
          'view_count': item['view_count'] ?? 0,
          'contributor_name': contributorName,
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'memory_title': memoryTitle,
          'category_name': (category?['name'] as String?)?.trim() ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead,
        });
      }

      return validatedStories;
    } catch (e) {
      _log('Error fetching trending stories: $e');
      return [];
    }
  }

  // -----------------------------
  // STORIES: Longest Streak
  // -----------------------------

  /// Fetch longest streak stories with pagination
  Future<List<Map<String, dynamic>>> fetchLongestStreakStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;

      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            contributor_id,
            memory_id,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id(
                id,
                name,
                icon_url
              )
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              posting_streak
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte(
        'created_at',
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      )
          .order('user_profiles_public(posting_streak)', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = (response as List);

      // Batch view status
      final storyIds =
      rows.map((r) => r['id'] as String?).whereType<String>().toList();

      final viewedIds = (currentUserId != null)
          ? await _fetchViewedStoryIdsForUser(
        userId: currentUserId,
        storyIds: storyIds,
      )
          : <String>{};

      final validatedStories = <Map<String, dynamic>>[];

      for (final item in rows) {
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        final memoryTitle = (memory?['title'] as String?)?.trim();
        final contributorName =
        (contributor['display_name'] as String?)?.trim();
        final rawThumb = item['thumbnail_url'];

        if (memoryTitle == null ||
            memoryTitle.isEmpty ||
            contributorName == null ||
            contributorName.isEmpty ||
            rawThumb == null ||
            rawThumb.toString().trim().isEmpty) {
          continue;
        }

        final isRead =
            (currentUserId != null) && viewedIds.contains(item['id']);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': _resolveThumbnailUrl(rawThumb),
          'created_at': item['created_at'] ?? '',
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributorName,
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'posting_streak': contributor['posting_streak'] ?? 0,
          'memory_title': memoryTitle,
          'category_name': (category?['name'] as String?)?.trim() ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead,
        });
      }

      return validatedStories;
    } catch (e) {
      _log('❌ ERROR fetching longest streak stories: $e');
      return [];
    }
  }

  // -----------------------------
  // STORIES: Popular User Stories
  // -----------------------------

  /// Fetch popular user stories with pagination
  Future<List<Map<String, dynamic>>> fetchPopularUserStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;

      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            contributor_id,
            memory_id,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id(
                id,
                name,
                icon_url
              )
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              popularity_score
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte(
        'created_at',
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      )
          .order('user_profiles_public(popularity_score)', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = (response as List);

      // Batch view status
      final storyIds =
      rows.map((r) => r['id'] as String?).whereType<String>().toList();

      final viewedIds = (currentUserId != null)
          ? await _fetchViewedStoryIdsForUser(
        userId: currentUserId,
        storyIds: storyIds,
      )
          : <String>{};

      final validatedStories = <Map<String, dynamic>>[];

      for (final item in rows) {
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        final memoryTitle = (memory?['title'] as String?)?.trim();
        final contributorName =
        (contributor['display_name'] as String?)?.trim();
        final rawThumb = item['thumbnail_url'];

        if (memoryTitle == null ||
            memoryTitle.isEmpty ||
            contributorName == null ||
            contributorName.isEmpty ||
            rawThumb == null ||
            rawThumb.toString().trim().isEmpty) {
          continue;
        }

        final isRead =
            (currentUserId != null) && viewedIds.contains(item['id']);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': _resolveThumbnailUrl(rawThumb),
          'created_at': item['created_at'] ?? '',
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributorName,
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'popularity_score': contributor['popularity_score'] ?? 0,
          'memory_title': memoryTitle,
          'category_name': (category?['name'] as String?)?.trim() ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead,
        });
      }

      return validatedStories;
    } catch (e) {
      _log('❌ ERROR fetching popular user stories: $e');
      return [];
    }
  }

  // -----------------------------
  // STORIES: Popular Now
  // -----------------------------

  /// Fetch popular now stories with pagination
  /// Filters: public memories, posted within 7 days
  /// Sorted by: popularity_score from user_profiles
  Future<List<Map<String, dynamic>>> fetchPopularNowStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;

      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            contributor_id,
            memory_id,
            reaction_count,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id!inner(
                name,
                icon_url
              )
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              popularity_score
            )
          ''')
          .eq('memories.visibility', 'public')
          .gte(
        'created_at',
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      )
          .order('user_profiles_public(popularity_score)', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = (response as List);

      // Batch view status
      final storyIds =
      rows.map((r) => r['id'] as String?).whereType<String>().toList();

      final viewedIds = (currentUserId != null)
          ? await _fetchViewedStoryIdsForUser(
        userId: currentUserId,
        storyIds: storyIds,
      )
          : <String>{};

      final validatedStories = <Map<String, dynamic>>[];

      for (final item in rows) {
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        final memoryTitle = (memory?['title'] as String?)?.trim();
        final contributorName =
        (contributor['display_name'] as String?)?.trim();
        final rawThumb = item['thumbnail_url'];

        if (memoryTitle == null ||
            memoryTitle.isEmpty ||
            contributorName == null ||
            contributorName.isEmpty ||
            rawThumb == null ||
            rawThumb.toString().trim().isEmpty) {
          continue;
        }

        final isRead =
            (currentUserId != null) && viewedIds.contains(item['id']);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': _resolveThumbnailUrl(rawThumb),
          'created_at': item['created_at'] ?? '',
          'reaction_count': item['reaction_count'] ?? 0,
          'contributor_name': contributorName,
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'popularity_score': contributor['popularity_score'] ?? 0,
          'memory_title': memoryTitle,
          'category_name': (category?['name'] as String?)?.trim() ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead,
        });
      }

      return validatedStories;
    } catch (e) {
      _log('❌ ERROR fetching popular now stories: $e');
      return [];
    }
  }

  // -----------------------------
  // MEMORIES: Popular Memories
  // -----------------------------

  /// Fetch popular memories with pagination
  Future<List<Map<String, dynamic>>> fetchPopularMemories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      dynamic response;
      try {
        response = await _client!
            .from('memories')
            .select('''
      id,
      title,
      created_at,
      expires_at,
      location_name,
      contributor_count,
      state,
      visibility,
      creator_id,
      category_id,
      popularity_score,
      stories_count,
      memory_categories:category_id(
        name,
        icon_url
      ),
      stories(
        thumbnail_url,
        video_url
      )
    ''')
            .eq('visibility', 'public')
            .eq('is_daily_capsule', false)
            .gt('stories_count', 0)
            .eq('state', 'open')
            .order('popularity_score', ascending: false)
            .range(offset, offset + limit - 1);
      } on PostgrestException catch (e) {
        if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
        response = await _client!
            .from('memories')
            .select('''
      id,
      title,
      created_at,
      expires_at,
      location_name,
      contributor_count,
      state,
      visibility,
      creator_id,
      category_id,
      popularity_score,
      stories_count,
      memory_categories:category_id(
        name,
        icon_url
      ),
      stories(
        thumbnail_url,
        video_url
      )
    ''')
            .eq('visibility', 'public')
            .gt('stories_count', 0)
            .eq('state', 'open')
            .order('popularity_score', ascending: false)
            .range(offset, offset + limit - 1);
      }

      final rows = (response as List);

      // Batch contributor avatars for these memories
      final memoryIds =
      rows.map((m) => m['id'] as String?).whereType<String>().toList();

      final avatarsByMemory = await _fetchContributorAvatarsForMemories(
        memoryIds: memoryIds,
        perMemoryLimit: 3,
      );

      final List<Map<String, dynamic>> transformedMemories = [];

      for (final memory in rows) {
        if (!_validateMemoryData(memory, 'PopularMemories')) continue;

        final category = memory['memory_categories'] as Map<String, dynamic>?;
        final categoryIconUrl = category?['icon_url'] ?? '';

        final stories = memory['stories'] as List? ?? [];
        final mediaItems = stories
            .where((s) =>
        s['thumbnail_url'] != null &&
            s['thumbnail_url'].toString().trim().isNotEmpty)
            .take(2)
            .map((s) => {
          'thumbnail_url': _resolveThumbnailUrl(s['thumbnail_url']),
          'video_url': s['video_url'],
        })
            .toList();

        if (mediaItems.isEmpty) {
          continue;
        }

        final createdAt = DateTime.parse(memory['created_at']);
        final expiresAt = DateTime.parse(memory['expires_at']);

        final memoryId = memory['id'] as String? ?? '';

        transformedMemories.add({
          'id': memoryId,
          'title': memory['title'] ?? 'Untitled Memory',
          'date': _formatDate(createdAt),
          'category_icon': categoryIconUrl,
          'contributor_avatars': avatarsByMemory[memoryId] ?? <String>[],
          'media_items': mediaItems,
          'start_date': _formatDate(createdAt),
          'start_time': _formatTime(createdAt),
          'end_date': _formatDate(expiresAt),
          'end_time': _formatTime(expiresAt),
          'location': memory['location_name'] ?? '',
          'state': memory['state'] ?? 'open',
          'popularity_score': memory['popularity_score'] ?? 0,
        });
      }

      return transformedMemories;
    } catch (e) {
      _log('❌ ERROR fetching popular memories: $e');
      return [];
    }
  }

  // -----------------------------
  // STORIES: Latest (All-time)
  // -----------------------------

  /// Fetch latest stories (all public stories ordered by created_at desc)
  /// Works for authenticated + anonymous users.
  Future<List<Map<String, dynamic>>> fetchLatestStories({
    int offset = 0,
    int limit = _pageSize,
  }) async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;

      final response = await _client!
          .from('stories')
          .select('''
            id,
            video_url,
            thumbnail_url,
            created_at,
            contributor_id,
            memory_id,
            memories!inner(
              title,
              state,
              visibility,
              category_id,
              memory_categories:category_id(
                id,
                name,
                icon_url
              )
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('memories.visibility', 'public')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final rows = (response as List);

      // Batch view status
      final storyIds =
      rows.map((r) => r['id'] as String?).whereType<String>().toList();

      final viewedIds = (currentUserId != null)
          ? await _fetchViewedStoryIdsForUser(
        userId: currentUserId,
        storyIds: storyIds,
      )
          : <String>{};

      final validatedStories = <Map<String, dynamic>>[];

      for (final item in rows) {
        final memory = item['memories'] as Map<String, dynamic>?;
        final contributor =
            item['user_profiles_public'] as Map<String, dynamic>? ?? {};
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        final memoryTitle = (memory?['title'] as String?)?.trim();
        final contributorName =
        (contributor['display_name'] as String?)?.trim();
        final rawThumb = item['thumbnail_url'];

        if (memoryTitle == null ||
            memoryTitle.isEmpty ||
            contributorName == null ||
            contributorName.isEmpty ||
            rawThumb == null ||
            rawThumb.toString().trim().isEmpty) {
          continue;
        }

        final isRead =
            (currentUserId != null) && viewedIds.contains(item['id']);

        validatedStories.add({
          'id': item['id'] ?? '',
          'thumbnail_url': _resolveThumbnailUrl(rawThumb),
          'created_at': item['created_at'] ?? '',
          'memory_id': item['memory_id'] ?? '',
          'contributor_name': contributorName,
          'contributor_avatar': AvatarHelperService.getAvatarUrl(
            contributor['avatar_url'],
          ),
          'memory_title': memoryTitle,
          'category_name': (category?['name'] as String?)?.trim() ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'is_read': isRead,
        });
      }

      return validatedStories;
    } catch (e, stackTrace) {
      _log('❌ ERROR in fetchLatestStories(): $e');
      _log('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Fetch all latest story IDs in chronological order (latest first)
  /// Shows ALL public stories. Works for authenticated + anonymous users.
  Future<List<String>> fetchLatestStoryIds() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        _log('❌ ERROR: Supabase client not initialized');
        return [];
      }

      final response = await client.from('stories').select('''
            id,
            created_at,
            memory_id,
            memories!inner(visibility)
          ''').eq('memories.visibility', 'public').order('created_at',
          ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final storyIds =
      (response as List).map((story) => story['id'] as String).toList();

      return storyIds;
    } catch (e) {
      _log('❌ ERROR fetching latest story IDs: $e');
      return [];
    }
  }

  /// Fetch "Happening Now" story IDs (stories from last 24 hours) in chronological order
  /// Shows ONLY stories that match the "happening now" criteria (last 24 hours)
  Future<List<String>> fetchHappeningNowStoryIds() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        _log('❌ ERROR: Supabase client not initialized');
        return [];
      }

      final response = await client
          .from('stories')
          .select('''
            id,
            created_at,
            memory_id,
            memories!inner(visibility)
          ''')
          .eq('memories.visibility', 'public')
          .gte(
        'created_at',
        DateTime.now()
            .subtract(const Duration(hours: 24))
            .toIso8601String(),
      )
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        _log('⚠️ WARNING: No happening now stories found');
        return [];
      }

      final storyIds =
      (response as List).map((story) => story['id'] as String).toList();

      _log('✅ SUCCESS: Fetched ${storyIds.length} happening now story IDs');
      return storyIds;
    } catch (e) {
      _log('❌ ERROR fetching happening now story IDs: $e');
      return [];
    }
  }

  // -----------------------------
  // USER ACTIVE MEMORIES
  // -----------------------------

  /// Fetch user's active memories where they are a contributor
  /// Returns memories with state='open' that haven't expired
  Future<List<Map<String, dynamic>>> fetchUserActiveMemories() async {
    if (_client == null) return [];

    try {
      final currentUserId = _client!.auth.currentUser?.id;
      if (currentUserId == null) {
        _log('❌ ERROR: No authenticated user');
        return [];
      }

      // Get memory IDs where user is a contributor
      final contributorResponse = await _client!
          .from('memory_contributors')
          .select('memory_id')
          .eq('user_id', currentUserId);

      final contributorIds = (contributorResponse as List? ?? const [])
          .map((c) => (c as Map)['memory_id'] as String?)
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toList();

      dynamic response;
      try {
        response = await _client!
            .from('memories')
            .select('''
            id,
            title,
            state,
            visibility,
            created_at,
            expires_at,
            creator_id,
            category_id,
            memory_categories:category_id(
              name,
              icon_url
            ),
            user_profiles_public:creator_id(
              id,
              display_name,
              avatar_url
            )
          ''')
            // Include both:
            // - memories the user created
            // - memories they joined via memory_contributors
            .or(
              contributorIds.isNotEmpty
                  ? 'creator_id.eq.$currentUserId,id.in.(${contributorIds.join(",")})'
                  : 'creator_id.eq.$currentUserId',
            )
            .eq('is_daily_capsule', false)
            .eq('state', 'open')
            .gt('expires_at', DateTime.now().toIso8601String())
            .order('created_at', ascending: false);
      } on PostgrestException catch (e) {
        if (!_isMissingColumn(e, 'is_daily_capsule')) rethrow;
        response = await _client!
            .from('memories')
            .select('''
            id,
            title,
            state,
            visibility,
            created_at,
            expires_at,
            creator_id,
            category_id,
            memory_categories:category_id(
              name,
              icon_url
            ),
            user_profiles_public:creator_id(
              id,
              display_name,
              avatar_url
            )
          ''')
            .or(
              contributorIds.isNotEmpty
                  ? 'creator_id.eq.$currentUserId,id.in.(${contributorIds.join(",")})'
                  : 'creator_id.eq.$currentUserId',
            )
            .eq('state', 'open')
            .gt('expires_at', DateTime.now().toIso8601String())
            .order('created_at', ascending: false);
      }

      final activeMemories = (response as List).map((memory) {
        final category = memory['memory_categories'] as Map<String, dynamic>?;
        final creator = memory['user_profiles_public'] as Map<String, dynamic>?;

        final createdAt = DateTime.parse(memory['created_at']);
        final expiresAt = DateTime.parse(memory['expires_at']);

        final creatorName = (creator?['display_name'] as String?)?.trim();
        final safeCreatorName =
        (creatorName != null && creatorName.isNotEmpty) ? creatorName : null;

        return {
          'id': memory['id'] ?? '',
          'title': memory['title'] ?? 'Untitled Memory',
          'visibility': memory['visibility'] ?? 'private',
          'category_name': category?['name'] ?? 'Custom',
          'category_icon': category?['icon_url'] ?? '',
          'created_at': memory['created_at'] ?? '',
          'expires_at': memory['expires_at'] ?? '',
          'created_date': _formatDate(createdAt),
          'expiration_text': _formatExpirationTime(expiresAt),
          'creator_id': memory['creator_id'],
          'creator_name': safeCreatorName,
        };
      }).toList();

      return activeMemories;
    } catch (e) {
      _log('❌ ERROR fetching user active memories: $e');
      return [];
    }
  }

  // -----------------------------
  // HELPERS
  // -----------------------------

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatExpirationTime(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'expired';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'expires in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'expires in $hours ${hours == 1 ? 'hour' : 'hours'}';
    } else {
      final days = difference.inDays;
      return 'expires in $days ${days == 1 ? 'day' : 'days'}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute$period';
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // -----------------------------
  // MEMORY DETAILS (Event view)
  // -----------------------------

  Future<Map<String, dynamic>?> fetchMemoryDetails(String memoryId) async {
    if (_client == null) return null;

    try {
      final memoryResponse = await _client!.from('memories').select('''
            id,
            title,
            created_at,
            expires_at,
            location_name,
            view_count,
            contributor_count
          ''').eq('id', memoryId).single();

      final contributorsResponse =
      await _client!.from('memory_contributors').select('''
            id,
            user_id,
            user_profiles_public!inner(
              id,
              display_name,
              avatar_url
            )
          ''').eq('memory_id', memoryId);

      final contributors = (contributorsResponse as List).map((c) {
        final profile = c['user_profiles_public'] as Map<String, dynamic>?;
        return {
          'contributorId': c['user_id'] ?? '',
          'contributorName': profile?['display_name'] ?? 'Unknown User',
          'contributorImage': AvatarHelperService.getAvatarUrl(
            profile?['avatar_url'],
          ),
        };
      }).toList();

      final storiesResponse = await _client!.from('stories').select('''
            id,
            thumbnail_url,
            video_url,
            created_at
          ''').eq('memory_id', memoryId).order('created_at', ascending: true);

      final stories = (storiesResponse as List).map((s) {
        return {
          'storyId': s['id'] ?? '',
          'storyImage': _resolveThumbnailUrl(s['thumbnail_url']),
          'timeAgo': _getRelativeTime(DateTime.parse(s['created_at'])),
        };
      }).toList();

      final createdAt = DateTime.parse(memoryResponse['created_at']);

      return {
        'eventTitle': memoryResponse['title'] ?? 'Untitled Memory',
        'eventDate': _formatDate(createdAt),
        'eventLocation': memoryResponse['location_name'] ?? '',
        'viewCount': memoryResponse['view_count']?.toString() ?? '0',
        'contributorsList': contributors,
        'storiesList': stories,
      };
    } catch (e) {
      _log('Error fetching memory details: $e');
      return null;
    }
  }

  // -----------------------------
  // STORY DETAILS (Viewer)
  // -----------------------------

  Future<Map<String, dynamic>?> fetchStoryDetails(String storyId) async {
    if (_client == null) return null;

    try {
      final response = await _client!.from('stories').select('''
            id,
            share_code,
            image_url,
            video_url,
            media_type,
            thumbnail_url,
            text_overlays,
            location_name,
            created_at,
            view_count,
            contributor_id,
            memory_id,
            memories!inner(
              id,
              title,
              created_at,
              location_name,
              visibility
            ),
            user_profiles_public!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              username
            ),
            user_profiles!stories_contributor_id_fkey(
              id,
              display_name,
              avatar_url,
              username
            )
          ''').eq('id', storyId).single();

      final contributor =
          (response['user_profiles_public'] as Map<String, dynamic>?) ??
          (response['user_profiles'] as Map<String, dynamic>?);
      final memory = response['memories'] as Map<String, dynamic>?;
      final textOverlays = response['text_overlays'] as List? ?? [];

      String? caption;
      if (textOverlays.isNotEmpty && textOverlays[0] is Map) {
        caption = (textOverlays[0] as Map)['text'] as String?;
      }

      final mediaType = response['media_type'] as String? ?? 'image';
      String mediaUrl = '';

      if (mediaType == 'video') {
        final rawVideoPath =
            response['video_url'] ?? response['thumbnail_url'] ?? '';
        mediaUrl = StoryService.resolveStoryMediaUrl(rawVideoPath) ?? '';
      } else {
        final rawImagePath =
            response['image_url'] ?? response['thumbnail_url'] ?? '';
        mediaUrl = StoryService.resolveStoryMediaUrl(rawImagePath) ?? '';
      }

      return {
        'id': storyId,
        'share_code': response['share_code'],
        'media_url': mediaUrl,
        'media_type': mediaType,
        'user_name': (contributor?['display_name'] ??
                contributor?['username'] ??
                'Unknown User')
            .toString(),
        // Always keep a stable user_id even if profile join is missing.
        'user_id': (contributor?['id'] ?? response['contributor_id'] ?? '').toString(),
        'user_avatar': AvatarHelperService.getAvatarUrl(
          (contributor?['avatar_url'] as String?)?.trim(),
        ),
        'created_at': response['created_at'] ?? '',
        'location': response['location_name'],
        'caption': caption,
        'view_count': response['view_count'] ?? 0,
        'memory_id': response['memory_id'] ?? '',
        'memory_title': memory?['title'] ?? 'Untitled Memory',
        'memory_date': memory?['created_at'] ?? '',
        'memory_location': memory?['location_name'] ?? '',
        'memory_visibility': memory?['visibility'] ?? '',
      };
    } catch (e) {
      _log('❌ ERROR fetching story details: $e');
      return null;
    }
  }

  // -----------------------------
  // MEMORY STORY IDS (Cycling)
  // -----------------------------

  Future<List<String>> fetchMemoryStoryIds(String memoryId) async {
    if (_client == null) return [];

    try {
      final response = await _client!
          .from('stories')
          .select('id')
          .eq('memory_id', memoryId)
          .order('created_at', ascending: true);

      return (response as List).map((item) => item['id'] as String).toList();
    } catch (e) {
      _log('❌ ERROR fetching memory story IDs: $e');
      return [];
    }
  }
}
