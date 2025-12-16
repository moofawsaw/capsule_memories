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
      shouldNavigateToInvite: false,
      shouldNavigateBack: false,
      createMemoryModel: CreateMemoryModel(
        isPublic: true,
        memoryName: null,
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

  void onNextPressed() {
    if (state.memoryNameController?.text.trim().isEmpty ?? true) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
    );

    // Update model with current form data
    state = state.copyWith(
      createMemoryModel: state.createMemoryModel?.copyWith(
        memoryName: state.memoryNameController?.text.trim(),
      ),
      isLoading: false,
      shouldNavigateToInvite: true,
    );

    // Reset navigation flag
    Future.delayed(Duration.zero, () {
      state = state.copyWith(shouldNavigateToInvite: false);
    });
  }

  void onCancelPressed() {
    // Clear form data
    state.memoryNameController?.clear();

    state = state.copyWith(
      shouldNavigateBack: true,
      createMemoryModel: CreateMemoryModel(
        isPublic: true,
        memoryName: null,
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
