import '../../../core/app_export.dart';
import '../../../services/follows_service.dart';
import '../../../services/friends_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../models/story_item_model.dart';
import '../models/user_profile_model.dart';

part 'user_profile_state.dart';

final userProfileNotifier =
    StateNotifierProvider.autoDispose<UserProfileNotifier, UserProfileState>(
  (ref) => UserProfileNotifier(
    UserProfileState(
      userProfileModel: UserProfileModel(),
    ),
  ),
);

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final FollowsService _followsService = FollowsService();
  final StoryService _storyService = StoryService();
  final FriendsService _friendsService = FriendsService();

  UserProfileNotifier(UserProfileState state) : super(state) {
    initialize();
  }

  Future<void> initialize({String? userId}) async {
    // Set loading state
    state = state.copyWith(isLoading: true);

    try {
      final currentUserId =
          SupabaseService.instance.client?.auth.currentUser?.id;

      // Use current user's ID if not provided
      final targetUserId = userId ?? currentUserId;

      if (targetUserId == null) {
        print('❌ USER PROFILE: No user ID available');
        state = state.copyWith(isLoading: false);
        return;
      }

      print('🔍 USER PROFILE: Fetching stories for user: $targetUserId');

      // Check friendship status if viewing another user's profile
      bool isFriend = false;
      if (currentUserId != null && targetUserId != currentUserId) {
        isFriend =
            await _friendsService.areFriends(currentUserId, targetUserId);
        print(
            '✅ USER PROFILE: Friendship status checked - isFriend: $isFriend');
      }

      // Fetch real stories from database using StoryService
      final storiesData = await _storyService.fetchUserStories(targetUserId);

      // Map database stories to StoryItemModel
      final storyItems = storiesData.map((story) {
        final memory = story['memories'] as Map<String, dynamic>?;
        final category = memory?['memory_categories'] as Map<String, dynamic>?;
        final contributor = story['user_profiles'] as Map<String, dynamic>?;

        return StoryItemModel(
          userName: contributor?['display_name'] ?? 'Unknown User',
          userAvatar: _storyService.getContributorAvatar(story),
          backgroundImage: _storyService.getStoryMediaUrl(story),
          categoryText: category?['name'] ?? 'Unknown',
          categoryIcon: category?['icon_url'] ?? '',
          timestamp: _storyService.getTimeAgo(
            DateTime.parse(story['created_at'] as String),
          ),
        );
      }).toList();

      print(
          '✅ USER PROFILE: Loaded ${storyItems.length} stories from database');

      state = state.copyWith(
        userProfileModel: UserProfileModel(
          profileImage: ImageConstant.imgEllipse864x64,
          userName: 'Lucy Ball',
          followersCount: '29',
          followingCount: '6',
          storyItems: storyItems,
        ),
        isFriend: isFriend,
        isLoading: false,
      );
    } catch (e) {
      print('❌ USER PROFILE: Error loading stories: $e');
      // Set empty list on error
      state = state.copyWith(
        userProfileModel: UserProfileModel(
          profileImage: ImageConstant.imgEllipse864x64,
          userName: 'Lucy Ball',
          followersCount: '29',
          followingCount: '6',
          storyItems: [],
        ),
        isLoading: false,
      );
    }
  }

  Future<void> onFollowButtonPressed(String targetUserId) async {
    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    final currentlyFollowing = state.isFollowing ?? false;

    if (currentlyFollowing) {
      // Unfollow user - no toast notification
      final success =
          await _followsService.unfollowUser(currentUser.id, targetUserId);
      if (success) {
        state = state.copyWith(isFollowing: false);
      }
    } else {
      // Follow user - database trigger will create notification automatically
      final success =
          await _followsService.followUser(currentUser.id, targetUserId);
      if (success) {
        state = state.copyWith(isFollowing: true);
      }
    }
  }

  Future<void> onAddFriendButtonPressed(String targetUserId) async {
    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    // Send friend request
    final success =
        await _friendsService.sendFriendRequest(currentUser.id, targetUserId);

    if (success) {
      print('✅ USER PROFILE: Friend request sent successfully');
    }
  }

  Future<bool> onRemoveFriendButtonPressed(String targetUserId) async {
    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return false;

    // Remove friend
    final success =
        await _friendsService.unfriendUser(currentUser.id, targetUserId);

    if (success) {
      state = state.copyWith(isFriend: false);
      print('✅ USER PROFILE: Friend removed successfully');
      return true;
    }

    return false;
  }

  void onBlockButtonPressed() {
    state = state.copyWith(
      isBlocked: !(state.isBlocked ?? false),
    );
  }
}
