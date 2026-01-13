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

class UserProfileScreenTwoNotifier extends StateNotifier<UserProfileScreenTwoState> {
  final FollowsService _followsService = FollowsService();
  final FriendsService _friendsService = FriendsService();
  final BlockedUsersService _blockedUsersService = BlockedUsersService();
  final StoryService _storyService = StoryService();

  UserProfileScreenTwoNotifier(UserProfileScreenTwoState state) : super(state);

  // ✅ Helper: get authed user id once
  String? get _currentUserId => SupabaseService.instance.client?.auth.currentUser?.id;

  Future<void> initialize({String? userId}) async {
    try {
      state = state.copyWith(isLoading: true, targetUserId: userId);

      final currentUserId = _currentUserId;
      final isCurrentUserProfile =
          (userId == null) || (currentUserId != null && userId == currentUserId);

      final resolvedTargetUserId =
      isCurrentUserProfile ? (currentUserId ?? '') : (userId ?? '');

      Map<String, dynamic>? profile;

      // current user -> user_profiles (private, contains email)
      // other user  -> user_profiles_public (no email)
      if (isCurrentUserProfile) {
        profile = await UserProfileService.instance.getCurrentUserProfile();
      } else {
        profile = await UserProfileService.instance.getPublicUserProfileById(resolvedTargetUserId);
      }

      if (profile == null) {
        state = state.copyWith(
          userProfileScreenTwoModel: UserProfileScreenTwoModel(
            avatarImagePath: ImageConstant.imgEllipse896x96,
            userName: 'User Not Found',
            email: null, // ✅ never show email on missing profile
            followersCount: '0',
            followingCount: '0',
            storyItems: [],
          ),
          isUploading: false,
          isLoading: false,
          isLoadingStories: false,
        );
        return;
      }

      String? avatarUrl;
      final avatarPath = profile['avatar_url'];
      if (avatarPath != null && avatarPath.toString().isNotEmpty) {
        avatarUrl = await UserProfileService.instance.getAvatarUrl(avatarPath.toString());
      }

      final profileUserId = (profile['id'] as String?) ?? resolvedTargetUserId;

      // ✅ Uses public table now (per your UserProfileService updates)
      final stats = await UserProfileService.instance.getUserStats(profileUserId);

      // Only load relationship status if viewing someone else
      if (!isCurrentUserProfile && resolvedTargetUserId.isNotEmpty) {
        await _loadRelationshipStatus(resolvedTargetUserId);
      }

      state = state.copyWith(isLoadingStories: true);

      final stories = await _storyService.fetchStoriesByAuthor(profileUserId);

      final storyItems = stories.map((story) {
        final contributor =
            (story['user_profiles_public'] as Map<String, dynamic>?) ??
                (story['user_profiles'] as Map<String, dynamic>?);

        final memory = story['memories'] as Map<String, dynamic>?;
        final category = memory?['memory_categories'] as Map<String, dynamic>?;

        final categoryName = category?['name'] ?? 'Memory';
        final categoryIconUrl = category?['icon_url'] as String?;

        return StoryItemModel(
          storyId: story['id'] as String?,
          contributorId: story['contributor_id'] as String?,
          userName: contributor?['display_name'] ?? contributor?['username'] ?? 'Unknown User',
          userAvatar: AvatarHelperService.getAvatarUrl(contributor?['avatar_url']),
          backgroundImage: StoryService.resolveStoryMediaUrl(story['thumbnail_url'] as String?),
          categoryText: categoryName,
          categoryIcon: categoryIconUrl ?? ImageConstant.imgVector,
          timestamp: _storyService.getTimeAgo(
            DateTime.parse(story['created_at'] ?? DateTime.now().toIso8601String()),
          ),
        );
      }).toList();

      // ✅ current user only
      final safeEmail = isCurrentUserProfile ? (profile['email'] as String?) : null;

      state = state.copyWith(
        userProfileScreenTwoModel: UserProfileScreenTwoModel(
          avatarImagePath: avatarUrl ?? '',
          userName: profile['display_name'] ??
              profile['username'] ??
              (isCurrentUserProfile ? (safeEmail?.split('@').first) : null) ??
              'User',
          email: safeEmail, // ✅ NULL for other users
          followersCount: stats['followers'].toString(),
          followingCount: stats['following'].toString(),
          storyItems: storyItems,
        ),
        isUploading: false,
        isLoading: false,
        isLoadingStories: false,
      );
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

      final isFollowing = await _followsService.isFollowing(currentUser.id, targetUserId);
      final isFriend = await _friendsService.areFriends(currentUser.id, targetUserId);
      final hasPendingRequest = await _friendsService.hasPendingRequest(currentUser.id, targetUserId);
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

  /// ✅ NEW: Delete story from DB + remove from UI list
  Future<bool> deleteStory(String storyId) async {
    try {
      if (storyId.trim().isEmpty) return false;

      final success = await _storyService.deleteStory(storyId);
      if (!success) return false;

      final currentItems = state.userProfileScreenTwoModel?.storyItems ?? <StoryItemModel>[];
      final updatedItems = currentItems.where((item) => item.storyId != storyId).toList();

      state = state.copyWith(
        userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
          storyItems: updatedItems,
        ),
      );

      return true;
    } catch (e) {
      print('❌ Error deleting story: $e');
      return false;
    }
  }

  Future<void> toggleFollow() async {
    final targetUserId = state.targetUserId;
    if (targetUserId == null) return;

    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    if (state.isFollowing) {
      final success = await _followsService.unfollowUser(currentUser.id, targetUserId);
      if (success) {
        state = state.copyWith(isFollowing: false);
      }
    } else {
      final success = await _followsService.followUser(currentUser.id, targetUserId);
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

    final success = await _friendsService.sendFriendRequest(currentUser.id, targetUserId);
    if (success) {
      state = state.copyWith(hasPendingFriendRequest: true);
    }
  }

  Future<void> unfriendUser() async {
    final targetUserId = state.targetUserId;
    if (targetUserId == null) return;

    final currentUser = SupabaseService.instance.client?.auth.currentUser;
    if (currentUser == null) return;

    final success = await _friendsService.unfriendUser(currentUser.id, targetUserId);
    if (success) {
      state = state.copyWith(isFriend: false);
    }
  }

  Future<bool> deleteStoryFromProfile(String storyId) async {
    if (storyId.isEmpty) return false;

    // Optimistic UI removal
    final currentItems = state.userProfileScreenTwoModel?.storyItems ?? <StoryItemModel>[];
    final updatedItems = currentItems.where((s) => s.storyId != storyId).toList();

    state = state.copyWith(
      userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(storyItems: updatedItems),
    );

    final success = await _storyService.deleteStory(storyId);

    if (!success) {
      // Revert if delete failed
      state = state.copyWith(
        userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(storyItems: currentItems),
      );
    }

    return success;
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

    await _followsService.followUser(currentUser.id, targetUserId);
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

      final imageBytes = await image.readAsBytes();
      final fileName = image.name;

      final filePath = await UserProfileService.instance.uploadAvatar(imageBytes, fileName);

      if (filePath != null) {
        final success = await UserProfileService.instance.updateUserProfile(avatarUrl: filePath);

        if (success) {
          final signedUrl = await UserProfileService.instance.getAvatarUrl(filePath);

          if (signedUrl != null) {
            state = state.copyWith(
              userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
                avatarImagePath: signedUrl,
              ),
              isUploading: false,
            );
          }
        }
      }

      state = state.copyWith(isUploading: false);
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      state = state.copyWith(isUploading: false);
    }
  }

  Future<void> updateUsername(String newUsername) async {
    try {
      if (newUsername.trim().isEmpty) return;

      final trimmedUsername = newUsername.trim();

      final success = await UserProfileService.instance.updateUserProfile(displayName: trimmedUsername);

      if (success) {
        state = state.copyWith(
          userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
            userName: trimmedUsername,
          ),
        );
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
