import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/follows_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../models/following_list_model.dart';
import '../models/following_story_item_model.dart';

part 'following_list_state.dart';

final followingListNotifier =
StateNotifierProvider.autoDispose<FollowingListNotifier, FollowingListState>(
      (ref) => FollowingListNotifier(
    FollowingListState(
      followingListModel: FollowingListModel(),
      isLoading: false,
      searchQuery: '',
      searchResults: const [],
      isSearching: false,
    ),
  ),
);

class FollowingListNotifier extends StateNotifier<FollowingListState> {
  final FollowsService _followsService = FollowsService();
  final StoryService _storyService = StoryService();

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  FollowingListNotifier(FollowingListState state) : super(state);

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Start stories loading immediately (we will fill once we know following IDs)
      state = state.copyWith(isLoadingStories: true, latestStories: const []);

      final followingData = await client
          .from('follows')
          .select('following_id, user_profiles!follows_following_id_fkey(*)')
          .eq('follower_id', currentUser.id);

      final followingUsers = (followingData as List)
          .map((item) {
        final userProfile = item['user_profiles'] as Map<String, dynamic>?;
        if (userProfile == null) return null;

        final avatarUrl =
        AvatarHelperService.getAvatarUrl(userProfile['avatar_url']);
        final followerCount = userProfile['follower_count'] ?? 0;

        return FollowingUserModel(
          id: userProfile['id'] as String,
          name: (userProfile['display_name'] as String?) ??
              (userProfile['username'] as String? ?? ''),
          followersText: '$followerCount followers',
          profileImagePath: avatarUrl,
        );
      })
          .whereType<FollowingUserModel>()
          .toList();

      state = state.copyWith(
        followingListModel: state.followingListModel?.copyWith(
          followingUsers: followingUsers,
        ),
        isLoading: false,
      );

      // Fetch "Latest Stories" from followed users (compact row)
      final followingIds = followingUsers
          .map((u) => (u.id ?? '').trim())
          .where((id) => id.isNotEmpty)
          .toList();
      await _loadLatestStoriesForFollowing(
        client: client,
        currentUserId: currentUser.id,
        followingIds: followingIds,
      );

      // Keep search flags accurate if user already typed
      final q = (state.searchQuery ?? '').trim();
      if (q.isNotEmpty) {
        await _performSearch(q);
      }
    } catch (e) {
      print('Error loading following list: $e');
      state = state.copyWith(
        isLoading: false,
        followingListModel: state.followingListModel?.copyWith(
          followingUsers: [],
        ),
        isLoadingStories: false,
        latestStories: const [],
      );
    }
  }

  Future<void> _loadLatestStoriesForFollowing({
    required SupabaseClient client,
    required String currentUserId,
    required List<String> followingIds,
  }) async {
    try {
      if (followingIds.isEmpty) {
        state = state.copyWith(isLoadingStories: false, latestStories: const []);
        return;
      }

      final response = await client
          .from('stories')
          .select('''
            id,
            memory_id,
            contributor_id,
            image_url,
            video_url,
            thumbnail_url,
            media_type,
            created_at,
            user_profiles_public!stories_contributor_id_fkey (
              id,
              avatar_url
            ),
            memories!inner (
              visibility,
              state
            )
          ''')
          .eq('memories.visibility', 'public')
          .inFilter('contributor_id', followingIds)
          .order('created_at', ascending: false)
          .limit(30);

      final rows = (response as List?) ?? [];
      if (rows.isEmpty) {
        state = state.copyWith(isLoadingStories: false, latestStories: const []);
        return;
      }

      final storyIds =
          rows.map((r) => r['id'] as String?).whereType<String>().toList();

      // Batch read/unread status for current user
      Set<String> viewedStoryIds = {};
      if (storyIds.isNotEmpty) {
        final viewsResponse = await client
            .from('story_views')
            .select('story_id')
            .eq('user_id', currentUserId)
            .inFilter('story_id', storyIds);

        viewedStoryIds = (viewsResponse as List)
            .map((v) => v['story_id'] as String?)
            .whereType<String>()
            .toSet();
      }

      final items = rows.map((storyData) {
        final createdAtRaw = storyData['created_at'] as String?;
        DateTime createdAt;
        try {
          createdAt = createdAtRaw != null ? DateTime.parse(createdAtRaw) : DateTime.now();
        } catch (_) {
          createdAt = DateTime.now();
        }

        final storyMap = Map<String, dynamic>.from(storyData);
        final storyId = (storyData['id'] as String?) ?? '';
        final bg = _storyService.getStoryMediaUrl(
          storyMap,
        );
        final avatar = _storyService.getContributorAvatar(
          storyMap,
        );

        return FollowingStoryItemModel(
          id: storyId,
          backgroundImage: bg,
          profileImage: avatar,
          timestamp: _storyService.getTimeAgo(createdAt),
          isRead: viewedStoryIds.contains(storyId),
        );
      }).where((s) => (s.id ?? '').isNotEmpty).toList();

      state = state.copyWith(isLoadingStories: false, latestStories: items);
    } catch (e) {
      print('Error loading latest following stories: $e');
      state = state.copyWith(isLoadingStories: false, latestStories: const []);
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) return;

      final success =
      await _followsService.unfollowUser(currentUser.id, userId);

      if (success) {
        await initialize();
      }
    } catch (e) {
      print('Error unfollowing user: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ SEARCH (uses search_users_smart RPC)
  // ─────────────────────────────────────────────────────────────

  void onSearchChanged(String value) {
    final next = value;
    state = state.copyWith(
      searchQuery: next,
      isSearching: next.trim().isNotEmpty,
    );

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final q = next.trim();
      if (q.isEmpty) {
        state = state.copyWith(
          isSearching: false,
          searchResults: const [],
        );
        return;
      }
      await _performSearch(q);
    });
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isSearching: true);

    try {
      final client = SupabaseService.instance.client;
      final currentUser = client?.auth.currentUser;
      if (client == null || currentUser == null) {
        state = state.copyWith(isSearching: false, searchResults: const []);
        return;
      }

      // ✅ Match the NEW SQL signature (same as Friends search)
      final res = await client.rpc('search_users_smart', params: {
        'p_query': query.trim(),
        'p_limit': 12,
        'p_user_id': currentUser.id,
      });

      // stale guard (user typed again)
      final stillSame = (state.searchQuery ?? '').trim() == query.trim();
      if (!stillSame) return;

      if (res is! List) {
        print('search_users_smart unexpected return type: ${res.runtimeType}');
        state = state.copyWith(isSearching: false, searchResults: const []);
        return;
      }

      final rows = res;

      final results = rows.map((r) {
        final map = r as Map<String, dynamic>;

        final id = (map['id'] ?? '').toString();
        final username = (map['username'] as String?) ?? '';
        final displayName = (map['display_name'] as String?) ?? '';
        final avatarPath = map['avatar_url'];
        final avatar = AvatarHelperService.getAvatarUrl(avatarPath);

        final isFollowing = map['is_following'] == true;

        final mutual = (map['mutual_friend_count'] is int)
            ? (map['mutual_friend_count'] as int)
            : ((map['mutual_friend_count'] as num?)?.toInt() ?? 0);

        final distanceKm = map['distance_km'] != null
            ? (map['distance_km'] as num).toDouble()
            : null;

        return FollowingSearchUserModel(
          id: id,
          userName: username,
          displayName: displayName,
          profileImagePath: avatar,
          isFollowing: isFollowing,
          mutualFriendCount: mutual,
          distanceKm: distanceKm,
        );
      }).toList();

      state = state.copyWith(
        isSearching: false,
        searchResults: results,
      );
    } catch (e) {
      print('Search RPC error: $e');
      state = state.copyWith(
        isSearching: false,
        searchResults: const [],
      );
    }
  }

  void updateSearchUserFollowing(String userId, bool isFollowing) {
    final list = List<FollowingSearchUserModel>.from(state.searchResults ?? []);
    final i = list.indexWhere((u) => (u.id ?? '') == userId);
    if (i == -1) return;

    list[i] = list[i].copyWith(isFollowing: isFollowing);
    state = state.copyWith(searchResults: list);
  }

  Future<bool> followUser(String userId) async {
    try {
      final client = SupabaseService.instance.client;
      final currentUser = client?.auth.currentUser;
      if (client == null || currentUser == null) return false;
      if (userId.isEmpty) return false;

      await client.from('follows').insert({
        'follower_id': currentUser.id,
        'following_id': userId,
      });

      await initialize();
      return true;
    } catch (e) {
      print('Follow error: $e');
      return false;
    }
  }
}
