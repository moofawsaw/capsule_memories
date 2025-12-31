import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_export.dart';
import '../../../services/friends_service.dart';
import '../models/friends_management_model.dart';
import './friends_management_state.dart';

final friendsManagementNotifier = StateNotifierProvider.autoDispose<
    FriendsManagementNotifier, FriendsManagementState>(
  (ref) => FriendsManagementNotifier(
    FriendsManagementState(
      friendsManagementModel: FriendsManagementModel(),
    ),
  ),
);

class FriendsManagementNotifier extends StateNotifier<FriendsManagementState> {
  final FriendsService _friendsService = FriendsService();
  CameraController? _cameraController;
  String _searchQuery = '';

  FriendsManagementNotifier(FriendsManagementState state) : super(state) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(
      friendsManagementModel: FriendsManagementModel(),
      isLoading: true,
    );

    await _fetchAllFriendsData();

    state = state.copyWith(
      isLoading: false,
    );
  }

  Future<void> _fetchAllFriendsData() async {
    try {
      // Fetch friends, sent requests, and incoming requests concurrently
      final results = await Future.wait([
        _friendsService.getUserFriends(),
        _friendsService.getSentFriendRequests(),
        _friendsService.getIncomingFriendRequests(),
      ]);

      final friendsData = results[0];
      final sentRequestsData = results[1];
      final incomingRequestsData = results[2];

      state = state.copyWith(
        friendsManagementModel: FriendsManagementModel(
          friendsList: _transformFriendsData(friendsData),
          sentRequestsList: _transformSentRequestsData(sentRequestsData),
          incomingRequestsList:
              _transformIncomingRequestsData(incomingRequestsData),
        ),
      );

      _filterFriends(_searchQuery);
    } catch (e) {
      debugPrint('Error fetching friends data: $e');
      state = state.copyWith(
        errorMessage: 'Failed to load friends data',
        isLoading: false,
      );
    }
  }

  List<FriendModel> _transformFriendsData(List<Map<String, dynamic>> data) {
    return data.map((friend) {
      return FriendModel(
        id: friend['id'] ?? '',
        friendshipId: friend['friendship_id'] ?? '',
        userName: friend['username'] ?? '',
        displayName: friend['display_name'] ?? friend['username'] ?? '',
        profileImagePath: friend['avatar_url'] ?? '',
      );
    }).toList();
  }

  List<SentRequestModel> _transformSentRequestsData(
      List<Map<String, dynamic>> data) {
    return data.map((request) {
      return SentRequestModel(
        id: request['id'] ?? '',
        userId: request['user_id'] ?? '',
        userName: request['username'] ?? '',
        displayName: request['display_name'] ?? request['username'] ?? '',
        profileImagePath: request['avatar_url'] ?? '',
        status: request['status'] ?? 'pending',
      );
    }).toList();
  }

  List<IncomingRequestModel> _transformIncomingRequestsData(
      List<Map<String, dynamic>> data) {
    return data.map((request) {
      return IncomingRequestModel(
        id: request['id'] ?? '',
        userId: request['user_id'] ?? '',
        userName: request['username'] ?? '',
        displayName: request['display_name'] ?? request['username'] ?? '',
        profileImagePath: request['avatar_url'] ?? '',
        bio: request['bio'] ?? '',
        buttonText: 'Accept',
      );
    }).toList();
  }

  void onSearchChanged(String query) {
    _searchQuery = query;
    state = state.copyWith(
      searchQuery: query,
    );

    if (query.isEmpty) {
      state = state.copyWith(
        searchResults: [],
        isSearching: false,
      );
      _filterFriends(query);
    } else {
      _searchUsers(query);
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      state = state.copyWith(
        isSearching: true,
      );

      final usersData = await _friendsService.searchAllUsers(query);

      // Get friendship status for each user
      final searchResults = await Future.wait(
        usersData.map((user) async {
          final status = await _friendsService.getFriendshipStatus(user['id']);
          return SearchUserModel(
            id: user['id'] ?? '',
            userName: user['username'] ?? '',
            displayName: user['display_name'] ?? user['username'] ?? '',
            profileImagePath: user['avatar_url'] ?? '',
            bio: user['bio'] ?? '',
            friendshipStatus: status,
          );
        }),
      );

      state = state.copyWith(
        searchResults: searchResults,
        isSearching: false,
      );
    } catch (e) {
      debugPrint('Error searching users: $e');
      state = state.copyWith(
        errorMessage: 'Failed to search users',
        isSearching: false,
      );
    }
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
              (friend.userName?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (friend.displayName
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
          .toList();

      final filteredSentRequests = state
          .friendsManagementModel?.sentRequestsList
          ?.where((request) =>
              (request.userName?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (request.displayName
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
          .toList();

      final filteredIncomingRequests = state
          .friendsManagementModel?.incomingRequestsList
          ?.where((request) =>
              (request.userName?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (request.displayName
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
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

  Future<void> onRemoveSentRequest(String requestId) async {
    try {
      final success = await _friendsService.cancelSentRequest(requestId);

      if (success) {
        final updatedList = state.friendsManagementModel?.sentRequestsList
            ?.where((request) => request.id != requestId)
            .toList();

        state = state.copyWith(
          friendsManagementModel: state.friendsManagementModel?.copyWith(
            sentRequestsList: updatedList,
          ),
        );

        _filterFriends(_searchQuery);
      }
    } catch (e) {
      debugPrint('Error removing sent request: $e');
      state = state.copyWith(
        errorMessage: 'Failed to cancel request',
      );
    }
  }

  Future<void> onAcceptIncomingRequest(String requestId) async {
    try {
      final success = await _friendsService.acceptFriendRequest(requestId);

      if (success) {
        // Refresh all friends data to get updated lists
        await _fetchAllFriendsData();
      }
    } catch (e) {
      debugPrint('Error accepting request: $e');
      state = state.copyWith(
        errorMessage: 'Failed to accept request',
      );
    }
  }

  Future<void> onDeclineIncomingRequest(String requestId) async {
    try {
      final success = await _friendsService.declineFriendRequest(requestId);

      if (success) {
        final updatedList = state.friendsManagementModel?.incomingRequestsList
            ?.where((request) => request.id != requestId)
            .toList();

        state = state.copyWith(
          friendsManagementModel: state.friendsManagementModel?.copyWith(
            incomingRequestsList: updatedList,
          ),
        );

        _filterFriends(_searchQuery);
      }
    } catch (e) {
      debugPrint('Error declining request: $e');
      state = state.copyWith(
        errorMessage: 'Failed to decline request',
      );
    }
  }

  Future<void> onRemoveFriend(String friendshipId) async {
    try {
      final success = await _friendsService.removeFriend(friendshipId);

      if (success) {
        final updatedList = state.friendsManagementModel?.friendsList
            ?.where((friend) => friend.friendshipId != friendshipId)
            .toList();

        state = state.copyWith(
          friendsManagementModel: state.friendsManagementModel?.copyWith(
            friendsList: updatedList,
          ),
        );

        _filterFriends(_searchQuery);
      }
    } catch (e) {
      debugPrint('Error removing friend: $e');
      state = state.copyWith(
        errorMessage: 'Failed to remove friend',
      );
    }
  }

  Future<void> onQRScanTap() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        // Initialize QR scanner
        state = state.copyWith(
          isQRScannerActive: true,
        );
        // QR scanning logic would be implemented here
      } else {
        state = state.copyWith(
          errorMessage: 'Camera permission is required for QR scanning',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to open QR scanner',
      );
    }
  }

  Future<void> onCameraTap() async {
    try {
      // Check if user has previously granted/denied permission
      final prefs = await SharedPreferences.getInstance();
      final hasAskedBefore = prefs.getBool('camera_permission_asked') ?? false;

      // Request camera permission
      PermissionStatus cameraStatus = await Permission.camera.status;

      if (cameraStatus.isDenied && !hasAskedBefore) {
        // First time asking - request permission
        cameraStatus = await Permission.camera.request();
        await prefs.setBool('camera_permission_asked', true);

        if (cameraStatus.isGranted) {
          await prefs.setBool('camera_permission_granted', true);
        } else if (cameraStatus.isPermanentlyDenied) {
          await prefs.setBool('camera_permission_permanently_denied', true);
        }
      } else if (cameraStatus.isDenied) {
        // User has been asked before - request again
        cameraStatus = await Permission.camera.request();

        if (cameraStatus.isGranted) {
          await prefs.setBool('camera_permission_granted', true);
          await prefs.setBool('camera_permission_permanently_denied', false);
        } else if (cameraStatus.isPermanentlyDenied) {
          await prefs.setBool('camera_permission_permanently_denied', true);
        }
      }

      if (cameraStatus.isGranted) {
        // Permission granted - initialize camera
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          state = state.copyWith(
            errorMessage: 'No cameras available on this device',
          );
          return;
        }

        // Use rear camera for scanning
        final camera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        state = state.copyWith(
          isCameraActive: true,
          cameraController: _cameraController,
          cameraPermissionStatus: CameraPermissionStatus.granted,
        );
      } else if (cameraStatus.isPermanentlyDenied) {
        // User permanently denied - show settings dialog
        state = state.copyWith(
          cameraPermissionStatus: CameraPermissionStatus.permanentlyDenied,
          errorMessage:
              'Camera permission is required for scanning. Please enable it in app settings.',
        );
      } else {
        // User denied permission
        state = state.copyWith(
          cameraPermissionStatus: CameraPermissionStatus.denied,
          errorMessage: 'Camera permission is required to scan QR codes',
        );
      }
    } catch (e) {
      debugPrint('Error opening camera: $e');
      state = state.copyWith(
        errorMessage: 'Failed to open camera. Please try again.',
        isCameraActive: false,
      );
    }
  }

  Future<void> processScannedQRCode(String qrCode) async {
    try {
      debugPrint('Processing QR code: $qrCode');

      // Parse the QR code data - expecting format: capsule://friend-request/USER_ID
      final uri = Uri.tryParse(qrCode);

      if (uri == null ||
          uri.scheme != 'capsule' ||
          uri.host != 'friend-request') {
        state = state.copyWith(
          errorMessage:
              'Invalid QR code format. Please scan a valid friend request QR code.',
        );
        return;
      }

      final userId =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;

      if (userId == null || userId.isEmpty) {
        state = state.copyWith(
          errorMessage: 'Invalid user ID in QR code.',
        );
        return;
      }

      // Check if user is already a friend or has pending request
      final friendshipStatus =
          await _friendsService.getFriendshipStatus(userId);

      if (friendshipStatus == 'friends') {
        state = state.copyWith(
          errorMessage: 'You are already friends with this user.',
        );
        return;
      }

      if (friendshipStatus == 'pending_sent') {
        state = state.copyWith(
          errorMessage: 'Friend request already sent to this user.',
        );
        return;
      }

      if (friendshipStatus == 'pending_received') {
        state = state.copyWith(
          errorMessage:
              'This user has already sent you a friend request. Check your incoming requests.',
        );
        return;
      }

      // Send friend request - pass empty string as second parameter
      final success = await _friendsService.sendFriendRequest(userId, '');

      if (success) {
        state = state.copyWith(
          successMessage: 'Friend request sent successfully!',
        );

        // Refresh data to show the new sent request
        await _fetchAllFriendsData();
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to send friend request. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      state = state.copyWith(
        errorMessage: 'An error occurred while processing the QR code.',
      );
    }
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  Future<void> closeCamera() async {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController!.dispose();
      _cameraController = null;
    }

    state = state.copyWith(
      isCameraActive: false,
      cameraController: null,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}