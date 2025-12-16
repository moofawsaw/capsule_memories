import 'package:flutter/material.dart';
import '../models/login_model.dart';
import '../../../core/app_export.dart';

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
  LoginNotifier(LoginState state) : super(state) {
    initialize();
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
      // Simulate login process
      await Future.delayed(Duration(seconds: 2));

      final email = state.emailController?.text ?? '';
      final password = state.passwordController?.text ?? '';

      // Mock validation - in real app, this would be API call
      if (email.isNotEmpty && password.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid credentials',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed. Please try again.',
      );
    }
  }

  /// Handle Google login
  void loginWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      // Simulate Google login process
      await Future.delayed(Duration(seconds: 2));

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google login failed. Please try again.',
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
      // Simulate Facebook login process
      await Future.delayed(Duration(seconds: 2));

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Facebook login failed. Please try again.',
      );
    }
  }

  @override
  void dispose() {
    state.emailController?.dispose();
    state.passwordController?.dispose();
    super.dispose();
  }
}
