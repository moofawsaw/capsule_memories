class UserMenuModel {
  final String? userName;
  final String? userEmail;
  final String? avatarImagePath;
  final bool? isDarkModeEnabled;
  final String? authProvider;
  final DateTime? createdAt;

  UserMenuModel({
    this.userName,
    this.userEmail,
    this.avatarImagePath,
    this.isDarkModeEnabled,
    this.authProvider,
    this.createdAt,
  });

  UserMenuModel copyWith({
    String? userName,
    String? userEmail,
    String? avatarImagePath,
    bool? isDarkModeEnabled,
    String? authProvider,
    DateTime? createdAt,
  }) {
    return UserMenuModel(
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
