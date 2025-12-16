import '../../../core/app_export.dart';

/// This class is used in the [AccountRegistrationScreen] screen.

// ignore_for_file: must_be_immutable
class AccountRegistrationModel extends Equatable {
  AccountRegistrationModel({
    this.email,
    this.password,
    this.confirmPassword,
    this.registrationMethod,
    this.isAgreedToTerms,
    this.id,
  }) {
    email = email ?? "";
    password = password ?? "";
    confirmPassword = confirmPassword ?? "";
    registrationMethod = registrationMethod ?? "email";
    isAgreedToTerms = isAgreedToTerms ?? false;
    id = id ?? "";
  }

  String? email;
  String? password;
  String? confirmPassword;
  String? registrationMethod;
  bool? isAgreedToTerms;
  String? id;

  AccountRegistrationModel copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? registrationMethod,
    bool? isAgreedToTerms,
    String? id,
  }) {
    return AccountRegistrationModel(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      registrationMethod: registrationMethod ?? this.registrationMethod,
      isAgreedToTerms: isAgreedToTerms ?? this.isAgreedToTerms,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        confirmPassword,
        registrationMethod,
        isAgreedToTerms,
        id,
      ];
}
