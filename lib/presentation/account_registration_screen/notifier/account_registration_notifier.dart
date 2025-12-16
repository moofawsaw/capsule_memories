import 'package:flutter/material.dart';
import '../models/account_registration_model.dart';
import '../../../core/app_export.dart';

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
  AccountRegistrationNotifier(AccountRegistrationState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      emailController: TextEditingController(),
      passwordController: TextEditingController(),
      confirmPasswordController: TextEditingController(),
      isLoading: false,
      isSuccess: false,
      hasError: false,
      errorMessage: '',
    );
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

  void signUp() async {
    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: '',
    );

    try {
      // Simulate registration process
      await Future.delayed(Duration(seconds: 2));

      // Update model with form data
      final updatedModel = state.accountRegistrationModel?.copyWith(
        email: state.emailController?.text ?? '',
        password: state.passwordController?.text ?? '',
        registrationMethod: 'email',
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        accountRegistrationModel: updatedModel,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Registration failed. Please try again.',
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
      // Simulate Google sign up process
      await Future.delayed(Duration(seconds: 2));

      final updatedModel = state.accountRegistrationModel?.copyWith(
        email: 'user@gmail.com',
        registrationMethod: 'google',
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        accountRegistrationModel: updatedModel,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Google sign up failed. Please try again.',
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
      // Simulate Facebook sign up process
      await Future.delayed(Duration(seconds: 2));

      final updatedModel = state.accountRegistrationModel?.copyWith(
        email: 'user@facebook.com',
        registrationMethod: 'facebook',
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        accountRegistrationModel: updatedModel,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Facebook sign up failed. Please try again.',
      );
    }
  }

  void clearForm() {
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
    state.emailController?.dispose();
    state.passwordController?.dispose();
    state.confirmPasswordController?.dispose();
    super.dispose();
  }
}
