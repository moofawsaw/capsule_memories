import 'package:image_picker/image_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/avatar_state_service.dart';
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
    ref,
  ),
);

class UserProfileScreenTwoNotifier
    extends StateNotifier<UserProfileScreenTwoState> {
  final Ref ref;

  UserProfileScreenTwoNotifier(UserProfileScreenTwoState state, this.ref)
      : super(state);

  Future<void> initialize() async {
    try {
      // Add loading state
      state = state.copyWith(isLoading: true);

      // Fetch real user data from database
      final profile = await UserProfileService.instance.getCurrentUserProfile();

      if (profile != null) {
        // Get signed URL for avatar if it exists
        String? avatarUrl;
        if (profile['avatar_url'] != null &&
            profile['avatar_url'].toString().isNotEmpty) {
          avatarUrl = await UserProfileService.instance
              .getAvatarUrl(profile['avatar_url']);
        }

        // Fetch actual user stats instead of using profile fields
        final userId = profile['id'] as String;
        final stats = await UserProfileService.instance.getUserStats(userId);

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
            // Pass empty string if no avatar - widget will show letter avatar fallback
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
        // User not authenticated - show placeholder data with message
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
            userName: 'Preview User',
            email: 'Please login to see your profile',
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
            final avatarNotifier = ref.read(avatarStateProvider.notifier);
            avatarNotifier.updateAvatar(
              signedUrl,
              userEmail: state.userProfileScreenTwoModel?.email,
            );

            print(
                '✅ Avatar updated successfully and broadcasted to all widgets');
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
