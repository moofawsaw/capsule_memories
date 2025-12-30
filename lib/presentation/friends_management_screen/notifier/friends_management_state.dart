part of 'friends_management_notifier.dart';

enum CameraPermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
}

class FriendsManagementState extends Equatable {
  final TextEditingController? searchController;
  final bool? isLoading;
  final bool? isQRScannerActive;
  final bool? isCameraActive;
  final CameraController? cameraController;
  final CameraPermissionStatus? cameraPermissionStatus;
  final String? searchQuery;
  final String? errorMessage;
  final FriendsManagementModel? friendsManagementModel;
  final List<FriendModel>? filteredFriendsList;
  final List<SentRequestModel>? filteredSentRequestsList;
  final List<IncomingRequestModel>? filteredIncomingRequestsList;
  final List<SearchUserModel>? searchResults;
  final bool? isSearching;

  FriendsManagementState({
    this.searchController,
    this.isLoading = false,
    this.isQRScannerActive = false,
    this.isCameraActive = false,
    this.cameraController,
    this.cameraPermissionStatus = CameraPermissionStatus.notDetermined,
    this.searchQuery,
    this.errorMessage,
    this.friendsManagementModel,
    this.filteredFriendsList,
    this.filteredSentRequestsList,
    this.filteredIncomingRequestsList,
    this.searchResults,
    this.isSearching = false,
  });

  @override
  List<Object?> get props => [
        searchController,
        isLoading,
        isQRScannerActive,
        isCameraActive,
        cameraController,
        cameraPermissionStatus,
        searchQuery,
        errorMessage,
        friendsManagementModel,
        filteredFriendsList,
        filteredSentRequestsList,
        filteredIncomingRequestsList,
        searchResults,
        isSearching,
      ];

  FriendsManagementState copyWith({
    TextEditingController? searchController,
    bool? isLoading,
    bool? isQRScannerActive,
    bool? isCameraActive,
    CameraController? cameraController,
    CameraPermissionStatus? cameraPermissionStatus,
    String? searchQuery,
    String? errorMessage,
    FriendsManagementModel? friendsManagementModel,
    List<FriendModel>? filteredFriendsList,
    List<SentRequestModel>? filteredSentRequestsList,
    List<IncomingRequestModel>? filteredIncomingRequestsList,
    List<SearchUserModel>? searchResults,
    bool? isSearching,
  }) {
    return FriendsManagementState(
      searchController: searchController ?? this.searchController,
      isLoading: isLoading ?? this.isLoading,
      isQRScannerActive: isQRScannerActive ?? this.isQRScannerActive,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      cameraController: cameraController ?? this.cameraController,
      cameraPermissionStatus:
          cameraPermissionStatus ?? this.cameraPermissionStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      friendsManagementModel:
          friendsManagementModel ?? this.friendsManagementModel,
      filteredFriendsList: filteredFriendsList ?? this.filteredFriendsList,
      filteredSentRequestsList:
          filteredSentRequestsList ?? this.filteredSentRequestsList,
      filteredIncomingRequestsList:
          filteredIncomingRequestsList ?? this.filteredIncomingRequestsList,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}
