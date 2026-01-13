import '../../../core/app_export.dart';

/// This class is used in the [ReportStoryScreen] screen.
// ignore_for_file: must_be_immutable
class ReportStoryModel extends Equatable {
  ReportStoryModel({
    this.storyId,
    this.selectedReason,
    this.additionalDetails,
    this.reportedUser,
    this.reportedUserId,
  });

  final String? storyId;
  final String? selectedReason;
  final String? additionalDetails;
  final String? reportedUser;
  final String? reportedUserId;

  ReportStoryModel copyWith({
    String? storyId,
    String? selectedReason,
    String? additionalDetails,
    String? reportedUser,
    String? reportedUserId,
  }) {
    return ReportStoryModel(
      storyId: storyId ?? this.storyId,
      selectedReason: selectedReason ?? this.selectedReason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      reportedUser: reportedUser ?? this.reportedUser,
      reportedUserId: reportedUserId ?? this.reportedUserId,
    );
  }

  @override
  List<Object?> get props => [
    storyId,
    selectedReason,
    additionalDetails,
    reportedUser,
    reportedUserId,
  ];
}

