import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../models/password_reset_model.dart';

part 'password_reset_state.dart';

final passwordResetNotifier = StateNotifierProvider.autoDispose<
    PasswordResetNotifier, PasswordResetState>(
  (ref) => PasswordResetNotifier(
    PasswordResetState(
      passwordResetModel: PasswordResetModel(),
    ),
  ),
);

class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  PasswordResetNotifier(PasswordResetState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      emailController: TextEditingController(),
      isLoading: false,
      isSuccess: false,
      errorMessage: null,
    );
  }

  void dispose() {
    state.emailController?.dispose();
  }

  String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value!)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Request password reset email
  Future<void> requestPasswordReset() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    try {
      final supabaseClient = SupabaseService.instance.client;
      if (supabaseClient == null) {
        throw Exception(
            'Supabase is not initialized. Please check your configuration.');
      }

      final email = state.emailController?.text ?? '';

      // Request password reset from Supabase
      await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.capsulememories://reset-password/',
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      String errorMessage = 'Failed to send reset email. Please try again.';
      if (e.toString().contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('rate limit')) {
        errorMessage = 'Too many requests. Please try again later.';
      } else if (e.toString().isNotEmpty) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  void resetPassword() {
    final email = state.emailController?.text ?? '';

    if (email.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter your email address',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    // Simulate password reset API call
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        // Clear form and show success
        state.emailController?.clear();

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          errorMessage: null,
        );

        // Reset success state after showing message
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            state = state.copyWith(isSuccess: false);
          }
        });
      }
    });
  }
}