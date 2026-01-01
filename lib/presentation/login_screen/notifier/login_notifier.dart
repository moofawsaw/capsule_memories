import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../services/supabase_service.dart';
import '../models/login_model.dart';

part 'login_state.dart';

final loginNotifier =
    StateNotifierProvider.autoDispose<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(
    LoginState(
      loginModel: LoginModel(),
    ),
  ),
);

class LoginNotifier extends StateNotifier<LoginState> {
  StreamSubscription<AuthState>? _authSubscription;

  LoginNotifier(LoginState state) : super(state) {
    initialize();
    _setupAuthListener();
  }

  void initialize() {
    state = state.copyWith(
      emailController: TextEditingController(),
      passwordController: TextEditingController(),
      isLoading: false,
      isSuccess: false,
      errorMessage: null,
    );
  }

  /// Setup auth state listener to reset loading state after OAuth callback
  void _setupAuthListener() {
    final supabaseClient = SupabaseService.instance.client;
    if (supabaseClient == null) return;

    _authSubscription = supabaseClient.auth.onAuthStateChange.listen((data) {
      // Reset loading state when auth succeeds or fails
      if (data.event == AuthChangeEvent.signedIn) {
        debugPrint('✅ OAuth sign-in successful - resetting loading state');
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          errorMessage: null,
        );
      } else if (data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.userDeleted) {
        debugPrint('👋 Auth state changed - resetting loading state');
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
        );
      }
    });
  }

  /// Validate email field
  String? validateEmail(String? value) {
    if (value?.isEmpty == true) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password field
  String? validatePassword(String? value) {
    if (value?.isEmpty == true) {
      return 'Password is required';
    }
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Handle login with email and password
  void login() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      final email = state.emailController?.text ?? '';
      final password = state.passwordController?.text ?? '';

      // Sign in with Supabase
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
        );
      } else {
        throw Exception('Login failed: Unable to authenticate user.');
      }
    } catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Please verify your email address before signing in.';
      } else if (e.toString().contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// Handle Google login with enhanced error handling and navigation
  void loginWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      // Sign in with Google OAuth
      // Supabase Flutter SDK v2.12.0+ handles deep link callbacks automatically
      // The auth state change listener in main.dart will handle success
      final authResponse = await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.capsulememories://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // Verify OAuth URL was generated successfully
      if (!authResponse) {
        throw AuthException(
          'Failed to generate Google OAuth URL. Please check your Supabase OAuth configuration.',
        );
      }

      // Note: Don't set loading to false here as OAuth flow redirects
      // The auth state listener will update UI when user returns
      // Keep loading state true while waiting for OAuth callback
    } on AuthException catch (e) {
      String errorMessage = 'Google login failed. Please try again.';

      if (e.message.contains('User cancelled')) {
        errorMessage = 'Google login was cancelled.';
      } else if (e.message.contains('popup_closed_by_user')) {
        errorMessage = 'Sign-in popup was closed. Please try again.';
      } else if (e.message.contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.message.contains('OAuth configuration')) {
        errorMessage =
            'Google Sign-In is not properly configured in Supabase. Please check the setup guide.';
      } else {
        errorMessage = 'Google login failed: ${e.message}';
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            'An unexpected error occurred during Google login. Please try again later.',
      );
    }
  }

  /// Handle Facebook login
  void loginWithFacebook() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      // Sign in with Facebook OAuth
      // Note: OAuth requires proper configuration in Supabase dashboard
      await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.capsulememories://login-callback/',
      );

      // Note: OAuth flow will redirect to browser/app, so we don't set success here
      // The auth state change listener in main.dart will handle the success case
      // Don't set loading to false here as the OAuth flow is async
    } catch (e) {
      String errorMessage =
          'Facebook login failed. Please ensure Facebook OAuth is configured in Supabase dashboard.';
      if (e.toString().isNotEmpty && !e.toString().contains('Exception: ')) {
        errorMessage = e.toString();
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  Future<void> signInWithEmail(BuildContext context) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      final email = state.emailController?.text ?? '';
      final password = state.passwordController?.text ?? '';

      // Sign in with Supabase
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: Unable to authenticate user.');
      }

      state = state.copyWith(isLoading: false);

      // Check for pending deep link action after login
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
      String errorMessage = 'Login failed. Please try again.';
      if (error.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please try again.';
      } else if (error.toString().contains('Email not confirmed')) {
        errorMessage = 'Please verify your email address before signing in.';
      } else if (error.toString().contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (error.toString().isNotEmpty) {
        errorMessage = error.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  @override
  void dispose() {
    state.emailController?.dispose();
    state.passwordController?.dispose();
    _authSubscription?.cancel();
    super.dispose();
  }
}
