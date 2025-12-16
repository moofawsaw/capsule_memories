import '../../../core/app_export.dart';

/// This class is used in the [ReportStoryScreen] screen.

// ignore_for_file: must_be_immutable
class ReportStoryModel extends Equatable {
  ReportStoryModel({
    this.selectedReason,
    this.additionalDetails,
    this.reportedUser,
    this.reportedUserId,
  }) {
    selectedReason = selectedReason ?? null;
    additionalDetails = additionalDetails ?? "";
    reportedUser = reportedUser ?? "Sarah Smith";
    reportedUserId = reportedUserId ?? "";
  }

  String? selectedReason;
  String? additionalDetails;
  String? reportedUser;
  String? reportedUserId;

  ReportStoryModel copyWith({
    String? selectedReason,
    String? additionalDetails,
    String? reportedUser,
    String? reportedUserId,
  }) {
    return ReportStoryModel(
      selectedReason: selectedReason ?? this.selectedReason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      reportedUser: reportedUser ?? this.reportedUser,
      reportedUserId: reportedUserId ?? this.reportedUserId,
    );
  }

  @override
  List<Object?> get props => [
        selectedReason,
        additionalDetails,
        reportedUser,
        reportedUserId,
      ];
}
