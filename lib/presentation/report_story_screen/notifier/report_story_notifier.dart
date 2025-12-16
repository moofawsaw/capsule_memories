import 'package:flutter/material.dart';
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
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      additionalDetailsController: TextEditingController(),
      isLoading: false,
      isSubmitted: false,
    );
  }

  void onReasonChanged(String? reason) {
    final updatedModel = state.reportStoryModel?.copyWith(
      selectedReason: reason,
    );

    state = state.copyWith(
      reportStoryModel: updatedModel,
    );
  }

  void submitReport() {
    if (state.reportStoryModel?.selectedReason == null) {
      return;
    }

    state = state.copyWith(isLoading: true);

    // Simulate API call
    Future.delayed(Duration(milliseconds: 1500), () {
      final updatedModel = state.reportStoryModel?.copyWith(
        additionalDetails: state.additionalDetailsController?.text ?? '',
        reportedUser: 'Sarah Smith',
      );

      state = state.copyWith(
        reportStoryModel: updatedModel,
        isLoading: false,
        isSubmitted: true,
      );

      // Clear form after successful submission
      state.additionalDetailsController?.clear();
      final clearedModel = state.reportStoryModel?.copyWith(
        selectedReason: null,
        additionalDetails: '',
      );

      state = state.copyWith(
        reportStoryModel: clearedModel,
      );
    });
  }

  @override
  void dispose() {
    state.additionalDetailsController?.dispose();
    super.dispose();
  }
}
