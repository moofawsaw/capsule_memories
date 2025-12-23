part of 'user_menu_notifier.dart';

class UserMenuState extends Equatable {
  final UserMenuModel? userMenuModel;
  final bool isLoading;
  final bool isSignedOut;

  UserMenuState({
    this.userMenuModel,
    this.isLoading = false,
    this.isSignedOut = false,
  });

  UserMenuState copyWith({
    UserMenuModel? userMenuModel,
    bool? isLoading,
    bool? isSignedOut,
  }) {
    return UserMenuState(
      userMenuModel: userMenuModel ?? this.userMenuModel,
      isLoading: isLoading ?? this.isLoading,
      isSignedOut: isSignedOut ?? this.isSignedOut,
    );
  }

  @override
  List<Object?> get props => [userMenuModel, isLoading, isSignedOut];
}
