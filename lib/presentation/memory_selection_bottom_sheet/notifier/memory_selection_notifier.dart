import 'package:flutter/foundation.dart';
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

  Map<String, dynamic> _asMapOrFirst(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is List && v.isNotEmpty && v.first is Map<String, dynamic>) {
      return v.first as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  String _norm(dynamic v) => (v ?? '').toString().trim().toLowerCase();

  /// Load active memories for current user
  Future<void> loadActiveMemories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final client = SupabaseService.instance.client;
      if (client == null) throw Exception('Supabase client not initialized');

      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('loadActiveMemories() called userId=$userId');

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

      final rows = (response as List);
      debugPrint('loadActiveMemories() response rows=${rows.length}');

      final memories = rows.map((item) {
        final memory = _asMapOrFirst(item['memories']);
        final category = _asMapOrFirst(memory['memory_categories']);

        final expiresAtRaw = memory['expires_at'];
        final DateTime expiresAt = expiresAtRaw is String
            ? DateTime.parse(expiresAtRaw)
            : (expiresAtRaw is DateTime ? expiresAtRaw : DateTime.now());

        final timeRemaining = _calculateTimeRemaining(expiresAt);

        final rawVis = memory['visibility'];
        final normVis = _norm(rawVis);

        debugPrint(
          'VIS CHECK title="${memory['title']}" rawVis="$rawVis" normVis="$normVis"',
        );

        return MemoryItem(
          id: memory['id'] as String?,
          title: memory['title'] as String?,
          categoryIcon: category['icon_url'] as String?,
          categoryName: category['name'] as String?,
          memberCount: memory['contributor_count'] is int
              ? memory['contributor_count'] as int
              : int.tryParse('${memory['contributor_count']}'),
          timeRemaining: timeRemaining,
          expiresAt: expiresAt,
          visibility: normVis, // canonical value used by UI
        );
      }).toList();

      state = state.copyWith(
        isLoading: false,
        activeMemories: memories,
        filteredMemories: memories,
      );
    } catch (e) {
      debugPrint('loadActiveMemories() ERROR: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load memories: ${e.toString()}',
        activeMemories: const [],
        filteredMemories: const [],
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

    final searchLower = query.toLowerCase();
    final filtered = (state.activeMemories ?? []).where((memory) {
      final title = memory.title?.toLowerCase() ?? '';
      final category = memory.categoryName?.toLowerCase() ?? '';
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

    if (difference.isNegative) return 'Expired';

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
