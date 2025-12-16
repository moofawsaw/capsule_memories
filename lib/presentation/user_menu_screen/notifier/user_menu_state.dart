part of 'user_menu_notifier.dart';

class UserMenuState extends Equatable {
  final bool? isLoading;
  final bool? isSignedOut;
  final UserMenuModel? userMenuModel;

  UserMenuState({
    this.isLoading = false,
    this.isSignedOut = false,
    this.userMenuModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        isSignedOut,
        userMenuModel,
      ];

  UserMenuState copyWith({
    bool? isLoading,
    bool? isSignedOut,
    UserMenuModel? userMenuModel,
  }) {
    return UserMenuState(
      isLoading: isLoading ?? this.isLoading,
      isSignedOut: isSignedOut ?? this.isSignedOut,
      userMenuModel: userMenuModel ?? this.userMenuModel,
    );
  }
}
