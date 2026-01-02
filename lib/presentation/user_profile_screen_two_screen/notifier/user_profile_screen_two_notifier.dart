import 'package:image_picker/image_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/blocked_users_service.dart';
import '../../../services/follows_service.dart';
import '../../../services/friends_service.dart';
import '../../../services/story_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/user_profile_service.dart';
import '../models/story_item_model.dart';
import '../models/user_profile_screen_two_model.dart';

part 'user_profile_screen_two_state.dart';

final userProfileScreenTwoNotifier = StateNotifierProvider.autoDispose<
    UserProfileScreenTwoNotifier, UserProfileScreenTwoState>(
  (ref) => UserProfileScreenTwoNotifier(
    UserProfileScreenTwoState(
      userProfileScreenTwoModel: UserProfileScreenTwoModel(),
    ),
  ),
);

class UserProfileScreenTwoNotifier
    extends StateNotifier<UserProfileScreenTwoState> {
  final FollowsService _followsService = FollowsService();
  final FriendsService _friendsService = FriendsService();
  final BlockedUsersService _blockedUsersService = BlockedUsersService();
  final StoryService _storyService = StoryService();

  UserProfileScreenTwoNotifier(UserProfileScreenTwoState state) : super(state);

  Future<void> initialize({String? userId}) async {
    try {
      state = state.copyWith(isLoading: true, targetUserId: userId);

      Map<String, dynamic>? profile;

      if (userId != null) {
        profile = await UserProfileService.instance.getUserProfileById(userId);
      } else {
        profile = await UserProfileService.instance.getCurrentUserProfile();
      }

      if (profile != null) {
        String? avatarUrl;
        if (profile['avatar_url'] != null &&
            profile['avatar_url'].toString().isNotEmpty) {
          avatarUrl = await UserProfileService.instance
              .getAvatarUrl(profile['avatar_url']);
        }

        final profileUserId = profile['id'] as String;
        final stats =
            await UserProfileService.instance.getUserStats(profileUserId);

        // Check relationship status if viewing another user's profile
        if (userId != null) {
          await _loadRelationshipStatus(userId);
        }

        // Set stories loading state before fetching
        state = state.copyWith(isLoadingStories: true);

        // CRITICAL FIX: Use fetchStoriesByAuthor to get only stories created by this user from public memories
        // This replaces fetchUserStories which returned stories from ALL memories where user is a contributor
        final stories = await _storyService.fetchStoriesByAuthor(
          userId ?? SupabaseService.instance.client?.auth.currentUser?.id ?? '',
        );

        // Transform database stories into StoryItemModel instances with ACTUAL category data
        final storyItems = stories.map((story) {
          final contributor = story['user_profiles'] as Map<String, dynamic>?;
          final memory = story['memories'] as Map<String, dynamic>?;
          final category =
              memory?['memory_categories'] as Map<String, dynamic>?;

          // Extract actual category information from database
          final categoryName = category?['name'] ?? 'Memory';
          final categoryIconUrl = category?['icon_url'] as String?;

          return StoryItemModel(
            storyId: story['id'] as String?,
            userName: contributor?['display_name'] ??
                contributor?['username'] ??
                'Unknown User',
            userAvatar: AvatarHelperService.getAvatarUrl(
              contributor?['avatar_url'],
            ),
            backgroundImage: _storyService.getStoryMediaUrl(story),
            categoryText:
                categoryName, // Use actual category name from database
            categoryIcon: categoryIconUrl ??
                ImageConstant.imgVector, // Use actual category icon URL
            timestamp: _storyService.getTimeAgo(
              DateTime.parse(
                  story['created_at'] ?? DateTime.now().toIso8601String()),
            ),
          );
        }).toList();

        state = state.copyWith(
          userProfileScreenTwoModel: UserProfileScreenTwoModel(
            avatarImagePath: avatarUrl ?? '',
            userName: profile['display_name'] ??
                profile['username'] ??
                profile['email']?.split('@')[0] ??
                'User',
            email: profile['email'] ?? '',
            followersCount: stats['followers'].toString(),
            followingCount: stats['following'].toString(),
            storyItems: storyItems,
          ),
          isUploading: false,
          isLoading: false,
          isLoadingStories: false,
        );
      } else {
        // User not found or not authenticated - show empty state
        state = state.copyWith(
          userProfileScreenTwoModel: UserProfileScreenTwoModel(
            avatarImagePath: ImageConstant.imgEllipse896x96,
            userName: 'User Not Found',
            email: userId != null
                ? 'Unable to load user data'
                : 'Please login to see your profile',
            followersCount: '0',
            followingCount: '0',
            storyItems: [],
          ),
          isUploading: false,
          isLoading: false,
          isLoadingStories: false,
        );
      }
    } catch (e) {
      print('❌ ERROR initializing user profile: $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingStories: false,
      );
    }
  }

  Future<void> _loadRelationshipStatus(String targetUserId) async {
    try {
      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) return;

      final isFollowing =
          await _followsService.isFollowing(currentUser.id, targetUserId);

      final isFriend =
          await _friendsService.areFriends(currentUser.id, targetUserId);

      final hasPendingRequest =
          await _friendsService.hasPendingRequest(currentUser.id, targetUserId);

      final isBlocked = await _blockedUsersService.isUserBlocked(targetUserId);

      state = state.copyWith(
        isFollowing: isFollowing,
        isFriend: isFriend,
        hasPendingFriendRequest: hasPendingRequest,
        isBlocked: isBlocked,
      );
    } catch (e) {
      debugPrint('Error loading relationship status: $e');
    }
  }

  Future<void> toggleFollow() async {
    final targetUserId = state.targetUserId;
    if (targetUserId == null) return;

    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    if (state.isFollowing) {
      final success =
          await _followsService.unfollowUser(currentUser.id, targetUserId);
      if (success) {
        state = state.copyWith(isFollowing: false);
      }
    } else {
      final success =
          await _followsService.followUser(currentUser.id, targetUserId);
      if (success) {
        state = state.copyWith(isFollowing: true);
      }
    }
  }

  Future<void> sendFriendRequest() async {
    final targetUserId = state.targetUserId;
    if (targetUserId == null) return;

    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    final success =
        await _friendsService.sendFriendRequest(currentUser.id, targetUserId);
    if (success) {
      state = state.copyWith(hasPendingFriendRequest: true);
    }
  }

  /// Unfriends the target user
  Future<void> unfriendUser() async {
    final targetUserId = state.targetUserId;
    if (targetUserId == null) return;

    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    final success =
        await _friendsService.unfriendUser(currentUser.id, targetUserId);
    if (success) {
      state = state.copyWith(isFriend: false);
    }
  }

  Future<void> toggleBlock() async {
    final targetUserId = state.targetUserId;
    if (targetUserId == null) return;

    if (state.isBlocked) {
      final success = await _blockedUsersService.unblockUser(targetUserId);
      if (success) {
        state = state.copyWith(isBlocked: false);
      }
    } else {
      final success = await _blockedUsersService.blockUser(targetUserId);
      if (success) {
        state = state.copyWith(
          isBlocked: true,
          isFollowing: false,
          isFriend: false,
          hasPendingFriendRequest: false,
        );
      }
    }
  }

  Future<void> onFollowButtonPressed(String targetUserId) async {
    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    // Follow user - database trigger will create notification automatically
    final success =
        await _followsService.followUser(currentUser.id, targetUserId);
    // Note: isFollowing property is not available in UserProfileScreenTwoState
  }

  Future<void> uploadAvatar() async {
    try {
      state = state.copyWith(isUploading: true);

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        state = state.copyWith(isUploading: false);
        return;
      }

      // Read image bytes - works on both web and mobile
      final imageBytes = await image.readAsBytes();
      final fileName = image.name;

      // Upload to Supabase Storage using bytes
      final filePath = await UserProfileService.instance.uploadAvatar(
        imageBytes,
        fileName,
      );

      if (filePath != null) {
        // Update user profile in database
        final success = await UserProfileService.instance.updateUserProfile(
          avatarUrl: filePath,
        );

        if (success) {
          // Get signed URL for immediate display
          final signedUrl =
              await UserProfileService.instance.getAvatarUrl(filePath);

          if (signedUrl != null) {
            // Update local state
            state = state.copyWith(
              userProfileScreenTwoModel:
                  state.userProfileScreenTwoModel?.copyWith(
                avatarImagePath: signedUrl,
              ),
              isUploading: false,
            );

            print('✅ Avatar updated successfully');
          }
        }
      }

      state = state.copyWith(isUploading: false);
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      state = state.copyWith(isUploading: false);
    }
  }

  /// Update username in Supabase and local state
  Future<void> updateUsername(String newUsername) async {
    try {
      // Validate username
      if (newUsername.trim().isEmpty) {
        print('⚠️ Username cannot be empty');
        return;
      }

      final trimmedUsername = newUsername.trim();

      // Update in database
      final success = await UserProfileService.instance.updateUserProfile(
        displayName: trimmedUsername,
      );

      if (success) {
        // Update local state
        state = state.copyWith(
          userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
            userName: trimmedUsername,
          ),
        );

        print('✅ Username updated successfully to: $trimmedUsername');
      } else {
        print('❌ Failed to update username in database');
      }
    } catch (e) {
      print('❌ Error updating username: $e');
    }
  }

  void updateProfile(String userName, String email) {
    state = state.copyWith(
      userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
        userName: userName,
        email: email,
      ),
    );
  }

  void updateStats(String followersCount, String followingCount) {
    state = state.copyWith(
      userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
        followersCount: followersCount,
        followingCount: followingCount,
      ),
    );
  }
}
