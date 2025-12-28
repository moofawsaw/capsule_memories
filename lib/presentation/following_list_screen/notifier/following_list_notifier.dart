import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/follows_service.dart';
import '../../../services/supabase_service.dart';
import '../models/following_list_model.dart';

part 'following_list_state.dart';

final followingListNotifier = StateNotifierProvider.autoDispose<
    FollowingListNotifier, FollowingListState>(
  (ref) => FollowingListNotifier(
    FollowingListState(
      followingListModel: FollowingListModel(),
    ),
  ),
);

class FollowingListNotifier extends StateNotifier<FollowingListState> {
  final FollowsService _followsService = FollowsService();

  FollowingListNotifier(FollowingListState state) : super(state) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        print('⚠️ Supabase client not initialized');
        state = state.copyWith(isLoading: false);
        return;
      }

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final followingData = await client
          .from('follows')
          .select('following_id, user_profiles!follows_following_id_fkey(*)')
          .eq('follower_id', currentUser.id);

      final followingUsers = followingData
          .map((item) {
            final userProfile = item['user_profiles'] as Map<String, dynamic>?;
            if (userProfile == null) return null;

            final avatarUrl =
                AvatarHelperService.getAvatarUrl(userProfile['avatar_url']);
            final followerCount = userProfile['follower_count'] ?? 0;

            return FollowingUserModel(
              id: userProfile['id'] as String,
              name: userProfile['display_name'] as String? ??
                  userProfile['username'] as String,
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
    } catch (e) {
      print('Error loading following list: $e');
      state = state.copyWith(
        isLoading: false,
        followingListModel: state.followingListModel?.copyWith(
          followingUsers: [],
        ),
      );
    }
  }

  void onUserAction(FollowingUserModel? user) {
    if (user != null) {
      state = state.copyWith(
        selectedUser: user,
      );
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) return;

      // Unfollow user - no toast notification
      final success =
          await _followsService.unfollowUser(currentUser.id, userId);

      if (success) {
        await initialize();
      }
    } catch (e) {
      print('Error unfollowing user: $e');
    }
  }
}
