part of 'account_registration_notifier.dart';

class AccountRegistrationState extends Equatable {
  final TextEditingController? emailController;
  final TextEditingController? passwordController;
  final TextEditingController? confirmPasswordController;
  final bool? isLoading;
  final bool? isSuccess;
  final bool? hasError;
  final String? errorMessage;
  final AccountRegistrationModel? accountRegistrationModel;

  AccountRegistrationState({
    this.emailController,
    this.passwordController,
    this.confirmPasswordController,
    this.isLoading = false,
    this.isSuccess = false,
    this.hasError = false,
    this.errorMessage = '',
    this.accountRegistrationModel,
  });

  @override
  List<Object?> get props => [
        emailController,
        passwordController,
        confirmPasswordController,
        isLoading,
        isSuccess,
        hasError,
        errorMessage,
        accountRegistrationModel,
      ];

  AccountRegistrationState copyWith({
    TextEditingController? emailController,
    TextEditingController? passwordController,
    TextEditingController? confirmPasswordController,
    bool? isLoading,
    bool? isSuccess,
    bool? hasError,
    String? errorMessage,
    AccountRegistrationModel? accountRegistrationModel,
  }) {
    return AccountRegistrationState(
      emailController: emailController ?? this.emailController,
      passwordController: passwordController ?? this.passwordController,
      confirmPasswordController:
          confirmPasswordController ?? this.confirmPasswordController,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      accountRegistrationModel:
          accountRegistrationModel ?? this.accountRegistrationModel,
    );
  }
}
