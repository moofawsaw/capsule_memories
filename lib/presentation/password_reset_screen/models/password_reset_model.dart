import '../../../core/app_export.dart';

/// This class is used in the [PasswordResetScreen] screen.

// ignore_for_file: must_be_immutable
class PasswordResetModel extends Equatable {
  PasswordResetModel({
    this.email,
    this.id,
  }) {
    email = email ?? "";
    id = id ?? "";
  }

  String? email;
  String? id;

  PasswordResetModel copyWith({
    String? email,
    String? id,
  }) {
    return PasswordResetModel(
      email: email ?? this.email,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        email,
        id,
      ];
}
