part of 'report_story_notifier.dart';

class ReportStoryState extends Equatable {
  final TextEditingController? additionalDetailsController;
  final bool? isLoading;
  final bool? isSubmitted;
  final ReportStoryModel? reportStoryModel;

  ReportStoryState({
    this.additionalDetailsController,
    this.isLoading = false,
    this.isSubmitted = false,
    this.reportStoryModel,
  });

  @override
  List<Object?> get props => [
        additionalDetailsController,
        isLoading,
        isSubmitted,
        reportStoryModel,
      ];

  ReportStoryState copyWith({
    TextEditingController? additionalDetailsController,
    bool? isLoading,
    bool? isSubmitted,
    ReportStoryModel? reportStoryModel,
  }) {
    return ReportStoryState(
      additionalDetailsController:
          additionalDetailsController ?? this.additionalDetailsController,
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      reportStoryModel: reportStoryModel ?? this.reportStoryModel,
    );
  }
}
