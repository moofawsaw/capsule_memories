import '../models/user_menu_model.dart';
import '../../../core/app_export.dart';

part 'user_menu_state.dart';

final userMenuNotifier =
    StateNotifierProvider.autoDispose<UserMenuNotifier, UserMenuState>(
  (ref) => UserMenuNotifier(
    UserMenuState(
      userMenuModel: UserMenuModel(),
    ),
  ),
);

class UserMenuNotifier extends StateNotifier<UserMenuState> {
  UserMenuNotifier(UserMenuState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      userMenuModel: UserMenuModel(),
      isLoading: false,
    );
  }

  void toggleDarkMode() {
    final currentModel = state.userMenuModel;
    final updatedModel = currentModel?.copyWith(
      isDarkModeEnabled: !(currentModel.isDarkModeEnabled ?? true),
    );

    state = state.copyWith(
      userMenuModel: updatedModel,
    );
  }

  void signOut() {
    state = state.copyWith(
      isLoading: true,
    );

    // Perform sign out logic here
    // Clear user data, tokens, etc.

    state = state.copyWith(
      isLoading: false,
      isSignedOut: true,
    );
  }

  void updateUserProfile(
      String userName, String userEmail, String? avatarPath) {
    final currentModel = state.userMenuModel;
    final updatedModel = currentModel?.copyWith(
      userName: userName,
      userEmail: userEmail,
      avatarImagePath: avatarPath,
    );

    state = state.copyWith(
      userMenuModel: updatedModel,
    );
  }
}
