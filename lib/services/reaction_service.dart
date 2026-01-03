import 'package:supabase_flutter/supabase_flutter.dart';

class ReactionService {
  final _supabase = Supabase.instance.client;
  static const int maxTapsPerUser = 10;

  /// Add or update a reaction (upsert based on user + story + type)
  /// Max 10 taps per user per reaction type
  Future<bool> addReaction({
    required String storyId,
    required String reactionType,
    int tapCount = 1,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if reaction already exists
      final existing = await _supabase
          .from('reactions')
          .select()
          .eq('story_id', storyId)
          .eq('user_id', userId)
          .eq('reaction_type', reactionType)
          .maybeSingle();

      if (existing != null) {
        final currentTaps = (existing['tap_count'] ?? 0) as int;

        // Check if user has reached max taps
        if (currentTaps >= maxTapsPerUser) {
          print(
              '⚠️ Max taps ($maxTapsPerUser) reached for reaction $reactionType');
          return false; // Cannot add more taps
        }

        // Calculate new tap count (don't exceed max)
        final newTapCount = (currentTaps + tapCount).clamp(0, maxTapsPerUser);

        // Update tap count (increment)
        await _supabase.from('reactions').update({
          'tap_count': newTapCount,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);

        return true;
      } else {
        // Insert new reaction (ensure initial count doesn't exceed max)
        final initialCount = tapCount.clamp(1, maxTapsPerUser);
        await _supabase.from('reactions').insert({
          'story_id': storyId,
          'user_id': userId,
          'reaction_type': reactionType,
          'tap_count': initialCount,
        });
        return true;
      }
    } catch (e) {
      print('❌ ERROR adding reaction: $e');
      rethrow;
    }
  }

  /// Get all reactions for a story (grouped by type with counts)
  Future<Map<String, int>> getReactionCounts(String storyId) async {
    try {
      final response = await _supabase
          .from('reactions')
          .select('reaction_type, tap_count')
          .eq('story_id', storyId);

      final counts = <String, int>{};
      for (final row in response) {
        final type = row['reaction_type'] as String;
        final taps = (row['tap_count'] ?? 1) as int;
        counts[type] = (counts[type] ?? 0) + taps;
      }
      return counts;
    } catch (e) {
      print('❌ ERROR fetching reaction counts: $e');
      return {};
    }
  }

  /// Check if current user has reacted with a specific type
  Future<bool> hasUserReacted(String storyId, String reactionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('reactions')
          .select('id')
          .eq('story_id', storyId)
          .eq('user_id', userId)
          .eq('reaction_type', reactionType)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ ERROR checking user reaction: $e');
      return false;
    }
  }

  /// Get user's tap count for a specific reaction
  Future<int> getUserTapCount(String storyId, String reactionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _supabase
          .from('reactions')
          .select('tap_count')
          .eq('story_id', storyId)
          .eq('user_id', userId)
          .eq('reaction_type', reactionType)
          .maybeSingle();

      return (response?['tap_count'] ?? 0) as int;
    } catch (e) {
      print('❌ ERROR fetching user tap count: $e');
      return 0;
    }
  }

  /// Remove a reaction
  Future<void> removeReaction(String storyId, String reactionType) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('reactions')
          .delete()
          .eq('story_id', storyId)
          .eq('user_id', userId)
          .eq('reaction_type', reactionType);
    } catch (e) {
      print('❌ ERROR removing reaction: $e');
      rethrow;
    }
  }
}
