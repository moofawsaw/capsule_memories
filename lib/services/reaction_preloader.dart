import 'dart:async';

import './reaction_service.dart';

class ReactionSnapshot {
  final Map<String, int> counts;
  final Map<String, int> userTapCounts;
  final DateTime fetchedAt;

  const ReactionSnapshot({
    required this.counts,
    required this.userTapCounts,
    required this.fetchedAt,
  });
}

class ReactionPreloader {
  ReactionPreloader._internal();
  static final ReactionPreloader instance = ReactionPreloader._internal();

  // Cache + in-flight dedupe
  final Map<String, ReactionSnapshot> _cache = {};
  final Map<String, Future<ReactionSnapshot>> _inflight = {};

  // Tune this: how long you trust cached reactions before refreshing.
  static const Duration ttl = Duration(minutes: 2);

  ReactionSnapshot? getCached(String storyId) {
    final snap = _cache[storyId];
    if (snap == null) return null;

    final isFresh = DateTime.now().difference(snap.fetchedAt) <= ttl;
    return isFresh ? snap : snap; // still return stale; caller may revalidate
  }

  bool hasFresh(String storyId) {
    final snap = _cache[storyId];
    if (snap == null) return false;
    return DateTime.now().difference(snap.fetchedAt) <= ttl;
  }

  /// Preload without awaiting (fire-and-forget).
  void preload(String storyId) {
    // If already fetching or fresh, skip.
    if (_inflight.containsKey(storyId)) return;
    if (hasFresh(storyId)) return;

    // Kick off and ignore result.
    unawaited(fetch(storyId));
  }

  /// Force refresh.
  Future<ReactionSnapshot> refresh(String storyId) async {
    _cache.remove(storyId);
    return fetch(storyId);
  }

  /// Fetch with in-flight dedupe.
  Future<ReactionSnapshot> fetch(String storyId) {
    final existing = _inflight[storyId];
    if (existing != null) return existing;

    final future = _fetchInternal(storyId);
    _inflight[storyId] = future;

    future.whenComplete(() {
      _inflight.remove(storyId);
    });

    return future;
  }

  Future<ReactionSnapshot> _fetchInternal(String storyId) async {
    final service = ReactionService();
    final result = await service.getReactionSnapshot(storyId);

    final snap = ReactionSnapshot(
      counts: result.counts,
      userTapCounts: result.userTapCounts,
      fetchedAt: DateTime.now(),
    );

    _cache[storyId] = snap;
    return snap;
  }

  /// Use when you optimistically update counts in the widget and want cache aligned.
  void upsertLocal({
    required String storyId,
    required String reactionType,
    required int deltaTotal,
    required int deltaUser,
  }) {
    final existing = _cache[storyId];
    final counts = Map<String, int>.from(existing?.counts ?? {});
    final userTaps = Map<String, int>.from(existing?.userTapCounts ?? {});

    counts[reactionType] = (counts[reactionType] ?? 0) + deltaTotal;
    userTaps[reactionType] = (userTaps[reactionType] ?? 0) + deltaUser;

    _cache[storyId] = ReactionSnapshot(
      counts: counts,
      userTapCounts: userTaps,
      fetchedAt: existing?.fetchedAt ?? DateTime.now(),
    );
  }

  void clearStory(String storyId) {
    _cache.remove(storyId);
    _inflight.remove(storyId);
  }

  void clearAll() {
    _cache.clear();
    _inflight.clear();
  }
}
