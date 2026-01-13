// lib/presentation/report_story_screen/notifier/report_story_notifier.dart
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_story_model.dart';
import '../../../core/app_export.dart';

part 'report_story_state.dart';

final reportStoryNotifier =
StateNotifierProvider.autoDispose<ReportStoryNotifier, ReportStoryState>(
      (ref) => ReportStoryNotifier(
    ReportStoryState(
      reportStoryModel: ReportStoryModel(),
    ),
  ),
);

class ReportStoryNotifier extends StateNotifier<ReportStoryState> {
  ReportStoryNotifier(ReportStoryState state) : super(state) {
    _initialize();
  }

  final SupabaseClient _client = Supabase.instance.client;

  void _initialize() {
    state = state.copyWith(
      additionalDetailsController: TextEditingController(),
      isLoading: false,
      isSubmitted: false,
      errorMessage: null,
    );
  }

  /// Called by the sheet/widget when opening the report UI
  void setContext({
    required String storyId,
    required String reportedUserName,
    required String reportedUserId,
  }) {
    final updatedModel = (state.reportStoryModel ?? ReportStoryModel()).copyWith(
      storyId: storyId,
      reportedUser: reportedUserName,
      reportedUserId: reportedUserId,
      // NOTE: DO NOT set status here unless your model supports it.
      // Status is set at insert time.
    );

    state = state.copyWith(
      reportStoryModel: updatedModel,
      isSubmitted: false,
      errorMessage: null,
    );
  }

  void onReasonChanged(String? reason) {
    final updatedModel = (state.reportStoryModel ?? ReportStoryModel()).copyWith(
      selectedReason: reason,
    );

    state = state.copyWith(
      reportStoryModel: updatedModel,
      errorMessage: null,
    );
  }

  /// Maps UI reason (label or value) -> DB enum reason
  /// DB enum values:
  /// inappropriate | harassment | spam | violence | hate_speech | other
  String _mapReasonToDbEnum(String? uiReason) {
    if (uiReason == null || uiReason.isEmpty) return 'other';

    final value = uiReason.trim().toLowerCase();

    // Exact enum values
    switch (value) {
      case 'inappropriate':
      case 'harassment':
      case 'spam':
      case 'violence':
      case 'hate_speech':
      case 'other':
        return value;
    }

    // Label-based fallbacks
    if (value.contains('inappropriate')) return 'inappropriate';
    if (value.contains('harassment') || value.contains('bullying')) {
      return 'harassment';
    }
    if (value.contains('spam')) return 'spam';
    if (value.contains('violence') || value.contains('dangerous')) {
      return 'violence';
    }
    if (value.contains('hate')) return 'hate_speech';
    if (value.contains('other')) return 'other';

    return 'other';
  }

  String _generateCaseNumber() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final datePart = '$y$m$d';

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random.secure();
    final suffix =
    List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();

    return 'RPT-$datePart-$suffix';
  }

  Future<void> submitReport() async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      state = state.copyWith(
        errorMessage: 'You must be signed in to report a story.',
      );
      return;
    }

    final model = state.reportStoryModel;
    final storyId = model?.storyId;
    final rawReason = model?.selectedReason;

    if (storyId == null || storyId.isEmpty) {
      state = state.copyWith(errorMessage: 'Missing storyId.');
      return;
    }

    if (rawReason == null || rawReason.isEmpty) {
      state = state.copyWith(errorMessage: 'Please select a reason.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final reporterId = currentUser.id;
      final reason = _mapReasonToDbEnum(rawReason);
      final caseNumber = _generateCaseNumber();
      final details = state.additionalDetailsController?.text.trim();

      await _client.from('reports').insert({
        'story_id': storyId,
        'reporter_id': reporterId,
        'reason': reason,
        'case_number': caseNumber,
        'status': 'pending',
        'details': (details != null && details.isNotEmpty) ? details : null,
      });

      state = state.copyWith(
        isLoading: false,
        isSubmitted: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit report.',
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    state.additionalDetailsController?.dispose();
    super.dispose();
  }
}
