// lib/presentation/feature_request_screen/notifier/feature_request_notifier.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

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
      status: FeatureRequestStatus.idle,
      message: null,
      selectedMediaFiles: [],
    );
  }

  String? validateFeatureDescription(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Please provide your feature request details';
    return null;
  }

  /// ✅ New method to handle media picking
  Future<void> pickMedia() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        // Limit to 3 files total
        final currentCount = state.selectedMediaFiles.length;
        final availableSlots = 3 - currentCount;

        if (availableSlots > 0) {
          final filesToAdd = images.take(availableSlots).toList();
          state = state.copyWith(
            selectedMediaFiles: [...state.selectedMediaFiles, ...filesToAdd],
          );
        }
      }
    } catch (e) {
      // Handle silently or show error if needed
      debugPrint('Error picking media: $e');
    }
  }

  /// ✅ New method to remove selected media
  void removeMedia(int index) {
    final updatedList = List<XFile>.from(state.selectedMediaFiles);
    if (index >= 0 && index < updatedList.length) {
      updatedList.removeAt(index);
      state = state.copyWith(selectedMediaFiles: updatedList);
    }
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

      // ✅ Convert media files to base64 for submission
      final List<Map<String, String>> mediaData = [];
      for (var file in state.selectedMediaFiles) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        mediaData.add({
          'name': file.name,
          'data': base64String,
          'mimeType': file.mimeType ?? 'image/jpeg',
        });
      }

      final response = await supabase.functions.invoke(
        'submit-feature-request',
        body: {
          'title': 'Feature Request',
          'description': description,
          'category': normalizedCategory,
          'device_info': deviceInfo,
          'media': mediaData, // ✅ Include media in submission
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
          selectedMediaFiles: [], // ✅ Clear selected media
        );
      } else {
        throw Exception('Failed to submit feature request: ${response.status}');
      }
    } catch (e) {
      state = state.copyWith(
        status: FeatureRequestStatus.error,
        message:
            'We couldn\'t submit your request right now. Please try again later. If it went through, you should receive an email confirmation shortly.',
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