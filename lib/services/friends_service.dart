import '../core/app_export.dart';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsService {
  SupabaseClient? get _supabase => SupabaseService.instance.client;

  /// Fetches friends list for the current authenticated user
  Future<List<Map<String, dynamic>>> getUserFriends() async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Friends table is stored bidirectionally (two rows per friendship),
      // so we only need the "user_id = current user" direction.
      final response = await _supabase!.from('friends').select('''
            id,
            created_at,
            friend:friend_id (
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('user_id', userId);

      // Transform results with avatar URL conversion (fast path: public URL).
      return (response as List).map((item) {
        final friend = item['friend'];
        final avatarPath = friend['avatar_url'];
        String avatarUrl = '';

        if (avatarPath != null && avatarPath.isNotEmpty) {
          if (avatarPath.startsWith('http://') ||
              avatarPath.startsWith('https://')) {
            avatarUrl = avatarPath;
          } else {
            try {
              final cleanPath = avatarPath.startsWith('/')
                  ? avatarPath.substring(1)
                  : avatarPath;
              avatarUrl =
                  _supabase!.storage.from('avatars').getPublicUrl(cleanPath);
            } catch (e) {
              debugPrint('Error generating avatar URL: $e');
            }
          }
        }

        return {
          'id': friend['id'],
          'username': friend['username'],
          'display_name': friend['display_name'],
          'avatar_url': avatarUrl,
          'friendship_id': item['id'],
          'created_at': item['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching friends: $e');
      return [];
    }
  }

  /// Fetches sent friend requests for the current authenticated user
  Future<List<Map<String, dynamic>>> getSentFriendRequests() async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase!.from('friend_requests').select('''
            id,
            status,
            created_at,
            receiver:receiver_id (
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('sender_id', userId).eq('status', 'pending');

      return (response as List).map((item) {
        final receiver = item['receiver'];
        final avatarPath = receiver['avatar_url'];
        String avatarUrl = '';

        // ✅ USE getPublicUrl() for public avatars
        if (avatarPath != null && avatarPath.isNotEmpty) {
          if (avatarPath.startsWith('http://') ||
              avatarPath.startsWith('https://')) {
            avatarUrl = avatarPath;
          } else {
            try {
              final cleanPath = avatarPath.startsWith('/')
                  ? avatarPath.substring(1)
                  : avatarPath;
              avatarUrl =
                  _supabase!.storage.from('avatars').getPublicUrl(cleanPath);
            } catch (e) {
              debugPrint('Error generating avatar URL: $e');
            }
          }
        }

        return {
          'id': item['id'],
          'user_id': receiver['id'],
          'username': receiver['username'],
          'display_name': receiver['display_name'],
          'avatar_url': avatarUrl,
          'status': item['status'],
          'created_at': item['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching sent requests: $e');
      return [];
    }
  }

  /// Fetches incoming friend requests for the current authenticated user
  Future<List<Map<String, dynamic>>> getIncomingFriendRequests() async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase!.from('friend_requests').select('''
            id,
            status,
            created_at,
            sender:sender_id (
              id,
              username,
              display_name,
              avatar_url,
              bio
            )
          ''').eq('receiver_id', userId).eq('status', 'pending');

      return (response as List).map((item) {
        final sender = item['sender'];
        final avatarPath = sender['avatar_url'];
        String avatarUrl = '';

        // ✅ USE getPublicUrl() for public avatars
        if (avatarPath != null && avatarPath.isNotEmpty) {
          if (avatarPath.startsWith('http://') ||
              avatarPath.startsWith('https://')) {
            avatarUrl = avatarPath;
          } else {
            try {
              final cleanPath = avatarPath.startsWith('/')
                  ? avatarPath.substring(1)
                  : avatarPath;
              avatarUrl =
                  _supabase!.storage.from('avatars').getPublicUrl(cleanPath);
            } catch (e) {
              debugPrint('Error generating avatar URL: $e');
            }
          }
        }

        return {
          'id': item['id'],
          'user_id': sender['id'],
          'username': sender['username'],
          'display_name': sender['display_name'],
          'avatar_url': avatarUrl,
          'bio': sender['bio'],
          'status': item['status'],
          'created_at': item['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching incoming requests: $e');
      return [];
    }
  }

  /// Accepts a friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get the friend request details
      final request = await _supabase!
          .from('friend_requests')
          .select('sender_id, receiver_id')
          .eq('id', requestId)
          .eq('receiver_id', userId)
          .single();

      // Update friend request status to accepted
      await _supabase!.from('friend_requests').update({
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', requestId);

      // Create friendship entries (bidirectional)
      await _supabase!.from('friends').insert([
        {
          'user_id': request['sender_id'],
          'friend_id': request['receiver_id'],
        },
        {
          'user_id': request['receiver_id'],
          'friend_id': request['sender_id'],
        }
      ]);

      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return false;
    }
  }

  /// Declines a friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase!
          .from('friend_requests')
          .update({
            'status': 'declined',
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', requestId)
          .eq('receiver_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      return false;
    }
  }

  /// Cancels a sent friend request
  Future<bool> cancelSentRequest(String requestId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase!
          .from('friend_requests')
          .delete()
          .eq('id', requestId)
          .eq('sender_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error canceling sent request: $e');
      return false;
    }
  }

  /// Removes a friend (unfriend)
  Future<bool> removeFriend(String friendshipId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase!.from('friends').delete().eq('id', friendshipId);

      return true;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return false;
    }
  }

  /// Unfriends a user by their user ID (removes bidirectional friendship)
  Future<bool> unfriendUser(String currentUserId, String friendUserId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      // Delete both friendship records (bidirectional)
      await _supabase!.from('friends').delete().or(
          'and(user_id.eq.$currentUserId,friend_id.eq.$friendUserId),and(user_id.eq.$friendUserId,friend_id.eq.$currentUserId)');

      return true;
    } catch (e) {
      debugPrint('Error unfriending user: $e');
      return false;
    }
  }

  /// Checks if two users are friends
  /// NOTE: Since we store friendships bidirectionally (two rows),
  /// we must NOT use an OR + maybeSingle() (it can return 2 rows and throw).
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      if (_supabase == null) return false;

      final response = await _supabase!
          .from('friends')
          .select('id')
          .eq('user_id', userId1)
          .eq('friend_id', userId2)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking friendship: $e');
      return false;
    }
  }

  /// Checks if there's a pending friend request in either direction
  Future<bool> hasPendingRequest(String userId1, String userId2) async {
    try {
      if (_supabase == null) return false;

      final response = await _supabase!
          .from('friend_requests')
          .select('id')
          .or(
            'and(sender_id.eq.$userId1,receiver_id.eq.$userId2),and(sender_id.eq.$userId2,receiver_id.eq.$userId1)',
          )
          .eq('status', 'pending')
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      debugPrint('Error checking pending request: $e');
      return false;
    }
  }

  /// Sends a friend request
  Future<bool> sendFriendRequest(String senderId, String receiverId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      await _supabase!.from('friend_requests').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return false;
    }
  }

  /// Searches for all users in the database by username or display name
  Future<List<Map<String, dynamic>>> searchAllUsers(String query) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final currentUserId = _supabase!.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (query.isEmpty) {
        return [];
      }

      // Search users by username or display_name, excluding current user
      final response = await _supabase!
          .from('user_profiles')
          .select('id, username, display_name, avatar_url, bio')
          .neq('id', currentUserId)
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);

      // Transform results with proper avatar URL conversion
      return (response as List).map((user) {
        final avatarPath = user['avatar_url'];
        String avatarUrl = '';

        if (avatarPath != null && avatarPath.isNotEmpty) {
          if (avatarPath.startsWith('http://') ||
              avatarPath.startsWith('https://')) {
            avatarUrl = avatarPath;
          } else {
            try {
              final cleanPath = avatarPath.startsWith('/')
                  ? avatarPath.substring(1)
                  : avatarPath;
              avatarUrl =
                  _supabase!.storage.from('avatars').getPublicUrl(cleanPath);
            } catch (e) {
              debugPrint('Error generating avatar URL: $e');
            }
          }
        }

        return {
          'id': user['id'],
          'username': user['username'],
          'display_name': user['display_name'],
          'avatar_url': avatarUrl,
          'bio': user['bio'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Gets friendship status between current user and another user
  Future<String> getFriendshipStatus(String otherUserId) async {
    try {
      if (_supabase == null) return 'none';

      final currentUserId = _supabase!.auth.currentUser?.id;

      if (currentUserId == null) return 'none';

// Check if already friends (directional check, because friends table is bidirectional)
      final friendCheck = await _supabase!
          .from('friends')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('friend_id', otherUserId)
          .maybeSingle();

      if (friendCheck != null) return 'friends';

      // Check if pending request sent
      final sentRequestCheck = await _supabase!
          .from('friend_requests')
          .select('id')
          .eq('sender_id', currentUserId)
          .eq('receiver_id', otherUserId)
          .eq('status', 'pending')
          .maybeSingle();

      if (sentRequestCheck != null) return 'request_sent';

      // Check if pending request received
      final receivedRequestCheck = await _supabase!
          .from('friend_requests')
          .select('id')
          .eq('sender_id', otherUserId)
          .eq('receiver_id', currentUserId)
          .eq('status', 'pending')
          .maybeSingle();

      if (receivedRequestCheck != null) return 'request_received';

      return 'none';
    } catch (e) {
      debugPrint('Error checking friendship status: $e');
      return 'none';
    }
  }
}
