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

      // Get all friends where user is either user_id or friend_id
      final response1 = await _supabase!.from('friends').select('''
            id,
            created_at,
            friend:friend_id (
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('user_id', userId);

      final response2 = await _supabase!.from('friends').select('''
            id,
            created_at,
            friend:user_id (
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('friend_id', userId);

      // Combine and transform results with proper avatar URL conversion
      final friends1 = (response1 as List).map((item) {
        final friend = item['friend'];
        final avatarPath = friend['avatar_url'];
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
          'id': friend['id'],
          'username': friend['username'],
          'display_name': friend['display_name'],
          'avatar_url': avatarUrl,
          'friendship_id': item['id'],
          'created_at': item['created_at'],
        };
      }).toList();

      final friends2 = (response2 as List).map((item) {
        final friend = item['friend'];
        final avatarPath = friend['avatar_url'];
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
          'id': friend['id'],
          'username': friend['username'],
          'display_name': friend['display_name'],
          'avatar_url': avatarUrl,
          'friendship_id': item['id'],
          'created_at': item['created_at'],
        };
      }).toList();

      // Combine both lists
      final allFriends = [...friends1, ...friends2];

      // Deduplicate based on friend user ID to avoid showing same friend twice
      final Map<String, Map<String, dynamic>> uniqueFriends = {};
      for (var friend in allFriends) {
        final friendId = friend['id'] as String;
        if (!uniqueFriends.containsKey(friendId)) {
          uniqueFriends[friendId] = friend;
        }
      }

      return uniqueFriends.values.toList();
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

  /// Checks if two users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      if (_supabase == null) return false;

      final response = await _supabase!
          .from('friends')
          .select('id')
          .or('and(user_id.eq.$userId1,friend_id.eq.$userId2),and(user_id.eq.$userId2,friend_id.eq.$userId1)')
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking friendship: $e');
      return false;
    }
  }

  /// Checks if there's a pending friend request
  Future<bool> hasPendingRequest(String senderId, String receiverId) async {
    try {
      if (_supabase == null) return false;

      final response = await _supabase!
          .from('friend_requests')
          .select('id')
          .eq('sender_id', senderId)
          .eq('receiver_id', receiverId)
          .eq('status', 'pending')
          .maybeSingle();

      return response != null;
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
}
