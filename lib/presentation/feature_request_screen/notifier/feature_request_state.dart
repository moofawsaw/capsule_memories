part of 'feature_request_notifier.dart';

class FeatureRequestState extends Equatable {
  final TextEditingController? featureDescriptionController;
  final bool? isLoading;
  final bool? isSubmitted;
  final bool? hasError;
  final FeatureRequestModel? featureRequestModel;

  FeatureRequestState({
    this.featureDescriptionController,
    this.isLoading = false,
    this.isSubmitted = false,
    this.hasError = false,
    this.featureRequestModel,
  });

  @override
  List<Object?> get props => [
        featureDescriptionController,
        isLoading,
        isSubmitted,
        hasError,
        featureRequestModel,
      ];

  FeatureRequestState copyWith({
    TextEditingController? featureDescriptionController,
    bool? isLoading,
    bool? isSubmitted,
    bool? hasError,
    FeatureRequestModel? featureRequestModel,
  }) {
    return FeatureRequestState(
      featureDescriptionController:
          featureDescriptionController ?? this.featureDescriptionController,
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      hasError: hasError ?? this.hasError,
      featureRequestModel: featureRequestModel ?? this.featureRequestModel,
    );
  }
}
