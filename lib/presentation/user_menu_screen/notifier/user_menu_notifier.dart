import '../models/user_menu_model.dart';
import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../core/utils/theme_provider.dart';

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

      // Fetch user profile from database
      final response = await client
          .from('user_profiles')
          .select('username, email, display_name, avatar_url, bio')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        // Pass empty string for avatar_url if null/empty to trigger letter avatar
        final avatarUrl = response['avatar_url'] as String?;
        final cleanAvatarUrl =
            (avatarUrl?.isNotEmpty ?? false) ? avatarUrl : '';

        state = state.copyWith(
          userMenuModel: UserMenuModel(
            userName: response['display_name'] ?? response['username'] ?? '',
            userEmail: response['email'] ?? '',
            avatarImagePath: cleanAvatarUrl,
            bio: response['bio'],
            userId: user.id,
            isDarkModeEnabled: state.userMenuModel?.isDarkModeEnabled ?? true,
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
    }
  }

  void toggleDarkMode() async {
    final currentModel = state.userMenuModel;
    final newDarkModeValue = !(currentModel?.isDarkModeEnabled ?? true);

    // Update local state
    final updatedModel = currentModel?.copyWith(
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
    state = state.copyWith(
      isLoading: true,
    );

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.auth.signOut();
      }

      state = state.copyWith(
        isLoading: false,
        isSignedOut: true,
      );
    } catch (e) {
      print('❌ Error signing out: $e');
      state = state.copyWith(
        isLoading: false,
      );
    }
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
    await _loadUserProfile();
  }
}
