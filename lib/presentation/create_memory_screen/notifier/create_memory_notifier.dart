import 'package:flutter/material.dart';
import '../models/create_memory_model.dart';
import '../../../core/app_export.dart';

part 'create_memory_state.dart';

final createMemoryNotifier =
    StateNotifierProvider.autoDispose<CreateMemoryNotifier, CreateMemoryState>(
  (ref) => CreateMemoryNotifier(
    CreateMemoryState(
      createMemoryModel: CreateMemoryModel(),
    ),
  ),
);

class CreateMemoryNotifier extends StateNotifier<CreateMemoryState> {
  CreateMemoryNotifier(CreateMemoryState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      memoryNameController: TextEditingController(),
      isLoading: false,
      currentStep: 1,
      shouldNavigateToInvite: false,
      shouldNavigateBack: false,
      createMemoryModel: CreateMemoryModel(
        isPublic: true,
        memoryName: null,
        selectedGroup: null,
      ),
    );
  }

  String? validateMemoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Memory name is required';
    }
    if (value.trim().length < 3) {
      return 'Memory name must be at least 3 characters';
    }
    return null;
  }

  void togglePrivacySetting(bool isPublic) {
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        isPublic: isPublic,
      ),
    );
  }

  void moveToStep2() {
    if (state.memoryNameController?.text.trim().isEmpty ?? true) {
      return;
    }

    // Update model with current form data and move to step 2
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        memoryName: state.memoryNameController?.text.trim(),
      ),
      currentStep: 2,
    );
  }

  void backToStep1() {
    state = state.copyWith(
      currentStep: 1,
    );
  }

  void updateSelectedGroup(String? groupValue) {
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        selectedGroup: groupValue,
      ),
    );
  }

  void handleQRCodeTap() {
    // Handle QR code functionality
    // Navigate to QR code screen or show QR scanner
  }

  void handleCameraTap() {
    // Handle camera functionality
    // Open camera or image picker
  }

  void createMemory() {
    // Set loading state
    state = state.copyWith(isLoading: true);

    // Simulate memory creation
    Future.delayed(Duration(seconds: 1), () {
      // Reset state and close bottom sheet
      state.memoryNameController?.clear();

      state = state.copyWith(
        isLoading: false,
        shouldNavigateBack: true,
        currentStep: 1,
        createMemoryModel: CreateMemoryModel(
          isPublic: true,
          memoryName: null,
          selectedGroup: null,
        ),
      );

      // Reset navigation flag
      Future.delayed(Duration.zero, () {
        state = state.copyWith(shouldNavigateBack: false);
      });
    });
  }

  void onCancelPressed() {
    // Clear form data
    state.memoryNameController?.clear();

    state = state.copyWith(
      shouldNavigateBack: true,
      currentStep: 1,
      createMemoryModel: CreateMemoryModel(
        isPublic: true,
        memoryName: null,
        selectedGroup: null,
      ),
    );

    // Reset navigation flag
    Future.delayed(Duration.zero, () {
      state = state.copyWith(shouldNavigateBack: false);
    });
  }

  @override
  void dispose() {
    state.memoryNameController?.dispose();
    super.dispose();
  }
}
