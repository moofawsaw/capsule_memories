// lib/presentation/feature_request_screen/notifier/feature_request_notifier.dart

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/app_export.dart';
import '../../../services/platform_stub.dart';
import '../../../services/supabase_service.dart';
import '../models/feature_request_model.dart';

part 'feature_request_state.dart';

final featureRequestNotifier =
StateNotifierProvider.autoDispose<FeatureRequestNotifier, FeatureRequestState>(
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
      status: FeatureRequestStatus.idle,
      message: null,
    );
  }

  String? validateFeatureDescription(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Please provide your feature request details';
    return null;
  }

  Future<void> submitFeatureRequest({String? category}) async {
    // One-time: if already completed on this screen instance, do nothing.
    if (state.isCompleted) return;

    final description = (state.featureDescriptionController?.text ?? '').trim();
    final validationError = validateFeatureDescription(description);

    if (validationError != null) {
      state = state.copyWith(
        status: FeatureRequestStatus.error,
        message: validationError,
      );
      return;
    }

    state = state.copyWith(
      status: FeatureRequestStatus.submitting,
      message: null,
    );

    try {
      final supabase = SupabaseService.instance.client;

      if (supabase == null) {
        throw Exception('Supabase client not initialized');
      }

      final deviceInfo = _getDeviceInfo();

      // ✅ Normalize chip label -> DB-friendly values
      final normalizedCategory = (category ?? 'Other').trim().toLowerCase();

      final response = await supabase.functions.invoke(
        'submit-feature-request',
        body: {
          'title': 'Feature Request',
          'description': description,
          'category': normalizedCategory, // ✅ chip-driven
          'device_info': deviceInfo,
        },
      );

      if (response.status == 200) {
        state.featureDescriptionController?.clear();

        state = state.copyWith(
          status: FeatureRequestStatus.success,
          message:
          'We received your submission. You should receive an email confirmation shortly.',
          featureRequestModel: state.featureRequestModel?.copyWith(
            description: description,
            submittedAt: DateTime.now(),
          ),
        );
      } else {
        throw Exception('Failed to submit feature request: ${response.status}');
      }
    } catch (e) {
      state = state.copyWith(
        status: FeatureRequestStatus.error,
        message:
        'We couldn’t submit your request right now. Please try again later. If it went through, you should receive an email confirmation shortly.',
      );
    }
  }

  Map<String, String> _getDeviceInfo() {
    String os = 'Unknown';
    String appVersion = '1.0.0';

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
