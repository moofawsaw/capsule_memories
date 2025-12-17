
import '../../../core/app_export.dart';

/// This class is used in the [UserMenuScreen] screen.

// ignore_for_file: must_be_immutable
class UserMenuModel extends Equatable {
  UserMenuModel({
    this.userName,
    this.userEmail,
    this.avatarImagePath,
    this.isDarkModeEnabled,
    this.id,
  }) {
    userName = userName ?? "Joe Kool";
    userEmail = userEmail ?? "email112@gmail.com";
    avatarImagePath = avatarImagePath ?? ImageConstant.imgEllipse852x52;
    isDarkModeEnabled = isDarkModeEnabled ?? true;
    id = id ?? "";
  }

  String? userName;
  String? userEmail;
  String? avatarImagePath;
  bool? isDarkModeEnabled;
  String? id;

  UserMenuModel copyWith({
    String? userName,
    String? userEmail,
    String? avatarImagePath,
    bool? isDarkModeEnabled,
    String? id,
  }) {
    return UserMenuModel(
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        userName,
        userEmail,
        avatarImagePath,
        isDarkModeEnabled,
        id,
      ];
}
