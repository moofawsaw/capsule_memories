import 'package:flutter_riverpod/flutter_riverpod.dart';
import './user_profile_service.dart';
import './supabase_service.dart';

/// Global avatar state notifier that broadcasts avatar changes across the app
/// All widgets displaying user avatars should listen to this provider
class AvatarState {
  final String? avatarUrl;
  final String? userEmail;
  final bool isLoading;
  final String? userId;

  AvatarState({
    this.avatarUrl,
    this.userEmail,
    this.isLoading = false,
    this.userId,
  });

  AvatarState copyWith({
    String? avatarUrl,
    String? userEmail,
    bool? isLoading,
    String? userId,
  }) {
    return AvatarState(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
    );
  }
}

class AvatarStateNotifier extends StateNotifier<AvatarState> {
  AvatarStateNotifier() : super(AvatarState());

  /// Load current user's avatar from database
  /// 🎯 HANDLES BOTH GOOGLE OAUTH URLS AND SUPABASE STORAGE KEYS
  /// - Google OAuth URLs (start with http/https) are used directly
  /// - Supabase Storage keys (like userId/file.png) are converted to signed URLs
  Future<void> loadCurrentUserAvatar() async {
    state = state.copyWith(isLoading: true);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        state = AvatarState(isLoading: false);
        return;
      }

      final user = client.auth.currentUser;
      if (user == null) {
        state = AvatarState(isLoading: false);
        return;
      }

      final userProfile =
          await UserProfileService.instance.getCurrentUserProfile();

      if (userProfile != null) {
        final avatarStoragePath = userProfile['avatar_url'] as String?;
        String? displayReadyUrl;

        if (avatarStoragePath != null && avatarStoragePath.isNotEmpty) {
          // 🎯 CRITICAL: Check if avatar_url is already a full URL (Google OAuth)
          if (avatarStoragePath.startsWith('http://') ||
              avatarStoragePath.startsWith('https://')) {
            // ✅ Google OAuth URL - use directly
            displayReadyUrl = avatarStoragePath;
            print('✅ Using Google OAuth avatar URL directly');
          } else {
            // ✅ Supabase Storage key - convert to signed URL
            displayReadyUrl = await UserProfileService.instance
                .getAvatarUrl(avatarStoragePath);
            print('✅ Converted Supabase Storage key to signed URL');
          }
        }

        state = AvatarState(
          avatarUrl: displayReadyUrl,
          userEmail: userProfile['email'] as String?,
          isLoading: false,
          userId: user.id,
        );

        print(
            '✅ Avatar loaded and cached: ${displayReadyUrl != null ? "URL available" : "No avatar"}');
      } else {
        state = AvatarState(isLoading: false);
      }
    } catch (e) {
      print('❌ Error loading avatar: $e');
      state = AvatarState(isLoading: false);
    }
  }

  /// Update avatar URL after successful upload
  /// This will trigger all listening widgets to refresh
  void updateAvatar(String newAvatarUrl, {String? userEmail}) {
    state = state.copyWith(
      avatarUrl: newAvatarUrl,
      userEmail: userEmail ?? state.userEmail,
      isLoading: false,
    );
    print('✅ Avatar updated in cache');
  }

  /// Clear avatar state on logout
  void clearAvatar() {
    state = AvatarState();
    print('✅ Avatar cache cleared');
  }

  /// Refresh avatar from database - ONLY call this after user updates avatar in /profile
  Future<void> refreshAvatar() async {
    print('🔄 Force refreshing avatar from database...');
    // Clear current state to force reload
    state = AvatarState();
    await loadCurrentUserAvatar();
  }
}

/// Global avatar state provider
/// Use this in any widget that displays user avatars
final avatarStateProvider =
    StateNotifierProvider<AvatarStateNotifier, AvatarState>(
  (ref) => AvatarStateNotifier(),
);
