import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/follows_service.dart';
import '../../../services/supabase_service.dart';
import '../models/followers_management_model.dart';

part 'followers_management_state.dart';

final followersManagementNotifier = StateNotifierProvider.autoDispose<
    FollowersManagementNotifier, FollowersManagementState>(
  (ref) => FollowersManagementNotifier(
    FollowersManagementState(
      followersManagementModel: FollowersManagementModel(),
    ),
  ),
);

class FollowersManagementNotifier
    extends StateNotifier<FollowersManagementState> {
  final FollowsService _followsService = FollowsService();

  FollowersManagementNotifier(FollowersManagementState state) : super(state) {
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

      // Add this block - Fetch followers using direct Supabase query
      final followersData = await client
          .from('follows')
          .select('follower_id, user_profiles!follows_follower_id_fkey(*)')
          .eq('following_id', currentUser.id);

      final followersList = followersData
          .map((item) {
            final userProfile = item['user_profiles'] as Map<String, dynamic>?;
            if (userProfile == null) return null;

            final avatarUrl =
                AvatarHelperService.getAvatarUrl(userProfile['avatar_url']);
            final followerCount = userProfile['follower_count'] ?? 0;

            return FollowerItemModel(
              id: userProfile['id'] as String,
              name: userProfile['display_name'] as String? ??
                  userProfile['username'] as String,
              followersCount: '$followerCount followers',
              profileImage: avatarUrl,
            );
          })
          .whereType<FollowerItemModel>()
          .toList();

      state = state.copyWith(
        followersManagementModel: state.followersManagementModel?.copyWith(
          followersList: followersList,
        ),
        isLoading: false,
      );
    } catch (e) {
      print('Error loading followers list: $e');
      state = state.copyWith(
        isLoading: false,
        followersManagementModel: state.followersManagementModel?.copyWith(
          followersList: [],
        ),
      );
    }
  }

  Future<void> blockFollower(int index) async {
    try {
      final followers = state.followersManagementModel?.followersList ?? [];
      if (index < 0 || index >= followers.length) return;

      // Remove follower from list (blocking functionality can be extended)
      final updatedFollowers = List<FollowerItemModel>.from(followers);
      updatedFollowers.removeAt(index);

      state = state.copyWith(
        followersManagementModel: state.followersManagementModel?.copyWith(
          followersList: updatedFollowers,
        ),
        isBlocked: true,
      );

      // Reset blocked state after a short delay
      await Future.delayed(Duration(milliseconds: 500));
      state = state.copyWith(isBlocked: false);
    } catch (e) {
      print('Error blocking follower: $e');
    }
  }

  Future<void> removeFollower(String followerId) async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) return;

      // Remove follower - no toast notification
      final success =
          await _followsService.unfollowUser(followerId, currentUser.id);

      if (success) {
        await initialize();
      }
    } catch (e) {
      print('Error removing follower: $e');
    }
  }

  Future<void> followBack(String followerId) async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) return;

      // Follow back - database trigger will create notification automatically
      final success =
          await _followsService.followUser(currentUser.id, followerId);

      if (success) {
        await initialize();
      }
    } catch (e) {
      print('Error following back: $e');
    }
  }
}