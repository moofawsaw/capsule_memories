// lib/presentation/user_profile_screen_two/notifier/user_profile_screen_two_notifier.dart

import 'package:image_picker/image_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/avatar_helper_service.dart';
import '../../../services/avatar_state_service.dart';
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
    ref,
    UserProfileScreenTwoState(
      userProfileScreenTwoModel: UserProfileScreenTwoModel(),
    ),
  ),
);

class UserProfileScreenTwoNotifier extends StateNotifier<UserProfileScreenTwoState> {
  UserProfileScreenTwoNotifier(this.ref, UserProfileScreenTwoState state) : super(state);

  final Ref ref;

  final FollowsService _followsService = FollowsService();
  final FriendsService _friendsService = FriendsService();
  final BlockedUsersService _blockedUsersService = BlockedUsersService();
  final StoryService _storyService = StoryService();

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

      if (isCurrentUserProfile) {
        profile = await UserProfileService.instance.getCurrentUserProfile();
      } else {
        profile = await UserProfileService.instance.getPublicUserProfileById(resolvedTargetUserId);
      }

      if (profile == null) {
        state = state.copyWith(
          userProfileScreenTwoModel: UserProfileScreenTwoModel(
            avatarImagePath: ImageConstant.imgEllipse896x96,
            displayName: 'User Not Found',
            username: '',
            email: null,
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

      final stats = await UserProfileService.instance.getUserStats(profileUserId);

      if (!isCurrentUserProfile && resolvedTargetUserId.isNotEmpty) {
        await _loadRelationshipStatus(resolvedTargetUserId);
      } else {
        // ensure relationship flags are neutral for self profile
        state = state.copyWith(
          isFollowing: false,
          isFriend: false,
          hasPendingFriendRequest: false,
          isBlocked: false,
        );
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

      final safeEmail = isCurrentUserProfile ? (profile['email'] as String?) : null;

      final rawDisplayName =
      (profile['display_name'] ?? profile['displayName'])?.toString().trim();
      final rawUsername =
      (profile['username'] ?? profile['user_name'] ?? profile['handle'])?.toString().trim();

      state = state.copyWith(
        userProfileScreenTwoModel: UserProfileScreenTwoModel(
          avatarImagePath: avatarUrl ?? '',
          displayName: (rawDisplayName != null && rawDisplayName.isNotEmpty) ? rawDisplayName : 'User',
          username: (rawUsername != null && rawUsername.isNotEmpty)
              ? rawUsername
              : (isCurrentUserProfile ? (safeEmail?.split('@').first ?? '') : ''),
          email: safeEmail,
          followersCount: stats['followers'].toString(),
          followingCount: stats['following'].toString(),
          storyItems: storyItems,
        ),
        isUploading: false,
        isLoading: false,
        isLoadingStories: false,

        // reset save indicators on fresh load
        isSavingDisplayName: false,
        isSavingUsername: false,
        displayNameSavedPulse: false,
        usernameSavedPulse: false,
      );
    } catch (e) {
      print('❌ ERROR initializing user profile: $e');
      state = state.copyWith(
        isLoading: false,
        isLoadingStories: false,
      );
    }
  }

  // ✅ Display Name: saving spinner + pulse checkmark
  Future<void> updateDisplayName(String newDisplayName) async {
    try {
      final trimmed = newDisplayName.trim();
      if (trimmed.isEmpty) return;

      final currentUser = SupabaseService.instance.client?.auth.currentUser;
      if (currentUser == null) return;

      // only allow on current-user profile
      final isCurrentUserProfile =
          state.targetUserId == null || state.targetUserId == currentUser.id;
      if (!isCurrentUserProfile) return;

      if (state.isSavingDisplayName) return;

      // avoid redundant save
      final current =
      (state.userProfileScreenTwoModel?.displayName ?? '').trim();
      if (current == trimmed) return;

      state = state.copyWith(
        isSavingDisplayName: true,
        displayNameSavedPulse: false,
      );

      final success =
      await UserProfileService.instance.updateUserProfile(displayName: trimmed);

      if (!success) {
        state = state.copyWith(isSavingDisplayName: false);
        return;
      }

      state = state.copyWith(
        userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
          displayName: trimmed,
        ),
        isSavingDisplayName: false,
        displayNameSavedPulse: true,
      );

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        state = state.copyWith(displayNameSavedPulse: false);
      });
    } catch (e) {
      print('❌ Error updating display name: $e');
      state = state.copyWith(isSavingDisplayName: false);
    }
  }
  String _normalizeUsername(String input) {
    final t = input.trim();
    final noAt = t.startsWith('@') ? t.substring(1) : t;
    // simple normalization: lowercase + remove spaces
    return noAt.trim().toLowerCase();
  }

  Future<bool> _isUsernameTaken(String normalizedUsername) async {
    final client = SupabaseService.instance.client;
    if (client == null) return false;

    final currentUser = client.auth.currentUser;
    if (currentUser == null) return false;

    // Look for ANY other user with same username (case-insensitive)
    // NOTE: This assumes you store usernames lowercase OR you created a lower(username) unique index.
    final res = await client
        .from('user_profiles')
        .select('id')
        .ilike('username', normalizedUsername)
        .neq('id', currentUser.id)
        .limit(1);

    return (res is List) && res.isNotEmpty;
  }

  bool _isValidUsername(String u) {
    // 3–20 chars, lowercase letters/numbers/underscore/dot
    return RegExp(r'^[a-z0-9_.]{3,20}$').hasMatch(u);
  }

  Future<void> updateUsername(String newUsername) async {
    try {
      final client = SupabaseService.instance.client;
      final currentUser = client?.auth.currentUser;
      if (client == null || currentUser == null) return;

      // only current user can update
      final isCurrentUserProfile =
          state.targetUserId == null || state.targetUserId == currentUser.id;
      if (!isCurrentUserProfile) return;

      if (state.isSavingUsername) return;

      final normalized = _normalizeUsername(newUsername);

      // ✅ clear previous pulses + errors immediately
      state = state.copyWith(
        usernameSavedPulse: false,
        usernameError: null,
      );

      if (normalized.isEmpty) {
        state = state.copyWith(usernameError: 'Username cannot be empty');
        return;
      }

      if (!_isValidUsername(normalized)) {
        state = state.copyWith(
          usernameError: 'Use 3–20 chars: a-z, 0-9, _ or .',
        );
        return;
      }

      final current = _normalizeUsername(state.userProfileScreenTwoModel?.username ?? '');
      if (current == normalized) return;

      state = state.copyWith(isSavingUsername: true);

      // ✅ pre-check: taken?
      final taken = await _isUsernameTaken(normalized);
      if (taken) {
        state = state.copyWith(
          isSavingUsername: false,
          usernameError: 'That username is already taken',
        );
        return;
      }

      // ✅ update DB
      await client
          .from('user_profiles')
          .update({'username': normalized})
          .eq('id', currentUser.id);

      // ✅ update local model + success pulse
      state = state.copyWith(
        userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
          username: normalized,
        ),
        isSavingUsername: false,
        usernameSavedPulse: true,
        usernameError: null,
      );

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        state = state.copyWith(usernameSavedPulse: false);
      });
    } catch (e) {
      print('❌ Error updating username: $e');
      state = state.copyWith(
        isSavingUsername: false,
        usernameError: 'Could not update username. Try again.',
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

  Future<bool> deleteStory(String storyId) async {
    try {
      if (storyId.trim().isEmpty) return false;

      final success = await _storyService.deleteStory(storyId);
      if (!success) return false;

      final currentItems =
          state.userProfileScreenTwoModel?.storyItems ?? <StoryItemModel>[];
      final updatedItems =
      currentItems.where((item) => item.storyId != storyId).toList();

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

  Future<bool> deleteStoryFromProfile(String storyId) async {
    if (storyId.isEmpty) return false;

    final currentItems =
        state.userProfileScreenTwoModel?.storyItems ?? <StoryItemModel>[];
    final updatedItems =
    currentItems.where((s) => s.storyId != storyId).toList();

    state = state.copyWith(
      userProfileScreenTwoModel:
      state.userProfileScreenTwoModel?.copyWith(storyItems: updatedItems),
    );

    final success = await _storyService.deleteStory(storyId);

    if (!success) {
      state = state.copyWith(
        userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
          storyItems: currentItems,
        ),
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

      final filePath =
      await UserProfileService.instance.uploadAvatar(imageBytes, fileName);

      if (filePath == null) {
        state = state.copyWith(isUploading: false);
        return;
      }

      final success =
      await UserProfileService.instance.updateUserProfile(avatarUrl: filePath);

      if (!success) {
        state = state.copyWith(isUploading: false);
        return;
      }

      final signedUrl = await UserProfileService.instance.getAvatarUrl(filePath);

      if (signedUrl != null && signedUrl.isNotEmpty) {
        state = state.copyWith(
          userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
            avatarImagePath: signedUrl,
          ),
        );

        // keeps existing “menu updates in real time” behavior for avatar
        ref.read(avatarStateProvider.notifier).updateAvatar(signedUrl);
      }

      state = state.copyWith(isUploading: false);
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      state = state.copyWith(isUploading: false);
    }
  }

  void updateProfile(String username, String email) {
    state = state.copyWith(
      userProfileScreenTwoModel: state.userProfileScreenTwoModel?.copyWith(
        username: username,
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
