import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/daily_capsule_service.dart';
import './daily_capsule_state.dart';

final dailyCapsuleProvider =
    StateNotifierProvider.autoDispose<DailyCapsuleNotifier, DailyCapsuleState>(
  (ref) => DailyCapsuleNotifier(),
);

class DailyCapsuleNotifier extends StateNotifier<DailyCapsuleState> {
  DailyCapsuleNotifier() : super(const DailyCapsuleState(isLoading: true));

  final _svc = DailyCapsuleService.instance;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _svc.upsertSettingsIfNeeded();
    await refresh();
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final today = await _svc.fetchTodayEntry();
      final archive = await _svc.fetchArchive(limit: 60);

      final streak = _svc.computeStreakFromEntries(
        todayYmd: _svc.todayLocalDateYmd,
        entriesDesc: archive,
      );

      state = state.copyWith(
        isLoading: false,
        todayEntry: today,
        archiveEntries: archive,
        streakCount: streak,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> completeMood(String emoji) async {
    state = state.copyWith(isCompleting: true, errorMessage: null);
    try {
      await _svc.completeMood(emoji);
      await refresh();
    } finally {
      state = state.copyWith(isCompleting: false);
    }
  }
}

