import '../../../core/app_export.dart';
import '../models/friends_management_model.dart';

enum CameraPermissionStatus {
  notDetermined,
  granted,
  denied,
  permanentlyDenied,
}

class FriendsManagementState extends Equatable {
  final bool isLoading;
  final bool isQRScannerActive;
  final bool isCameraActive;
  final String? errorMessage;
  final String? successMessage;
  final String searchQuery;
  final List<FriendModel>? filteredFriendsList;
  final List<SentRequestModel>? filteredSentRequestsList;
  final List<IncomingRequestModel>? filteredIncomingRequestsList;
  final List<SearchUserModel>? searchResults;
  final bool isSearching;

  const FriendsManagementState({
    this.isLoading = false,
    this.isQRScannerActive = false,
    this.isCameraActive = false,
    this.errorMessage,
    this.successMessage,
    this.searchQuery = '',
    this.filteredFriendsList,
    this.filteredSentRequestsList,
    this.filteredIncomingRequestsList,
    this.searchResults,
    this.isSearching = false,
  });

  FriendsManagementState copyWith({
    bool? isLoading,
    bool? isQRScannerActive,
    bool? isCameraActive,
    String? errorMessage,
    String? successMessage,
    String? searchQuery,
    List<FriendModel>? filteredFriendsList,
    List<SentRequestModel>? filteredSentRequestsList,
    List<IncomingRequestModel>? filteredIncomingRequestsList,
    List<SearchUserModel>? searchResults,
    bool? isSearching,
  }) {
    return FriendsManagementState(
      isLoading: isLoading ?? this.isLoading,
      isQRScannerActive: isQRScannerActive ?? this.isQRScannerActive,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredFriendsList: filteredFriendsList ?? this.filteredFriendsList,
      filteredSentRequestsList:
          filteredSentRequestsList ?? this.filteredSentRequestsList,
      filteredIncomingRequestsList:
          filteredIncomingRequestsList ?? this.filteredIncomingRequestsList,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isQRScannerActive,
        isCameraActive,
        errorMessage,
        successMessage,
        searchQuery,
        filteredFriendsList,
        filteredSentRequestsList,
        filteredIncomingRequestsList,
        searchResults,
        isSearching,
      ];
}
