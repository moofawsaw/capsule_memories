import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_export.dart';
import '../../../services/friends_data_provider.dart';
import '../models/friends_management_model.dart';
import './friends_management_state.dart';

final friendsManagementNotifier = NotifierProvider.autoDispose<
    FriendsManagementNotifier, FriendsManagementState>(
  () => FriendsManagementNotifier(),
);

class FriendsManagementNotifier
    extends AutoDisposeNotifier<FriendsManagementState> {
  final FriendsDataProvider _friendsProvider = FriendsDataProvider();
  final FriendsDataProvider _friendsService = FriendsDataProvider();
  StreamSubscription<List<FriendItem>>? _friendsSubscription;
  StreamSubscription<List<FriendRequestItem>>? _incomingRequestsSubscription;
  StreamSubscription<List<FriendRequestItem>>? _sentRequestsSubscription;

  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  CameraController? _cameraController;

  @override
  FriendsManagementState build() {
    initialize();
    searchController.addListener(_onSearchTextChanged);
    return FriendsManagementState(
      friendsManagementModel: FriendsManagementModel(),
    );
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Initialize friends data provider with real-time subscriptions
      _friendsProvider.initialize();

      // Subscribe to friends stream
      _friendsSubscription = _friendsProvider.friendsStream.listen((friends) {
        final friendsList = friends
            .map((f) => FriendModel(
                  id: f.id,
                  userName: f.userName,
                  displayName: f.displayName,
                  profileImagePath: f.profileImagePath,
                  friendshipId: f.friendshipId,
                ))
            .toList();

        state = state.copyWith(
          friendsManagementModel: state.friendsManagementModel?.copyWith(
            friendsList: friendsList.cast<FriendModel>(),
          ),
        );
      });

      // Subscribe to incoming requests stream
      _incomingRequestsSubscription =
          _friendsProvider.incomingRequestsStream.listen((requests) {
        final incomingRequests = requests
            .map((r) => IncomingRequestModel(
                  id: r.id,
                  userId: r.userId,
                  userName: r.userName,
                  displayName: r.displayName,
                  profileImagePath: r.profileImagePath,
                  bio: r.bio,
                ))
            .toList();

        state = state.copyWith(
          friendsManagementModel: state.friendsManagementModel?.copyWith(
            incomingRequestsList: incomingRequests.cast<IncomingRequestModel>(),
          ),
        );
      });

      // Subscribe to sent requests stream
      _sentRequestsSubscription =
          _friendsProvider.sentRequestsStream.listen((requests) {
        final sentRequests = requests
            .map((r) => SentRequestModel(
                  id: r.id,
                  userId: r.userId,
                  userName: r.userName,
                  displayName: r.displayName,
                  profileImagePath: r.profileImagePath,
                  status: r.status,
                ))
            .toList();

        state = state.copyWith(
          friendsManagementModel: state.friendsManagementModel?.copyWith(
            sentRequestsList: sentRequests.cast<SentRequestModel>(),
          ),
        );
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error initializing friends data: $e');
      state = state.copyWith(
        errorMessage: 'Failed to initialize friends data',
        isLoading: false,
      );
    }
  }

  void _onSearchTextChanged() {
    final query = searchController.text;
    onSearchChanged(query);
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

      final usersData = await _friendsService.searchUsers(query);

      // Get friendship status for each user
      final searchResults = await Future.wait(
        usersData.map((user) async {
          final status =
              await _friendsService.checkFriendshipStatus(user['id']);
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
        searchResults: searchResults.cast<SearchUserModel>(),
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
        await initialize();
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

  Future<Map<String, dynamic>> processScannedQRCode(String qrCode) async {
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
        return {
          'success': false,
          'message':
              'Invalid QR code format. Please scan a valid friend request QR code.',
          'type': 'error'
        };
      }

      final userId =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;

      if (userId == null || userId.isEmpty) {
        state = state.copyWith(
          errorMessage: 'Invalid user ID in QR code.',
        );
        return {
          'success': false,
          'message': 'Invalid user ID in QR code.',
          'type': 'error'
        };
      }

      // Check if user is already a friend or has pending request
      final friendshipStatus =
          await _friendsService.checkFriendshipStatus(userId);

      if (friendshipStatus == 'friends') {
        state = state.copyWith(
          errorMessage: 'You are already friends with this user.',
        );
        return {
          'success': false,
          'message': 'You are already friends with this user.',
          'type': 'error'
        };
      }

      if (friendshipStatus == 'pending_sent') {
        state = state.copyWith(
          errorMessage: 'Friend request already sent to this user.',
        );
        return {
          'success': false,
          'message': 'Friend request already sent to this user.',
          'type': 'error'
        };
      }

      if (friendshipStatus == 'pending_received') {
        state = state.copyWith(
          errorMessage:
              'This user has already sent you a friend request. Check your incoming requests.',
        );
        return {
          'success': false,
          'message':
              'This user has already sent you a friend request. Check your incoming requests.',
          'type': 'error'
        };
      }

      // Get the user's display name for the success message
      final userData = await _friendsService.searchUsers('');
      final targetUser = userData.firstWhere(
        (user) => user['id'] == userId,
        orElse: () => {'display_name': 'user'},
      );
      final displayName =
          targetUser['display_name'] ?? targetUser['username'] ?? 'user';

      // Send friend request - pass empty string as second parameter
      final success = await _friendsService.addFriendRequest(userId, '');

      if (success) {
        final successMessage =
            'Success! You have added $displayName as a friend';

        state = state.copyWith(
          successMessage: successMessage,
        );

        // Explicitly refresh all friends data to show the new sent request
        await _friendsProvider.refreshAllData();

        // Also reinitialize to ensure real-time subscriptions are active
        await initialize();

        return {'success': true, 'message': successMessage, 'type': 'friend'};
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to send friend request. Please try again.',
        );
        return {
          'success': false,
          'message': 'Failed to send friend request. Please try again.',
          'type': 'error'
        };
      }
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      state = state.copyWith(
        errorMessage: 'An error occurred while processing the QR code.',
      );
      return {
        'success': false,
        'message': 'An error occurred while processing the QR code.',
        'type': 'error'
      };
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
}
