part of 'feature_request_notifier.dart';

enum FeatureRequestStatus { idle, submitting, success, error }

class FeatureRequestState extends Equatable {
  final TextEditingController? featureDescriptionController;
  final FeatureRequestStatus status;
  final String? message;
  final FeatureRequestModel? featureRequestModel;
  // ✅ Added selectedMediaFiles to track uploaded media
  final List<XFile> selectedMediaFiles;

  const FeatureRequestState({
    this.featureDescriptionController,
    this.status = FeatureRequestStatus.idle,
    this.message,
    this.featureRequestModel,
    this.selectedMediaFiles = const [],
  });

  bool get isLoading => status == FeatureRequestStatus.submitting;
  bool get isSuccess => status == FeatureRequestStatus.success;
  bool get isError => status == FeatureRequestStatus.error;

  /// "One-time" receipt behavior: once success/error happens, keep showing receipt.
  bool get isCompleted => isSuccess || isError;

  @override
  List<Object?> get props => [
        featureDescriptionController,
        status,
        message,
        featureRequestModel,
        selectedMediaFiles,
      ];

  FeatureRequestState copyWith({
    TextEditingController? featureDescriptionController,
    FeatureRequestStatus? status,
    String? message,
    FeatureRequestModel? featureRequestModel,
    List<XFile>? selectedMediaFiles,
  }) {
    return FeatureRequestState(
      featureDescriptionController:
          featureDescriptionController ?? this.featureDescriptionController,
      status: status ?? this.status,
      message: message,
      featureRequestModel: featureRequestModel ?? this.featureRequestModel,
      selectedMediaFiles: selectedMediaFiles ?? this.selectedMediaFiles,
    );
  }
}
