part of 'user_profile_screen_two_notifier.dart';

class UserProfileScreenTwoState extends Equatable {
  final UserProfileScreenTwoModel? userProfileScreenTwoModel;
  final bool? isLoading;

  UserProfileScreenTwoState({
    this.userProfileScreenTwoModel,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
        userProfileScreenTwoModel,
        isLoading,
      ];

  UserProfileScreenTwoState copyWith({
    UserProfileScreenTwoModel? userProfileScreenTwoModel,
    bool? isLoading,
  }) {
    return UserProfileScreenTwoState(
      userProfileScreenTwoModel:
          userProfileScreenTwoModel ?? this.userProfileScreenTwoModel,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
