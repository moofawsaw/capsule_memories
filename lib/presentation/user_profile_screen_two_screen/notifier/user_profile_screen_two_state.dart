part of 'user_profile_screen_two_notifier.dart';

class UserProfileScreenTwoState extends Equatable {
  UserProfileScreenTwoState({
    this.userProfileScreenTwoModel,
    this.isUploading = false,
    this.isLoading = false,
  });

  UserProfileScreenTwoModel? userProfileScreenTwoModel;
  bool isUploading;
  bool isLoading;

  @override
  List<Object?> get props => [
        userProfileScreenTwoModel,
        isUploading,
        isLoading,
      ];

  UserProfileScreenTwoState copyWith({
    UserProfileScreenTwoModel? userProfileScreenTwoModel,
    bool? isUploading,
    bool? isLoading,
  }) {
    return UserProfileScreenTwoState(
      userProfileScreenTwoModel:
          userProfileScreenTwoModel ?? this.userProfileScreenTwoModel,
      isUploading: isUploading ?? this.isUploading,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
