import '../../../core/app_export.dart';

/// This class is used in the [login_screen] screen.

// ignore_for_file: must_be_immutable
class LoginModel extends Equatable {
  LoginModel({
    this.email,
    this.password,
    this.rememberMe,
    this.id,
  }) {
    email = email ?? "";
    password = password ?? "";
    rememberMe = rememberMe ?? false;
    id = id ?? "";
  }

  String? email;
  String? password;
  bool? rememberMe;
  String? id;

  LoginModel copyWith({
    String? email,
    String? password,
    bool? rememberMe,
    String? id,
  }) {
    return LoginModel(
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [email, password, rememberMe, id];
}
