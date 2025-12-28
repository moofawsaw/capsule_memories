class UserMenuModel {
  final String userName;
  final String userEmail;
  final String? avatarImagePath;
  final String? bio;
  final String? userId;
  final bool isDarkModeEnabled;

  UserMenuModel({
    this.userName = '',
    this.userEmail = '',
    this.avatarImagePath,
    this.bio,
    this.userId,
    this.isDarkModeEnabled = true,
  });

  UserMenuModel copyWith({
    String? userName,
    String? userEmail,
    String? avatarImagePath,
    String? bio,
    String? userId,
    bool? isDarkModeEnabled,
  }) {
    return UserMenuModel(
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      bio: bio ?? this.bio,
      userId: userId ?? this.userId,
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
    );
  }
}
