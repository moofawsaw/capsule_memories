part of 'friends_management_notifier.dart';

class FriendsManagementState extends Equatable {
  final TextEditingController? searchController;
  final bool? isLoading;
  final bool? isQRScannerActive;
  final bool? isCameraActive;
  final String? searchQuery;
  final String? errorMessage;
  final FriendsManagementModel? friendsManagementModel;
  final List<FriendModel>? filteredFriendsList;
  final List<SentRequestModel>? filteredSentRequestsList;
  final List<IncomingRequestModel>? filteredIncomingRequestsList;

  FriendsManagementState({
    this.searchController,
    this.isLoading = false,
    this.isQRScannerActive = false,
    this.isCameraActive = false,
    this.searchQuery,
    this.errorMessage,
    this.friendsManagementModel,
    this.filteredFriendsList,
    this.filteredSentRequestsList,
    this.filteredIncomingRequestsList,
  });

  @override
  List<Object?> get props => [
        searchController,
        isLoading,
        isQRScannerActive,
        isCameraActive,
        searchQuery,
        errorMessage,
        friendsManagementModel,
        filteredFriendsList,
        filteredSentRequestsList,
        filteredIncomingRequestsList,
      ];

  FriendsManagementState copyWith({
    TextEditingController? searchController,
    bool? isLoading,
    bool? isQRScannerActive,
    bool? isCameraActive,
    String? searchQuery,
    String? errorMessage,
    FriendsManagementModel? friendsManagementModel,
    List<FriendModel>? filteredFriendsList,
    List<SentRequestModel>? filteredSentRequestsList,
    List<IncomingRequestModel>? filteredIncomingRequestsList,
  }) {
    return FriendsManagementState(
      searchController: searchController ?? this.searchController,
      isLoading: isLoading ?? this.isLoading,
      isQRScannerActive: isQRScannerActive ?? this.isQRScannerActive,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      friendsManagementModel:
          friendsManagementModel ?? this.friendsManagementModel,
      filteredFriendsList: filteredFriendsList ?? this.filteredFriendsList,
      filteredSentRequestsList:
          filteredSentRequestsList ?? this.filteredSentRequestsList,
      filteredIncomingRequestsList:
          filteredIncomingRequestsList ?? this.filteredIncomingRequestsList,
    );
  }
}
