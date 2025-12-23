import '../core/app_export.dart';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockedUsersService {
  SupabaseClient? get _supabase => SupabaseService.instance.client;

  /// Blocks a user
  Future<bool> blockUser(String blockedUserId, {String? reason}) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase!.from('blocked_users').insert({
        'blocker_id': userId,
        'blocked_id': blockedUserId,
        'reason': reason,
      });

      return true;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  /// Unblocks a user
  Future<bool> unblockUser(String blockedUserId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase!
          .from('blocked_users')
          .delete()
          .eq('blocker_id', userId)
          .eq('blocked_id', blockedUserId);

      return true;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  /// Checks if a user is blocked
  Future<bool> isUserBlocked(String targetUserId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        return false;
      }

      final response = await _supabase!
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', userId)
          .eq('blocked_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Gets list of blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      final userId = _supabase!.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase!.from('blocked_users').select('''
            id,
            created_at,
            reason,
            blocked:blocked_id (
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('blocker_id', userId);

      return (response as List).map((item) {
        final blocked = item['blocked'];
        final avatarPath = blocked['avatar_url'];
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
          'block_id': item['id'],
          'user_id': blocked['id'],
          'username': blocked['username'],
          'display_name': blocked['display_name'],
          'avatar_url': avatarUrl,
          'reason': item['reason'],
          'created_at': item['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching blocked users: $e');
      return [];
    }
  }
}
