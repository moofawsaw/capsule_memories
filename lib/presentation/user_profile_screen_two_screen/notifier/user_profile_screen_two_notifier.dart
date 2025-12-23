import 'package:image_picker/image_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/blocked_users_service.dart';
import '../../../services/follows_service.dart';
import '../../../services/friends_service.dart';
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

        final storyItems = [
          StoryItemModel(
            userName: 'Kelly Jones',
            userAvatar: ImageConstant.imgFrame2,
            backgroundImage: ImageConstant.imgImg,
            categoryText: 'Vacation',
            categoryIcon: ImageConstant.imgVector,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            userName: 'Mac Hollins',
            userAvatar: ImageConstant.imgEllipse826x26,
            backgroundImage: ImageConstant.imgImage8,
            categoryText: 'Vacation',
            categoryIcon: ImageConstant.imgVector,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            userName: 'Beth Way',
            userAvatar: ImageConstant.imgFrame48x48,
            backgroundImage: ImageConstant.imgImage8202x116,
            categoryText: 'Vacation',
            categoryIcon: ImageConstant.imgVector,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            userName: 'Elliott Freisen',
            userAvatar: ImageConstant.imgEllipse81,
            backgroundImage: ImageConstant.imgImage81,
            categoryText: 'Vacation',
            categoryIcon: ImageConstant.imgVector,
            timestamp: '2 mins ago',
          ),
        ];

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
        );
      } else {
        // User not found or not authenticated - show placeholder data
        final storyItems = [
          StoryItemModel(
            userName: 'Kelly Jones',
            userAvatar: ImageConstant.imgFrame2,
            backgroundImage: ImageConstant.imgImg,
            categoryText: 'Vacation',
            categoryIcon: ImageConstant.imgVector,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            userName: 'Mac Hollins',
            userAvatar: ImageConstant.imgEllipse826x26,
            backgroundImage: ImageConstant.imgImage8,
            categoryText: 'Vacation',
            categoryIcon: ImageConstant.imgVector,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            userName: 'Beth Way',
            userAvatar: ImageConstant.imgFrame48x48,
            backgroundImage: ImageConstant.imgImage8202x116,
            categoryText: 'Vacation',
            categoryIcon: ImageConstant.imgVector,
            timestamp: '2 mins ago',
          ),
          StoryItemModel(
            userName: 'Elliott Freisen',
            userAvatar: ImageConstant.imgEllipse81,
            backgroundImage: ImageConstant.imgImage81,
            categoryText: 'Vacation',
            categoryIcon: ImageConstant.imgVector,
            timestamp: '2 mins ago',
          ),
        ];

        state = state.copyWith(
          userProfileScreenTwoModel: UserProfileScreenTwoModel(
            avatarImagePath: ImageConstant.imgEllipse896x96,
            userName: 'User Not Found',
            email: userId != null
                ? 'Unable to load user data'
                : 'Please login to see your profile',
            followersCount: '0',
            followingCount: '0',
            storyItems: storyItems,
          ),
          isUploading: false,
          isLoading: false,
        );
      }
    } catch (e) {
      print('❌ Error initializing profile: $e');
      // On error, show placeholder with error message
      state = state.copyWith(
        userProfileScreenTwoModel: UserProfileScreenTwoModel(
          avatarImagePath: ImageConstant.imgEllipse896x96,
          userName: 'Error Loading Profile',
          email: 'Please try again',
          followersCount: '0',
          followingCount: '0',
          storyItems: [],
        ),
        isUploading: false,
        isLoading: false,
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

            // 🔥 CRITICAL: Broadcast avatar update to all widgets across the app
            // Remove ref.read - ref is not available in this context
            // final avatarNotifier = ref.read(avatarStateProvider.notifier);
            // avatarNotifier.updateAvatar(
            //   signedUrl,
            //   userEmail: state.userProfileScreenTwoModel?.email,
            // );

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
