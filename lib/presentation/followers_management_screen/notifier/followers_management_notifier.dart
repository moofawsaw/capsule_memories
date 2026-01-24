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

      // Determine which of these followers the current user already follows back.
      final followerIds = (followersData as List)
          .map((item) => item['follower_id'] as String?)
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toList();

      Set<String> followingBackIds = {};
      if (followerIds.isNotEmpty) {
        try {
          final followBackRows = await client
              .from('follows')
              .select('following_id')
              .eq('follower_id', currentUser.id)
              .inFilter('following_id', followerIds);

          followingBackIds = (followBackRows as List)
              .map((r) => r['following_id'] as String?)
              .whereType<String>()
              .toSet();
        } catch (e) {
          // ignore: avoid_print
          print('Error checking follow-back status: $e');
        }
      }

      final followersList = followersData
          .map((item) {
            final userProfile = item['user_profiles'] as Map<String, dynamic>?;
            if (userProfile == null) return null;

            final avatarUrl =
                AvatarHelperService.getAvatarUrl(userProfile['avatar_url']);
            final followerCount = userProfile['follower_count'] ?? 0;
            final id = userProfile['id'] as String;

            return FollowerItemModel(
              id: id,
              name: userProfile['display_name'] as String? ??
                  userProfile['username'] as String,
              followersCount: '$followerCount followers',
              profileImage: avatarUrl,
              isFollowingBack: followingBackIds.contains(id),
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
        state = state.copyWith(didFollowBack: true);
        await initialize();

        // Reset success pulse
        await Future.delayed(const Duration(milliseconds: 600));
        state = state.copyWith(didFollowBack: false);
      }
    } catch (e) {
      print('Error following back: $e');
    }
  }
}
