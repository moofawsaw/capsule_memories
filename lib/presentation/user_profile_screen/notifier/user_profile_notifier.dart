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

  /// Delete a story and refresh the profile
  Future<bool> deleteStory(String storyId) async {
    try {
      print('🗑️ USER PROFILE NOTIFIER: Deleting story $storyId');

      // Call story service to delete from database
      final storyService = StoryService();
      final success = await storyService.deleteStory(storyId);

      if (success) {
        print('✅ USER PROFILE NOTIFIER: Story deleted successfully');

        // Refresh profile to update story list
        await initialize();

        return true;
      } else {
        print('❌ USER PROFILE NOTIFIER: Failed to delete story');
        return false;
      }
    } catch (e) {
      print('❌ USER PROFILE NOTIFIER: Error deleting story: $e');
      return false;
    }
  }

  /// Confirm and delete story with user dialog
  Future<void> confirmAndDeleteStory(
      BuildContext context, String storyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: appTheme.gray_900_02,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.h),
        ),
        title: Text(
          'Delete Story',
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans
              .copyWith(color: appTheme.white_A700),
        ),
        content: Text(
          'Are you sure you want to delete this story? This action cannot be undone.',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(color: appTheme.red_500),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Deleting story...'),
          backgroundColor: appTheme.deep_purple_A100,
          duration: Duration(seconds: 2),
        ),
      );

      // Delete story
      final success = await deleteStory(storyId);

      if (context.mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Story deleted successfully'
                : 'Failed to delete story'),
            backgroundColor:
                success ? appTheme.deep_purple_A100 : appTheme.red_500,
          ),
        );
      }
    }
  }

  /// Initialize profile with optional user ID for viewing other profiles
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

      // CRITICAL FIX: Always check friendship status when viewing any profile (including own)
      bool isFriend = false;
      bool isFollowing = false;

      if (currentUserId != null) {
        // Check if already friends using friends table
        isFriend =
            await _friendsService.areFriends(currentUserId, targetUserId);
        print(
            '✅ USER PROFILE: Friendship status - isFriend: $isFriend (current: $currentUserId, target: $targetUserId)');

        // Check following status
        isFollowing =
            await _followsService.isFollowing(currentUserId, targetUserId);
      }

      // CRITICAL FIX: Use fetchStoriesByAuthor to show only stories authored by this user
      final storiesData =
          await _storyService.fetchStoriesByAuthor(targetUserId);

      // Map database stories to StoryItemModel
      final storyItems = storiesData.map((story) {
        final memory = story['memories'] as Map<String, dynamic>?;
        final category = memory?['memory_categories'] as Map<String, dynamic>?;
        final contributor =
            (story['user_profiles_public'] as Map<String, dynamic>?) ??
                (story['user_profiles'] as Map<String, dynamic>?);


        // CRITICAL FIX: Resolve category icon URL from category-icons bucket
        String? categoryIconUrl;
        if (category?['icon_url'] != null) {
          final iconPath = category!['icon_url'] as String;

          // Check if already a full URL
          if (iconPath.startsWith('http://') ||
              iconPath.startsWith('https://')) {
            categoryIconUrl = iconPath;
          } else {
            // Resolve relative path from category-icons bucket
            final supabaseService = SupabaseService.instance;
            categoryIconUrl = supabaseService.getStorageUrl(
                  iconPath,
                  bucket: 'category-icons',
                ) ??
                iconPath;
          }
        }

        return StoryItemModel(
          userName: contributor?['display_name'] ?? 'Unknown User',
          userAvatar: _storyService.getContributorAvatar(story),
          backgroundImage: StoryService.resolveStoryMediaUrl(
              story['thumbnail_url'] as String?),
          categoryText: category?['name'] ?? 'Unknown',
          categoryIcon: categoryIconUrl ?? '',
          timestamp: _storyService.getTimeAgo(
            DateTime.parse(story['created_at'] as String),
          ),
        );
      }).toList();

      print(
          '✅ USER PROFILE: Loaded ${storyItems.length} stories from database');

      state = state.copyWith(
        userProfileModel: UserProfileModel(
          profileImage: '',
          userName: 'Lucy Ball',
          followersCount: '29',
          followingCount: '6',
          storyItems: storyItems,
        ),
        isFriend: isFriend,
        isFollowing: isFollowing,
        isLoading: false,
      );
    } catch (e) {
      print('❌ USER PROFILE: Error loading stories: $e');
      // Set empty list on error
      state = state.copyWith(
        userProfileModel: UserProfileModel(
          profileImage: '',
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

    // CRITICAL FIX: Check if already friends before sending request
    final alreadyFriends =
        await _friendsService.areFriends(currentUser.id, targetUserId);

    if (alreadyFriends) {
      print('❌ USER PROFILE: Cannot send friend request - already friends');
      // Update state to reflect actual friendship status
      state = state.copyWith(isFriend: true);
      return;
    }

    // Check if there's already a pending request
    final hasPending =
        await _friendsService.hasPendingRequest(currentUser.id, targetUserId);

    if (hasPending) {
      print(
          '❌ USER PROFILE: Cannot send friend request - request already pending');
      return;
    }

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
