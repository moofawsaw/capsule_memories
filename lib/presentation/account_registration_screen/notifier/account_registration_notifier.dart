import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../core/services/native_google_sign_in_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/user_profile_service.dart';
import '../models/account_registration_model.dart';

part 'account_registration_state.dart';

final accountRegistrationNotifier = StateNotifierProvider.autoDispose<
    AccountRegistrationNotifier, AccountRegistrationState>(
  (ref) => AccountRegistrationNotifier(
    AccountRegistrationState(
      accountRegistrationModel: AccountRegistrationModel(),
    ),
  ),
);

class AccountRegistrationNotifier
    extends StateNotifier<AccountRegistrationState> {
  StreamSubscription<AuthState>? _authSubscription;

  AccountRegistrationNotifier(AccountRegistrationState state) : super(state) {
    initialize();
    _setupAuthListener();
  }

  void initialize() {
    state = state.copyWith(
      nameController: TextEditingController(),
      emailController: TextEditingController(),
      passwordController: TextEditingController(),
      confirmPasswordController: TextEditingController(),
      isLoading: false,
      isSuccess: false,
      hasError: false,
      errorMessage: '',
    );
  }

  /// Setup auth state listener to reset loading state after social sign-in.
  void _setupAuthListener() {
    final supabaseClient = SupabaseService.instance.client;
    if (supabaseClient == null) return;

    _authSubscription = supabaseClient.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        debugPrint('✅ Social sign-in successful - finishing registration flow');
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          hasError: false,
          errorMessage: '',
        );
      } else if (data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.userDeleted) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
        );
      }
    });
  }

  String? validateName(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Name is required';
    }
    if ((value?.length ?? 0) < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Password is required';
    }
    if ((value?.length ?? 0) < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please confirm your password';
    }
    if (value != state.passwordController?.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> signUpWithEmail(BuildContext context) async {
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: '',
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      await supabaseClient.auth.signUp(
        email: state.emailController!.text,
        password: state.passwordController!.text,
      );

      state = state.copyWith(isLoading: false);

      // Check for pending deep link action after signup
      final result = await DeepLinkService().completePendingAction();
      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Action completed!')),
        );
      }

      NavigatorService.pushNamedAndRemoveUntil(
        AppRoutes.appFeed,
      );
    } catch (error) {
      String errorMessage = 'Registration failed. Please try again.';
      if (error.toString().contains('User already registered')) {
        errorMessage =
            'This email is already registered. Please sign in instead.';
      } else if (error.toString().contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (error.toString().contains('Password')) {
        errorMessage = 'Password does not meet requirements.';
      } else if (error.toString().isNotEmpty) {
        errorMessage = error.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: errorMessage,
      );
    }
  }

  void signUp() async {
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: '',
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      final name = state.nameController?.text ?? '';
      final email = state.emailController?.text ?? '';
      final password = state.passwordController?.text ?? '';

      // Sign up with Supabase
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Update user_profiles with the display name
        await UserProfileService.instance.updateUserProfile(
          displayName: name,
        );

        // Update model with form data
        final updatedModel = state.accountRegistrationModel?.copyWith(
          email: email,
          password: password,
          registrationMethod: 'email',
        );

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          accountRegistrationModel: updatedModel,
        );
      } else {
        throw Exception('Registration failed: Unable to create user account.');
      }
    } catch (e) {
      String errorMessage = 'Registration failed. Please try again.';
      if (e.toString().contains('User already registered')) {
        errorMessage =
            'This email is already registered. Please sign in instead.';
      } else if (e.toString().contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('Password')) {
        errorMessage = 'Password does not meet requirements.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: errorMessage,
      );
    }
  }

  void signUpWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: '',
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      // Native Google sign-in (mobile-first) → exchange ID token with Supabase.
      try {
        await NativeGoogleSignInService.signIn(supabaseClient);
        // NOTE: We intentionally do not set isSuccess/isLoading here.
        // `_setupAuthListener` will update UI when Supabase session is established.
        return;
      } on AuthException catch (e) {
        // If native Google Sign-In isn't configured on this build/device,
        // fall back to Supabase's browser OAuth (still using Custom Tabs).
        final code = (e.code ?? '').trim();
        const configErrorCodes = {
          'clientConfigurationError',
          'providerConfigurationError',
          'uiUnavailable',
          // Android: native sign-in couldn't mint an ID token (often missing SHA/OAuth client).
          'failedToRetrieveAuthToken',
          // Some builds report this when Google Play Console / OAuth isn't wired up.
          'developerConsoleNotSetUpCorrectly',
        };
        if (!configErrorCodes.contains(code)) rethrow;

        debugPrint(
          'ℹ️ Native Google sign-in unavailable ($code). Falling back to OAuth.',
        );
      }

      await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.capsulememories://login-callback/',
        // Use an in-app browser (Custom Tabs on Android) for a smoother OAuth UX.
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );

      // NOTE: OAuth flow will redirect to browser/app, so we don't set success here.
      // `_setupAuthListener` will update UI when Supabase session is established.
    } catch (e) {
      String errorMessage =
          'Google sign up failed. Please ensure Google OAuth is configured in Supabase dashboard.';
      if (e.toString().contains('Unacceptable audience in id_token')) {
        errorMessage =
            'Google sign-in is misconfigured (ID token audience mismatch). '
            'Make sure `GOOGLE_WEB_CLIENT_ID` matches the Web client ID in Supabase → Auth → Providers → Google.';
      }
      if (e.toString().isNotEmpty && !e.toString().contains('Exception: ')) {
        errorMessage = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: errorMessage,
      );
    }
  }

  void signUpWithFacebook() async {
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: '',
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      // Sign in with Facebook OAuth with forced re-authentication
      // Note: OAuth requires proper configuration in Supabase dashboard
      await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.capsulememories://login-callback/',
        // Use an in-app browser (Custom Tabs on Android) for a smoother OAuth UX.
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );

      // Note: OAuth flow will redirect to browser/app, so we don't set success here
      // The auth state change listener in main.dart will handle the success case
      // Don't set loading to false here as the OAuth flow is async
    } catch (e) {
      String errorMessage =
          'Facebook sign up failed. Please ensure Facebook OAuth is configured in Supabase dashboard.';
      if (e.toString().isNotEmpty && !e.toString().contains('Exception: ')) {
        errorMessage = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: errorMessage,
      );
    }
  }

  void clearForm() {
    state.nameController?.clear();
    state.emailController?.clear();
    state.passwordController?.clear();
    state.confirmPasswordController?.clear();

    state = state.copyWith(
      isSuccess: false,
      hasError: false,
      errorMessage: '',
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    state.nameController?.dispose();
    state.emailController?.dispose();
    state.passwordController?.dispose();
    state.confirmPasswordController?.dispose();
    super.dispose();
  }
}
