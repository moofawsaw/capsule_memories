// lib/presentation/friends_management_screen/notifier/friends_management_notifier.dart

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_export.dart';
import '../../../services/friends_data_provider.dart';
import '../../../services/supabase_service.dart';
import '../models/friends_management_model.dart';
import 'friends_management_state.dart';

final friendsManagementNotifier =
NotifierProvider.autoDispose<FriendsManagementNotifier, FriendsManagementState>(
      () => FriendsManagementNotifier(),
);

class FriendsManagementNotifier extends AutoDisposeNotifier<FriendsManagementState> {
  final FriendsDataProvider _friendsProvider = FriendsDataProvider();
  final FriendsDataProvider _friendsService = FriendsDataProvider();

  StreamSubscription<List<FriendItem>>? _friendsSubscription;
  StreamSubscription<List<FriendRequestItem>>? _incomingRequestsSubscription;
  StreamSubscription<List<FriendRequestItem>>? _sentRequestsSubscription;

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  CameraController? _cameraController;
  bool _didInit = false;

  @override
  FriendsManagementState build() {
    if (!_didInit) {
      _didInit = true;
      initialize();

      // Keep listener approach (you can remove onChanged in the widget if you want)
      searchController.addListener(_onSearchTextChanged);
    }

    ref.onDispose(() async {
      _debounce?.cancel();

      searchController.removeListener(_onSearchTextChanged);
      searchController.dispose();

      await _friendsSubscription?.cancel();
      await _incomingRequestsSubscription?.cancel();
      await _sentRequestsSubscription?.cancel();

      await closeCamera();
    });

    return const FriendsManagementState();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      _friendsProvider.initialize();

      // Friends
      await _friendsSubscription?.cancel();
      _friendsSubscription = _friendsProvider.friendsStream.listen((friends) {
        final list = friends
            .map(
              (f) => FriendModel(
            id: f.id,
            userName: f.userName,
            displayName: f.displayName,
            profileImagePath: f.profileImagePath,
            friendshipId: f.friendshipId,
          ),
        )
            .toList();

        state = state.copyWith(
          friendsList: list,
          filteredFriendsList: list,
        );
      });

      // Incoming requests
      await _incomingRequestsSubscription?.cancel();
      _incomingRequestsSubscription =
          _friendsProvider.incomingRequestsStream.listen((requests) {
            final list = requests
                .map(
                  (r) => IncomingRequestModel(
                id: r.id,
                userId: r.userId,
                userName: r.userName,
                displayName: r.displayName,
                profileImagePath: r.profileImagePath,
                bio: r.bio,
              ),
            )
                .toList();

            state = state.copyWith(
              incomingRequestsList: list,
              filteredIncomingRequestsList: list,
            );
          });

      // Sent requests
      await _sentRequestsSubscription?.cancel();
      _sentRequestsSubscription = _friendsProvider.sentRequestsStream.listen((requests) {
        final list = requests
            .map(
              (r) => SentRequestModel(
            id: r.id,
            userId: r.userId,
            userName: r.userName,
            displayName: r.displayName,
            profileImagePath: r.profileImagePath,
            status: r.status,
          ),
        )
            .toList();

        state = state.copyWith(
          sentRequestsList: list,
          filteredSentRequestsList: list,
        );
      });

      state = state.copyWith(isLoading: false);

      // If user already typed something, rerun search
      final q = state.searchQuery.trim();
      if (q.isNotEmpty) {
        await _searchUsersSmart(q);
      }
    } catch (e) {
      debugPrint('Error initializing friends data: $e');
      state = state.copyWith(
        errorMessage: 'Failed to initialize friends data',
        isLoading: false,
      );
    }
  }

  void _onSearchTextChanged() {
    onSearchChanged(searchController.text);
  }

  // ✅ Search ONLY for new users (does NOT filter friends / requests)
  void onSearchChanged(String query) {
    state = state.copyWith(searchQuery: query);

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _debounce?.cancel();
      state = state.copyWith(
        searchResults: const [],
        isSearching: false,
      );
      return;
    }

    _debounce?.cancel();
    state = state.copyWith(isSearching: true);

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      await _searchUsersSmart(trimmed);
    });
  }

  Future<void> _searchUsersSmart(String query) async {
    final snapshotQuery = query.trim();
    state = state.copyWith(isSearching: true);

    try {
      final client = SupabaseService.instance.client;
      final currentUser = client?.auth.currentUser;

      if (client == null || currentUser == null) {
        state = state.copyWith(isSearching: false, searchResults: const []);
        return;
      }

      // ✅ Correct, single param map matching the NEW SQL signature
      final res = await client.rpc('search_users_smart', params: {
        'p_query': snapshotQuery,
        'p_limit': 10,
        'p_user_id': currentUser.id,
      });

      if (res is! List) {
        debugPrint('search_users_smart unexpected return type: ${res.runtimeType}');
        if (state.searchQuery.trim() == snapshotQuery) {
          state = state.copyWith(isSearching: false, searchResults: const []);
        }
        return;
      }

      // If user typed more while waiting, ignore stale results
      if (state.searchQuery.trim() != snapshotQuery) return;

      final rows = res.cast<dynamic>();

      final results = rows.map((r) {
        final m = (r as Map).cast<String, dynamic>();

        final id = (m['id'] ?? '').toString();
        final username = (m['username'] ?? '').toString();
        final displayName = (m['display_name'] ?? '').toString();
        final avatarUrl = (m['avatar_url'] ?? '').toString();

        // ✅ NEW SQL returns booleans (not friendship_status string)
        final isFriend = m['is_friend'] == true;
        final isPending = m['is_pending'] == true;

        final status = isFriend
            ? 'friends'
            : (isPending ? 'pending' : 'none');

        return SearchUserModel(
          id: id,
          userName: username,
          displayName: displayName.isNotEmpty ? displayName : username,
          profileImagePath: avatarUrl,
          bio: '', // not returned by this function
          friendshipStatus: status,
        );
      }).toList();

      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } catch (e) {
      debugPrint('Error searching users (smart): $e');
      if (state.searchQuery.trim() == snapshotQuery) {
        state = state.copyWith(
          errorMessage: 'Failed to search users',
          isSearching: false,
          searchResults: const [],
        );
      }
    }
  }

  // ✅ Optimistic update from UI
  void updateSearchUserStatus(String userId, String status) {
    final current = state.searchResults;
    final updated = current.map((u) {
      if ((u.id ?? '') == userId) {
        return u.copyWith(friendshipStatus: status);
      }
      return u;
    }).toList();

    state = state.copyWith(searchResults: updated);
  }

  // ✅ Called when tapping "Add Friend"
  Future<void> sendFriendRequest(String targetUserId) async {
    try {
      if (targetUserId.trim().isEmpty) return;

      final success = await _friendsService.addFriendRequest(targetUserId, '');

      if (success) {
        updateSearchUserStatus(targetUserId, 'pending');

        // Ensure Sent Requests updates quickly (if your provider supports it)
        try {
          await _friendsProvider.refreshAllData();
        } catch (_) {
          // ignore if refreshAllData doesn't exist
        }
      } else {
        state = state.copyWith(errorMessage: 'Failed to send friend request');
      }
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      state = state.copyWith(errorMessage: 'Failed to send friend request');
    }
  }

  Future<void> onRemoveSentRequest(String requestId) async {
    try {
      final success = await _friendsService.cancelSentRequest(requestId);

      if (success) {
        final updated = state.filteredSentRequestsList
            .where((request) => request.id != requestId)
            .toList();

        state = state.copyWith(
          sentRequestsList: updated,
          filteredSentRequestsList: updated,
        );
      }
    } catch (e) {
      debugPrint('Error removing sent request: $e');
      state = state.copyWith(errorMessage: 'Failed to cancel request');
    }
  }

  Future<void> onAcceptIncomingRequest(String requestId) async {
    try {
      final success = await _friendsService.acceptFriendRequest(requestId);
      if (success) {
        await initialize();
      }
    } catch (e) {
      debugPrint('Error accepting request: $e');
      state = state.copyWith(errorMessage: 'Failed to accept request');
    }
  }

  Future<void> onDeclineIncomingRequest(String requestId) async {
    try {
      final success = await _friendsService.declineFriendRequest(requestId);

      if (success) {
        final updated = state.filteredIncomingRequestsList
            .where((request) => request.id != requestId)
            .toList();

        state = state.copyWith(
          incomingRequestsList: updated,
          filteredIncomingRequestsList: updated,
        );
      }
    } catch (e) {
      debugPrint('Error declining request: $e');
      state = state.copyWith(errorMessage: 'Failed to decline request');
    }
  }

  Future<void> onRemoveFriend(String friendshipId) async {
    try {
      final success = await _friendsService.removeFriend(friendshipId);

      if (success) {
        final updated = state.filteredFriendsList
            .where((friend) => friend.friendshipId != friendshipId)
            .toList();

        state = state.copyWith(
          friendsList: updated,
          filteredFriendsList: updated,
        );
      }
    } catch (e) {
      debugPrint('Error removing friend: $e');
      state = state.copyWith(errorMessage: 'Failed to remove friend');
    }
  }

  Future<void> onQRScanTap() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        state = state.copyWith(isQRScannerActive: true);
      } else {
        state = state.copyWith(
          errorMessage: 'Camera permission is required for QR scanning',
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to open QR scanner');
    }
  }

  Future<void> onCameraTap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAskedBefore = prefs.getBool('camera_permission_asked') ?? false;

      PermissionStatus cameraStatus = await Permission.camera.status;

      if (cameraStatus.isDenied && !hasAskedBefore) {
        cameraStatus = await Permission.camera.request();
        await prefs.setBool('camera_permission_asked', true);

        if (cameraStatus.isGranted) {
          await prefs.setBool('camera_permission_granted', true);
        } else if (cameraStatus.isPermanentlyDenied) {
          await prefs.setBool('camera_permission_permanently_denied', true);
        }
      } else if (cameraStatus.isDenied) {
        cameraStatus = await Permission.camera.request();

        if (cameraStatus.isGranted) {
          await prefs.setBool('camera_permission_granted', true);
          await prefs.setBool('camera_permission_permanently_denied', false);
        } else if (cameraStatus.isPermanentlyDenied) {
          await prefs.setBool('camera_permission_permanently_denied', true);
        }
      }

      if (cameraStatus.isGranted) {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          state = state.copyWith(errorMessage: 'No cameras available on this device');
          return;
        }

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

        state = state.copyWith(isCameraActive: true);
      } else if (cameraStatus.isPermanentlyDenied) {
        state = state.copyWith(
          errorMessage:
          'Camera permission is required for scanning. Please enable it in app settings.',
        );
      } else {
        state = state.copyWith(
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

  Future<void> openDeviceAppSettings() async {
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

    state = state.copyWith(isCameraActive: false);
  }
}
