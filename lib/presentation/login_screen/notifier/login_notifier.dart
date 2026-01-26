import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_export.dart';
import '../../../core/services/native_facebook_sign_in_service.dart';
import '../../../core/services/native_google_sign_in_service.dart';
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
  Timer? _oauthTimeoutTimer;

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
      // Cancel timeout timer when auth state changes
      _oauthTimeoutTimer?.cancel();

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

  /// Reset loading state if user is not authenticated
  /// Called when app resumes from background (user returned from OAuth)
  void resetLoadingIfNotAuthenticated() {
    final supabaseClient = SupabaseService.instance.client;

    // Only do work if we were in an OAuth loading state
    if (!(state.isLoading ?? false)) return;

    // Give Supabase a moment to process any deep link callback after resume.
    Future.delayed(const Duration(milliseconds: 350), () {
      final session = supabaseClient?.auth.currentSession;

      // If there is still no active session, user backed out/cancelled.
      if (session == null && (state.isLoading ?? false)) {
        debugPrint(
          '🔄 Returned from OAuth without session - resetting loading state',
        );
        _oauthTimeoutTimer?.cancel();
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
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

      // Native Google sign-in (mobile-first) → exchange ID token with Supabase.
      // This avoids the browser OAuth redirect flow entirely.
      try {
        await NativeGoogleSignInService.signIn(supabaseClient);
        // NOTE: We intentionally do not set isSuccess/isLoading here.
        // The auth state listener will update UI when Supabase session is established.
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

      final authResponse = await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.capsulememories://login-callback/',
        // Use an in-app browser (Custom Tabs on Android) for a smoother OAuth UX.
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );

      if (!authResponse) {
        throw AuthException(
          'Failed to generate Google OAuth URL. Please check your Supabase OAuth configuration.',
        );
      }

      // Set a fallback timeout to reset loading state if OAuth doesn't complete
      _oauthTimeoutTimer = Timer(Duration(seconds: 60), () {
        if (state.isLoading ?? false) {
          debugPrint('⏰ OAuth timeout - resetting loading state');
          resetLoadingIfNotAuthenticated();
        }
      });

      // NOTE: Don't set loading to false here as OAuth flow redirects
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
      } else if (e.message.contains('Unacceptable audience in id_token')) {
        errorMessage =
            'Google sign-in is misconfigured (ID token audience mismatch). '
            'Make sure `GOOGLE_WEB_CLIENT_ID` matches the Web client ID in Supabase → Auth → Providers → Google.';
      } else if (e.message.contains('OAuth configuration')) {
        errorMessage =
            'Google Sign-In is not properly configured in Supabase. Please check the setup guide.';
      } else {
        errorMessage = 'Google login failed: ${e.message}';
      }

      _oauthTimeoutTimer?.cancel();
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      _oauthTimeoutTimer?.cancel();
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

      // ANDROID NOTE:
      // Native Facebook app-switch returns a classic access token which Supabase rejects
      // in some environments ("bad id token"). For Android we use OAuth code flow but
      // launch it in an in-app browser (Custom Tabs) to keep UX inside the app.
      if (defaultTargetPlatform == TargetPlatform.android) {
        final ok = await supabaseClient.auth.signInWithOAuth(
          OAuthProvider.facebook,
          redirectTo: 'io.supabase.capsulememories://login-callback/',
          authScreenLaunchMode: LaunchMode.inAppBrowserView,
        );
        if (!ok) {
          throw const AuthException(
            'Failed to generate Facebook OAuth URL.',
          );
        }

        _oauthTimeoutTimer = Timer(const Duration(seconds: 60), () {
          if (state.isLoading ?? false) {
            debugPrint('⏰ OAuth timeout - resetting loading state');
            resetLoadingIfNotAuthenticated();
          }
        });
        return;
      }

      // Native Facebook sign-in (mobile-first) → exchange access token with Supabase.
      // This avoids the browser OAuth redirect flow entirely.
      try {
        await NativeFacebookSignInService.signIn(supabaseClient);
        // Auth listener will update UI when session is established.
        return;
      } on AuthException catch (e) {
        // If native FB isn't configured/available, fall back to browser OAuth.
        final code = (e.code ?? '').trim();
        final msg = e.message.toLowerCase();
        const configErrorCodes = {
          'providerConfigurationError',
          'clientConfigurationError',
          'uiUnavailable',
          'operationInProgress',
        };
        final bool looksLikeAndroidTokenValidationEdgeCase =
            (defaultTargetPlatform == TargetPlatform.android) &&
                (msg.contains('bad id token') || msg.contains('bad_id_token'));
        if (!configErrorCodes.contains(code) && !looksLikeAndroidTokenValidationEdgeCase) {
          rethrow;
        }

        debugPrint(
          'ℹ️ Native Facebook sign-in unavailable ($code). Falling back to OAuth.',
        );
      }

      await supabaseClient.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.capsulememories://login-callback/',
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );

      // Set a fallback timeout to reset loading state if OAuth doesn't complete
      _oauthTimeoutTimer = Timer(Duration(seconds: 60), () {
        if (state.isLoading ?? false) {
          debugPrint('⏰ OAuth timeout - resetting loading state');
          resetLoadingIfNotAuthenticated();
        }
      });

      // Note: OAuth flow will redirect to browser/app, so we don't set success here
      // The auth state change listener in main.dart will handle the success case
      // Don't set loading to false here as the OAuth flow is async
    } on AuthException catch (e) {
      String errorMessage = 'Facebook login failed. Please try again.';
      if (e.message.contains('cancelled')) {
        errorMessage = 'Facebook login was cancelled.';
      } else if (e.message.contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Facebook login failed: ${e.message}';
      }

      _oauthTimeoutTimer?.cancel();
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    } catch (e) {
      String errorMessage =
          'Facebook login failed. Please ensure Facebook OAuth is configured in Supabase dashboard.';
      if (e.toString().isNotEmpty && !e.toString().contains('Exception: ')) {
        errorMessage = e.toString();
      }

      _oauthTimeoutTimer?.cancel();
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
    _oauthTimeoutTimer?.cancel();
    super.dispose();
  }
}
