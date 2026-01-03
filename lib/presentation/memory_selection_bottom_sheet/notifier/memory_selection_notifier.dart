import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../models/memory_selection_model.dart';
import './memory_selection_state.dart';

final memorySelectionProvider =
    StateNotifierProvider<MemorySelectionNotifier, MemorySelectionState>(
  (ref) => MemorySelectionNotifier(),
);

class MemorySelectionNotifier extends StateNotifier<MemorySelectionState> {
  MemorySelectionNotifier() : super(MemorySelectionState.initial());

  /// Load active memories for current user
  Future<void> loadActiveMemories() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        throw Exception('Supabase client not initialized');
      }

      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch active memories where user is a contributor and memory is not sealed
      final response = await client
          .from('memory_contributors')
          .select('''
            memory_id,
            memories!inner(
              id,
              title,
              expires_at,
              state,
              contributor_count,
              visibility,
              memory_categories(
                name,
                icon_url
              )
            )
          ''')
          .eq('user_id', userId)
          .eq('memories.state', 'open')
          .order('memories.expires_at', ascending: true);

      final memories = (response as List).map((item) {
        final memory = item['memories'] as Map<String, dynamic>;
        final category =
            (memory['memory_categories'] as Map<String, dynamic>?) ?? {};
        final expiresAt = DateTime.parse(memory['expires_at'] as String);
        final timeRemaining = _calculateTimeRemaining(expiresAt);

        // Debug logging
        print(
            '🔍 DEBUG - Memory from DB: ${memory['title']}, visibility: ${memory['visibility']}');

        return MemoryItem(
          id: memory['id'] as String,
          title: memory['title'] as String?,
          categoryIcon: category['icon_url'] as String?,
          categoryName: category['name'] as String?,
          memberCount: memory['contributor_count'] as int?,
          timeRemaining: timeRemaining,
          expiresAt: expiresAt,
          visibility: memory['visibility'] as String?,
        );
      }).toList();

      print('🔍 DEBUG - Total memories loaded: ${memories.length}');
      print(
          '🔍 DEBUG - Visibility values: ${memories.map((m) => '${m.title}: ${m.visibility}').join(', ')}');

      state = MemorySelectionState(
        isLoading: false,
        activeMemories: memories,
        filteredMemories: memories,
      );
    } catch (e) {
      state = MemorySelectionState(
        isLoading: false,
        errorMessage: 'Failed to load memories: ${e.toString()}',
        activeMemories: [],
        filteredMemories: [],
      );
    }
  }

  /// Filter memories based on search query
  void filterMemories(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        filteredMemories: state.activeMemories,
        searchQuery: null,
      );
      return;
    }

    final filtered = state.activeMemories?.where((memory) {
      final title = memory.title?.toLowerCase() ?? '';
      final category = memory.categoryName?.toLowerCase() ?? '';
      final searchLower = query.toLowerCase();

      return title.contains(searchLower) || category.contains(searchLower);
    }).toList();

    state = state.copyWith(
      filteredMemories: filtered,
      searchQuery: query,
    );
  }

  /// Calculate human-readable time remaining
  String _calculateTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} left';
    } else {
      return 'Less than a minute';
    }
  }
}
