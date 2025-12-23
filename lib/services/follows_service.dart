import '../core/app_export.dart';
import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowsService {
  SupabaseClient? get _supabase => SupabaseService.instance.client;

  /// Checks if user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      if (_supabase == null) return false;

      final response = await _supabase!
          .from('follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  /// Follow a user
  Future<bool> followUser(String followerId, String followingId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      await _supabase!.from('follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
      });

      return true;
    } catch (e) {
      debugPrint('Error following user: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String followerId, String followingId) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase not initialized');
      }

      await _supabase!
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);

      return true;
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      return false;
    }
  }
}
