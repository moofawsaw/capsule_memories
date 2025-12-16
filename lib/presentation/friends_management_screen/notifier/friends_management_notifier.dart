import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/friends_management_model.dart';
import '../../../core/app_export.dart';

part 'friends_management_state.dart';

final friendsManagementNotifier = StateNotifierProvider.autoDispose<
    FriendsManagementNotifier, FriendsManagementState>(
  (ref) => FriendsManagementNotifier(
    FriendsManagementState(
      friendsManagementModel: FriendsManagementModel(),
    ),
  ),
);

class FriendsManagementNotifier extends StateNotifier<FriendsManagementState> {
  FriendsManagementNotifier(FriendsManagementState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      searchController: TextEditingController(),
      isLoading: false,
      friendsManagementModel: FriendsManagementModel(
        friendsList: _generateFriendsList(),
        sentRequestsList: _generateSentRequestsList(),
        incomingRequestsList: _generateIncomingRequestsList(),
      ),
    );
  }

  List<FriendModel> _generateFriendsList() {
    return [
      FriendModel(
        id: '1',
        profileImagePath: ImageConstant.imgFrame,
        userName: 'Justine Black',
      ),
      FriendModel(
        id: '2',
        profileImagePath: ImageConstant.imgFrameBlueGray90001,
        userName: 'Marcus Green',
      ),
    ];
  }

  List<SentRequestModel> _generateSentRequestsList() {
    return [
      SentRequestModel(
        id: '1',
        profileImagePath: ImageConstant.imgFrame48x48,
        userName: 'Sofia White',
        status: 'Pending',
      ),
      SentRequestModel(
        id: '2',
        profileImagePath: ImageConstant.imgFrame1,
        userName: 'Jonah White',
        status: 'Pending',
      ),
    ];
  }

  List<IncomingRequestModel> _generateIncomingRequestsList() {
    return [
      IncomingRequestModel(
        id: '1',
        profileImagePath: ImageConstant.imgFrame2,
        userName: 'Payton White',
        buttonText: 'Accept',
      ),
      IncomingRequestModel(
        id: '2',
        profileImagePath: ImageConstant.imgFrame3,
        userName: 'Bella Thorne',
        buttonText: 'Accept',
      ),
    ];
  }

  void onSearchChanged(String query) {
    state = state.copyWith(searchQuery: query);
    _filterFriends(query);
  }

  void _filterFriends(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        filteredFriendsList: state.friendsManagementModel?.friendsList,
        filteredSentRequestsList:
            state.friendsManagementModel?.sentRequestsList,
        filteredIncomingRequestsList:
            state.friendsManagementModel?.incomingRequestsList,
      );
    } else {
      final filteredFriends = state.friendsManagementModel?.friendsList
          ?.where((friend) =>
              friend.userName?.toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();

      final filteredSentRequests = state
          .friendsManagementModel?.sentRequestsList
          ?.where((request) =>
              request.userName?.toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();

      final filteredIncomingRequests = state
          .friendsManagementModel?.incomingRequestsList
          ?.where((request) =>
              request.userName?.toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();

      state = state.copyWith(
        filteredFriendsList: filteredFriends,
        filteredSentRequestsList: filteredSentRequests,
        filteredIncomingRequestsList: filteredIncomingRequests,
      );
    }
  }

  void onFriendTap(String friendId) {
    // Navigate to friend's profile or show options
  }

  void onFriendActionTap(String friendId) {
    // Show friend management options
  }

  void onRemoveSentRequest(String requestId) {
    final updatedList = state.friendsManagementModel?.sentRequestsList
        ?.where((request) => request.id != requestId)
        .toList();

    state = state.copyWith(
      friendsManagementModel: state.friendsManagementModel?.copyWith(
        sentRequestsList: updatedList,
      ),
    );

    _filterFriends(state.searchQuery ?? '');
  }

  void onAcceptIncomingRequest(String requestId) {
    final requestToAccept = state.friendsManagementModel?.incomingRequestsList
        ?.firstWhere((request) => request.id == requestId);

    if (requestToAccept != null) {
      // Add to friends list
      final newFriend = FriendModel(
        id: requestToAccept.id,
        profileImagePath: requestToAccept.profileImagePath,
        userName: requestToAccept.userName,
      );

      final updatedFriendsList = [
        ...(state.friendsManagementModel?.friendsList ?? []),
        newFriend,
      ];

      // Remove from incoming requests
      final updatedIncomingList = state
          .friendsManagementModel?.incomingRequestsList
          ?.where((request) => request.id != requestId)
          .toList();

      state = state.copyWith(
        friendsManagementModel: state.friendsManagementModel?.copyWith(
          friendsList: updatedFriendsList,
          incomingRequestsList: updatedIncomingList,
        ),
      );

      _filterFriends(state.searchQuery ?? '');
    }
  }

  Future<void> onQRScanTap() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        // Initialize QR scanner
        state = state.copyWith(isQRScannerActive: true);
        // QR scanning logic would be implemented here
      } else {
        state = state.copyWith(
            errorMessage: 'Camera permission is required for QR scanning');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to open QR scanner');
    }
  }

  Future<void> onCameraTap() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isGranted) {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          state = state.copyWith(isCameraActive: true);
          // Camera functionality would be implemented here
        }
      } else {
        state = state.copyWith(errorMessage: 'Camera permission is required');
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to open camera');
    }
  }

  @override
  void dispose() {
    state.searchController?.dispose();
    super.dispose();
  }
}
