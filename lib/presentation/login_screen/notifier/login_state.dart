part of 'login_notifier.dart';

class LoginState extends Equatable {
  final TextEditingController? emailController;
  final TextEditingController? passwordController;
  final bool? isLoading;
  final bool? isSuccess;
  final String? errorMessage;
  final LoginModel? loginModel;

  LoginState({
    this.emailController,
    this.passwordController,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.loginModel,
  });

  @override
  List<Object?> get props => [
        emailController,
        passwordController,
        isLoading,
        isSuccess,
        errorMessage,
        loginModel,
      ];

  LoginState copyWith({
    TextEditingController? emailController,
    TextEditingController? passwordController,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    LoginModel? loginModel,
  }) {
    return LoginState(
      emailController: emailController ?? this.emailController,
      passwordController: passwordController ?? this.passwordController,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      loginModel: loginModel ?? this.loginModel,
    );
  }
}
