part of 'user_profile_screen_two_notifier.dart';

class UserProfileScreenTwoState extends Equatable {
  UserProfileScreenTwoState({
    this.userProfileScreenTwoModel,
    this.isUploading = false,
    this.isLoading = false,
    this.isLoadingStories = false,
    this.isFollowing = false,
    this.isFriend = false,
    this.hasPendingFriendRequest = false,
    this.isBlocked = false,
    this.targetUserId,

    // ✅ inline save UX
    this.isSavingDisplayName = false,
    this.isSavingUsername = false,
    this.displayNameSavedPulse = false,
    this.usernameSavedPulse = false,

    // ✅ NEW: validation / error messaging
    this.displayNameError,
    this.usernameError,
  });

  UserProfileScreenTwoModel? userProfileScreenTwoModel;

  bool isUploading;
  bool isLoading;
  bool isLoadingStories;

  bool isFollowing;
  bool isFriend;
  bool hasPendingFriendRequest;
  bool isBlocked;

  String? targetUserId;

  // ✅ name / username save state
  bool isSavingDisplayName;
  bool isSavingUsername;
  bool displayNameSavedPulse;
  bool usernameSavedPulse;

  // ✅ NEW: errors (null = no error)
  String? displayNameError;
  String? usernameError;

  @override
  List<Object?> get props => [
    userProfileScreenTwoModel,
    isUploading,
    isLoading,
    isLoadingStories,
    isFollowing,
    isFriend,
    hasPendingFriendRequest,
    isBlocked,
    targetUserId,

    // ✅ save UX
    isSavingDisplayName,
    isSavingUsername,
    displayNameSavedPulse,
    usernameSavedPulse,

    // ✅ errors
    displayNameError,
    usernameError,
  ];

  UserProfileScreenTwoState copyWith({
    UserProfileScreenTwoModel? userProfileScreenTwoModel,
    bool? isUploading,
    bool? isLoading,
    bool? isLoadingStories,
    bool? isFollowing,
    bool? isFriend,
    bool? hasPendingFriendRequest,
    bool? isBlocked,
    String? targetUserId,

    // ✅ save UX
    bool? isSavingDisplayName,
    bool? isSavingUsername,
    bool? displayNameSavedPulse,
    bool? usernameSavedPulse,

    // ✅ errors
    String? displayNameError,
    String? usernameError,
  }) {
    return UserProfileScreenTwoState(
      userProfileScreenTwoModel:
      userProfileScreenTwoModel ?? this.userProfileScreenTwoModel,
      isUploading: isUploading ?? this.isUploading,
      isLoading: isLoading ?? this.isLoading,
      isLoadingStories: isLoadingStories ?? this.isLoadingStories,
      isFollowing: isFollowing ?? this.isFollowing,
      isFriend: isFriend ?? this.isFriend,
      hasPendingFriendRequest:
      hasPendingFriendRequest ?? this.hasPendingFriendRequest,
      isBlocked: isBlocked ?? this.isBlocked,
      targetUserId: targetUserId ?? this.targetUserId,

      // ✅ save UX
      isSavingDisplayName: isSavingDisplayName ?? this.isSavingDisplayName,
      isSavingUsername: isSavingUsername ?? this.isSavingUsername,
      displayNameSavedPulse:
      displayNameSavedPulse ?? this.displayNameSavedPulse,
      usernameSavedPulse: usernameSavedPulse ?? this.usernameSavedPulse,

      // ✅ errors (note: passing null clears the error)
      displayNameError: displayNameError,
      usernameError: usernameError,
    );
  }
}
