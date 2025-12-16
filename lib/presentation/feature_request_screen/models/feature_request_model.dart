import '../../../core/app_export.dart';

/// This class is used in the [FeatureRequestScreen] screen.

// ignore_for_file: must_be_immutable
class FeatureRequestModel extends Equatable {
  FeatureRequestModel({
    this.description,
    this.submittedAt,
    this.id,
  }) {
    description = description ?? "";
    id = id ?? "";
  }

  String? description;
  DateTime? submittedAt;
  String? id;

  FeatureRequestModel copyWith({
    String? description,
    DateTime? submittedAt,
    String? id,
  }) {
    return FeatureRequestModel(
      description: description ?? this.description,
      submittedAt: submittedAt ?? this.submittedAt,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [description, submittedAt, id];
}
