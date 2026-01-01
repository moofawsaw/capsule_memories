import 'dart:async';

import '../core/app_export.dart';
import './friends_service.dart';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendItem {
  final String id;
  final String userName;
  final String? displayName;
  final String? profileImagePath;
  final String? friendshipId;

  FriendItem({
    required this.id,
    required this.userName,
    this.displayName,
    this.profileImagePath,
    this.friendshipId,
  });

  factory FriendItem.fromMap(Map<String, dynamic> map) {
    return FriendItem(
      id: map['id'] ?? '',
      userName: map['username'] ?? '',
      displayName: map['display_name'],
      profileImagePath: map['avatar_url'],
      friendshipId: map['friendship_id'],
    );
  }
}

class FriendRequestItem {
  final String id;
  final String userId;
  final String userName;
  final String? displayName;
  final String? profileImagePath;
  final String? bio;
  final String status;
  final String createdAt;

  FriendRequestItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.displayName,
    this.profileImagePath,
    this.bio,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestItem.fromMap(Map<String, dynamic> map) {
    return FriendRequestItem(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['username'] ?? '',
      displayName: map['display_name'],
      profileImagePath: map['avatar_url'],
      bio: map['bio'],
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] ?? '',
    );
  }
}

class SearchResultItem {
  final String id;
  final String userName;
  final String? displayName;
  final String? profileImagePath;
  final String? bio;

  SearchResultItem({
    required this.id,
    required this.userName,
    this.displayName,
    this.profileImagePath,
    this.bio,
  });

  factory SearchResultItem.fromMap(Map<String, dynamic> map) {
    return SearchResultItem(
      id: map['id'] ?? '',
      userName: map['username'] ?? '',
      displayName: map['display_name'],
      profileImagePath: map['avatar_url'],
      bio: map['bio'],
    );
  }
}

/// Centralized friends data provider - manages all friend-related state
class FriendsDataProvider {
  static final FriendsDataProvider _instance = FriendsDataProvider._internal();
  factory FriendsDataProvider() => _instance;
  FriendsDataProvider._internal();

  final FriendsService _friendsService = FriendsService();

  // Stream controllers for real-time updates
  final _friendsController = StreamController<List<FriendItem>>.broadcast();
  final _incomingRequestsController =
      StreamController<List<FriendRequestItem>>.broadcast();
  final _sentRequestsController =
      StreamController<List<FriendRequestItem>>.broadcast();

  // Getters for streams
  Stream<List<FriendItem>> get friendsStream => _friendsController.stream;
  Stream<List<FriendRequestItem>> get incomingRequestsStream =>
      _incomingRequestsController.stream;
  Stream<List<FriendRequestItem>> get sentRequestsStream =>
      _sentRequestsController.stream;

  // Current state
  List<FriendItem> _currentFriends = [];
  List<FriendRequestItem> _currentIncomingRequests = [];
  List<FriendRequestItem> _currentSentRequests = [];

  // Getters for current state
  List<FriendItem> get currentFriends => _currentFriends;
  List<FriendRequestItem> get currentIncomingRequests =>
      _currentIncomingRequests;
  List<FriendRequestItem> get currentSentRequests => _currentSentRequests;

  /// Initialize real-time subscription
  void initialize() {
    _setupRealtimeSubscription();
    refreshAllData();
  }

  /// Fetch all friends data
  Future<void> refreshAllData() async {
    await Future.wait([
      _refreshFriends(),
      _refreshIncomingRequests(),
      _refreshSentRequests(),
    ]);
  }

  /// Fetch friends list
  Future<void> _refreshFriends() async {
    try {
      final friendsData = await _friendsService.getUserFriends();
      _currentFriends = friendsData.map((f) => FriendItem.fromMap(f)).toList();
      _friendsController.add(_currentFriends);
    } catch (e) {
      debugPrint('Error refreshing friends: $e');
    }
  }

  /// Fetch incoming requests
  Future<void> _refreshIncomingRequests() async {
    try {
      final requestsData = await _friendsService.getIncomingFriendRequests();
      _currentIncomingRequests =
          requestsData.map((r) => FriendRequestItem.fromMap(r)).toList();
      _incomingRequestsController.add(_currentIncomingRequests);
    } catch (e) {
      debugPrint('Error refreshing incoming requests: $e');
    }
  }

  /// Fetch sent requests
  Future<void> _refreshSentRequests() async {
    try {
      final requestsData = await _friendsService.getSentFriendRequests();
      _currentSentRequests =
          requestsData.map((r) => FriendRequestItem.fromMap(r)).toList();
      _sentRequestsController.add(_currentSentRequests);
    } catch (e) {
      debugPrint('Error refreshing sent requests: $e');
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    final success = await _friendsService.acceptFriendRequest(requestId);
    if (success) {
      await refreshAllData();
    }
    return success;
  }

  /// Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    final success = await _friendsService.declineFriendRequest(requestId);
    if (success) {
      await refreshAllData();
    }
    return success;
  }

  /// Cancel sent request
  Future<bool> cancelSentRequest(String requestId) async {
    final success = await _friendsService.cancelSentRequest(requestId);
    if (success) {
      await refreshAllData();
    }
    return success;
  }

  /// Remove friend
  Future<bool> removeFriend(String friendshipId) async {
    final success = await _friendsService.removeFriend(friendshipId);
    if (success) {
      await refreshAllData();
    }
    return success;
  }

  /// Setup real-time subscription to friends table
  void _setupRealtimeSubscription() {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    // Listen to friends table changes
    client
        .channel('friends_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friends',
          callback: (payload) {
            debugPrint('Friends table changed: ${payload.eventType}');
            _refreshFriends();
          },
        )
        .subscribe();

    // Listen to friend_requests table changes
    client
        .channel('friend_requests_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friend_requests',
          callback: (payload) {
            debugPrint('Friend requests table changed: ${payload.eventType}');
            _refreshIncomingRequests();
            _refreshSentRequests();
          },
        )
        .subscribe();
  }

  /// Dispose streams
  void dispose() {
    _friendsController.close();
    _incomingRequestsController.close();
    _sentRequestsController.close();
  }
}