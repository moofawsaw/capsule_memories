part of 'password_reset_notifier.dart';

class PasswordResetState extends Equatable {
  final TextEditingController? emailController;
  final bool? isLoading;
  final bool? isSuccess;
  final String? errorMessage;
  final PasswordResetModel? passwordResetModel;

  PasswordResetState({
    this.emailController,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.passwordResetModel,
  });

  @override
  List<Object?> get props => [
        emailController,
        isLoading,
        isSuccess,
        errorMessage,
        passwordResetModel,
      ];

  PasswordResetState copyWith({
    TextEditingController? emailController,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    PasswordResetModel? passwordResetModel,
  }) {
    return PasswordResetState(
      emailController: emailController ?? this.emailController,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      passwordResetModel: passwordResetModel ?? this.passwordResetModel,
    );
  }
}
