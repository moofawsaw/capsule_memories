import '../models/feature_request_model.dart';
import '../../../core/app_export.dart';

part 'feature_request_state.dart';

final featureRequestNotifier = StateNotifierProvider.autoDispose<
    FeatureRequestNotifier, FeatureRequestState>(
  (ref) => FeatureRequestNotifier(
    FeatureRequestState(
      featureRequestModel: FeatureRequestModel(),
    ),
  ),
);

class FeatureRequestNotifier extends StateNotifier<FeatureRequestState> {
  FeatureRequestNotifier(FeatureRequestState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      featureDescriptionController: TextEditingController(),
      isLoading: false,
      isSubmitted: false,
      hasError: false,
    );
  }

  String? validateFeatureDescription(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return 'Please provide your feature request details';
    }
    return null;
  }

  void submitFeatureRequest() {
    final description = state.featureDescriptionController?.text.trim();

    if (description?.isEmpty ?? true) {
      state = state.copyWith(hasError: true);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      hasError: false,
    );

    // Simulate API call
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        // Clear form
        state.featureDescriptionController?.clear();

        state = state.copyWith(
          isLoading: false,
          isSubmitted: true,
          featureRequestModel: state.featureRequestModel?.copyWith(
            description: description,
            submittedAt: DateTime.now(),
          ),
        );

        // Reset submission state after a delay
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            state = state.copyWith(isSubmitted: false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    state.featureDescriptionController?.dispose();
    super.dispose();
  }
}
