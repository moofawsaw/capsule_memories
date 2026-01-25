import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_menu_model.dart';
import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../core/utils/theme_provider.dart';
import '../../../services/avatar_state_service.dart';
import '../../../services/memory_cache_service.dart';
import '../../../services/push_notification_service.dart';

// If you want fallback access to cached token:
// import '../../../services/push_notification_service.dart';

part 'user_menu_state.dart';

final userMenuNotifier =
StateNotifierProvider.autoDispose<UserMenuNotifier, UserMenuState>(
      (ref) => UserMenuNotifier(
    UserMenuState(
      userMenuModel: UserMenuModel(),
    ),
    ref,
  ),
);

class UserMenuNotifier extends StateNotifier<UserMenuState> {
  final Ref ref;

  UserMenuNotifier(UserMenuState state, this.ref) : super(state) {
    initialize();
  }

  void initialize() async {
    state = state.copyWith(
      isLoading: true,
    );

    await _loadUserProfile();

    state = state.copyWith(
      isLoading: false,
    );
  }

  // Load authenticated user profile from database
  Future<void> _loadUserProfile() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        print('⚠️ Supabase client not available');
        return;
      }

      // Get current authenticated user
      final user = client.auth.currentUser;
      if (user == null) {
        print('⚠️ No authenticated user');
        return;
      }

      // Fetch user profile from database - now includes auth_provider and created_at
      final response = await client
          .from('user_profiles')
          .select(
          'username, email, display_name, avatar_url, bio, auth_provider, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final isDark = ref.read(themeModeProvider) == ThemeMode.dark;

        // Pass empty string for avatar_url if null/empty to trigger letter avatar
        final avatarUrl = response['avatar_url'] as String?;
        final cleanAvatarUrl =
        (avatarUrl?.isNotEmpty ?? false) ? avatarUrl : '';

        state = state.copyWith(
          userMenuModel: UserMenuModel(
            userName: response['display_name'] ?? response['username'] ?? '',
            userEmail: response['email'] ?? '',
            avatarImagePath: cleanAvatarUrl,
            isDarkModeEnabled: isDark,
            authProvider: response['auth_provider'] as String?,
            createdAt: response['created_at'] != null
                ? DateTime.parse(response['created_at'] as String)
                : null,
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
    }
  }

  /// Ensure the local toggle matches the global theme mode.
  void syncDarkModeFromTheme() {
    final model = state.userMenuModel;
    if (model == null) return;
    final isDark = ref.read(themeModeProvider) == ThemeMode.dark;
    if ((model.isDarkModeEnabled ?? true) == isDark) return;
    state = state.copyWith(
      userMenuModel: model.copyWith(isDarkModeEnabled: isDark),
    );
  }

  void toggleDarkMode() async {
    final currentIsDark = ref.read(themeModeProvider) == ThemeMode.dark;
    final newDarkModeValue = !currentIsDark;

    // Update local state
    final updatedModel = state.userMenuModel?.copyWith(
      isDarkModeEnabled: newDarkModeValue,
    );

    state = state.copyWith(
      userMenuModel: updatedModel,
    );

    // Update global theme
    await ref.read(themeModeProvider.notifier).setThemeMode(
      newDarkModeValue ? ThemeMode.dark : ThemeMode.light,
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        // ✅ Unregister token BEFORE signOut (best effort)
        try {
          final prefs = await SharedPreferences.getInstance();
          final deviceId = prefs.getString('fcm_device_id');

          // Prefer the cached token your service already has (more reliable at logout)
          final currentFcmToken = PushNotificationService.instance.fcmToken;

          if ((deviceId != null && deviceId.isNotEmpty) ||
              (currentFcmToken != null && currentFcmToken.isNotEmpty)) {
            await client.functions.invoke(
              'unregister-fcm-token',
              body: {
                'device_id': deviceId,
                'token': currentFcmToken,
              },
            );
          }
        } catch (e) {
          print('⚠️ unregister-fcm-token failed (continuing logout): $e');
        }

        await client.auth.signOut();
      }

      // 🔥 CRITICAL: Clear all cached user data on sign out
      print('🧹 CACHE CLEAR: Starting comprehensive cache cleanup on sign out');

      ref.read(avatarStateProvider.notifier).clearAvatar();
      print('✅ CACHE CLEAR: Avatar state cleared');

      MemoryCacheService().clearCache();
      print('✅ CACHE CLEAR: Memory/story cache cleared');

      print('✅ CACHE CLEAR: All user data cache successfully cleared on sign out');

      state = state.copyWith(
        isLoading: false,
        isSignedOut: true,
      );
    } catch (e) {
      print('❌ Error signing out: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Best-effort unregister via Edge Function:
  /// await supabase.functions.invoke('unregister-fcm-token', body: { device_id, token })
  // ignore: unused_element
  Future<void> _unregisterFcmTokenBestEffort(dynamic client) async {
    try {
      // deviceId is generated/persisted in PushNotificationService under this key
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('fcm_device_id');

      // Try to fetch the current token from Firebase directly (most reliable at logout)
      String? token = await FirebaseMessaging.instance.getToken();

      // Optional fallback if you prefer using your service cache:
      // token ??= PushNotificationService.instance.fcmToken;

      if (deviceId == null ||
          deviceId.isEmpty ||
          token == null ||
          token.isEmpty) {
        print(
            '⚠️ Skipping unregister-fcm-token (missing deviceId or token). deviceId=$deviceId token=${token != null ? "present" : "null"}');
        return;
      }

      await client.functions.invoke(
        'unregister-fcm-token',
        body: {
          'device_id': deviceId,
          'token': token,
        },
      );

      print('✅ unregister-fcm-token invoked successfully');
    } catch (e) {
      // Never block logout
      print('⚠️ unregister-fcm-token failed (continuing logout): $e');
    }
  }

  // ignore: unused_element
  void _clearUserCaches() {
    // 🔥 CRITICAL: Clear all cached user data on sign out
    // This prevents previous user data from displaying for new login
    print('🧹 CACHE CLEAR: Starting comprehensive cache cleanup on sign out');

    // Clear avatar state (profile pictures, user info)
    ref.read(avatarStateProvider.notifier).clearAvatar();
    print('✅ CACHE CLEAR: Avatar state cleared');

    // Clear memory and story caches
    MemoryCacheService().clearCache();
    print('✅ CACHE CLEAR: Memory/story cache cleared');

    print('✅ CACHE CLEAR: All user data cache successfully cleared on sign out');
  }

  Future<void> updateUserProfile(
      String userName, String userEmail, String? avatarPath) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final user = client.auth.currentUser;
      if (user == null) return;

      // Update profile in database
      await client.from('user_profiles').update({
        'display_name': userName,
        'email': userEmail,
        'avatar_url': avatarPath,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Update local state
      final currentModel = state.userMenuModel;
      final updatedModel = currentModel?.copyWith(
        userName: userName,
        userEmail: userEmail,
        avatarImagePath: avatarPath,
      );

      state = state.copyWith(
        userMenuModel: updatedModel,
      );
    } catch (e) {
      print('❌ Error updating user profile: $e');
    }
  }

  // Refresh user profile data
  Future<void> refreshProfile() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final user = client.auth.currentUser;
      if (user == null) return;

      final response = await client
          .from('user_profiles')
          .select('display_name, email, avatar_url, auth_provider, created_at')
          .eq('id', user.id)
          .single();

      state = state.copyWith(
        userMenuModel: UserMenuModel(
          userName: response['display_name'] as String?,
          userEmail: response['email'] as String?,
          avatarImagePath: response['avatar_url'] as String?,
          isDarkModeEnabled: state.userMenuModel?.isDarkModeEnabled,
          authProvider: response['auth_provider'] as String?,
          createdAt: response['created_at'] != null
              ? DateTime.parse(response['created_at'] as String)
              : null,
        ),
      );
    } catch (e) {
      debugPrint('Error refreshing profile: $e');
    }
  }
}
