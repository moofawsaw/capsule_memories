
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/app_export.dart';
import '../../../services/platform_stub.dart';
import '../../../services/supabase_service.dart';
import '../models/feature_request_model.dart';

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

  Future<void> submitFeatureRequest() async {
    final description = state.featureDescriptionController?.text.trim();

    if (description?.isEmpty ?? true) {
      state = state.copyWith(hasError: true);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      hasError: false,
    );

    try {
      final supabase = SupabaseService.instance.client;

      if (supabase == null) {
        throw Exception('Supabase client not initialized');
      }

      // Get device info
      final deviceInfo = _getDeviceInfo();

      // Call Supabase Edge Function
      final response = await supabase.functions.invoke(
        'submit-feature-request',
        body: {
          'title':
              'Feature Request', // You can extract this from description or add a title field
          'description': description,
          'category': 'memories', // Optional category
          'device_info': deviceInfo,
        },
      );

      if (response.status == 200) {
        // Clear form on success
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
      } else {
        throw Exception('Failed to submit feature request: ${response.status}');
      }
    } catch (e) {
      print('❌ Error submitting feature request: $e');
      state = state.copyWith(
        isLoading: false,
        hasError: true,
      );
    }
  }

  Map<String, String> _getDeviceInfo() {
    String os = 'Unknown';
    String appVersion = '1.0.0'; // You can get this from package_info_plus

    if (kIsWeb) {
      os = 'Web';
    } else {
      if (Platform.isAndroid) {
        os = 'Android';
      } else if (Platform.isIOS) {
        os = 'iOS';
      } else if (Platform.isMacOS) {
        os = 'MacOS';
      } else if (Platform.isWindows) {
        os = 'Windows';
      } else if (Platform.isLinux) {
        os = 'Linux';
      }
    }

    return {
      'os': os,
      'appVersion': appVersion,
    };
  }

  @override
  void dispose() {
    state.featureDescriptionController?.dispose();
    super.dispose();
  }
}
