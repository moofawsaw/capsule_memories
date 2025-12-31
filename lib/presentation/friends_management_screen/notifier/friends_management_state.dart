part of 'friends_management_notifier.dart';
part 'friends_management_state.freezed.dart';

enum CameraPermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
}

@freezed
class FriendsManagementState with _$FriendsManagementState {
  const factory FriendsManagementState({
    @Default(false) bool isLoading,
    @Default(false) bool isQRScannerActive,
    @Default(false) bool isCameraActive,
    CameraController? cameraController,
    @Default(CameraPermissionStatus.notDetermined)
    CameraPermissionStatus cameraPermissionStatus,
    String? errorMessage,
    String? successMessage,
    @Default('') String searchQuery,
    FriendsManagementModel? friendsManagementModel,
    List<FriendModel>? filteredFriendsList,
    List<SentRequestModel>? filteredSentRequestsList,
    List<IncomingRequestModel>? filteredIncomingRequestsList,
    List<SearchUserModel>? searchResults,
    @Default(false) bool isSearching,
  }) = _FriendsManagementState;
}