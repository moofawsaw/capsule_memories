part of 'report_story_notifier.dart';

class ReportStoryState extends Equatable {
  final TextEditingController? additionalDetailsController;
  final bool? isLoading;
  final bool? isSubmitted;
  final String? errorMessage;
  final ReportStoryModel? reportStoryModel;

  const ReportStoryState({
    this.additionalDetailsController,
    this.isLoading = false,
    this.isSubmitted = false,
    this.errorMessage,
    this.reportStoryModel,
  });

  @override
  List<Object?> get props => [
    additionalDetailsController,
    isLoading,
    isSubmitted,
    errorMessage,
    reportStoryModel,
  ];

  ReportStoryState copyWith({
    TextEditingController? additionalDetailsController,
    bool? isLoading,
    bool? isSubmitted,
    String? errorMessage,
    ReportStoryModel? reportStoryModel,
  }) {
    return ReportStoryState(
      additionalDetailsController:
      additionalDetailsController ?? this.additionalDetailsController,
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: errorMessage,
      reportStoryModel: reportStoryModel ?? this.reportStoryModel,
    );
  }
}
