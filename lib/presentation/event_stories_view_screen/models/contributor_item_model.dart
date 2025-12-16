import '../../../core/app_export.dart';

/// This class is used for the contributor item widget.

// ignore_for_file: must_be_immutable
class ContributorItemModel extends Equatable {
  ContributorItemModel({
    this.contributorId,
    this.contributorName,
    this.contributorImage,
  }) {
    contributorId = contributorId ?? "";
    contributorName = contributorName ?? "";
    contributorImage = contributorImage ?? "";
  }

  String? contributorId;
  String? contributorName;
  String? contributorImage;

  ContributorItemModel copyWith({
    String? contributorId,
    String? contributorName,
    String? contributorImage,
  }) {
    return ContributorItemModel(
      contributorId: contributorId ?? this.contributorId,
      contributorName: contributorName ?? this.contributorName,
      contributorImage: contributorImage ?? this.contributorImage,
    );
  }

  @override
  List<Object?> get props => [
        contributorId,
        contributorName,
        contributorImage,
      ];
}
