import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../models/memory_details_model.dart';

part 'memory_details_state.dart';

final memoryDetailsNotifier = StateNotifierProvider.autoDispose<
    MemoryDetailsNotifier, MemoryDetailsState>(
  (ref) => MemoryDetailsNotifier(
    MemoryDetailsState(
      memoryDetailsModel: MemoryDetailsModel(),
    ),
  ),
);

class MemoryDetailsNotifier extends StateNotifier<MemoryDetailsState> {
  MemoryDetailsNotifier(MemoryDetailsState state) : super(state) {
    initialize();
  }

  void initialize() {
    final titleController = TextEditingController();
    final inviteLinkController = TextEditingController();

    titleController.text = 'Family Xmas 2025';
    inviteLinkController.text =
        ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08;

    final members = [
      MemberModel(
        name: 'Ki Jones',
        profileImagePath: ImageConstant.imgEllipse826x26,
        role: 'Creator',
        isCreator: true,
      ),
      MemberModel(
        name: 'Jane Doe',
        profileImagePath: ImageConstant.imgEllipse81,
        role: 'Member',
        isCreator: false,
      ),
    ];

    state = state.copyWith(
      titleController: titleController,
      inviteLinkController: inviteLinkController,
      isPublic: true,
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(
        title: 'Family Xmas 2025',
        inviteLink:
            ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08,
        isPublic: true,
        members: members,
      ),
    );
  }

  void updateVisibility(bool isPublic) {
    state = state.copyWith(
      isPublic: isPublic,
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(
        isPublic: isPublic,
      ),
    );
  }

  void copyInviteLink() {
    final inviteLink = state.inviteLinkController?.text ?? '';
    if (inviteLink.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: inviteLink));
      state = state.copyWith(
        showSuccessMessage: true,
        successMessage: 'Invite link copied to clipboard',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    }
  }

  void updateTitle(String title) {
    state = state.copyWith(
      memoryDetailsModel: state.memoryDetailsModel?.copyWith(
        title: title,
      ),
    );
  }

  Future<void> saveMemory() async {
    state = state.copyWith(isSaving: true);

    try {
      // Simulate save operation
      await Future.delayed(Duration(seconds: 1));

      state = state.copyWith(
        isSaving: false,
        showSuccessMessage: true,
        successMessage: 'Memory saved successfully',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        showSuccessMessage: true,
        successMessage: 'Failed to save memory',
      );
    }
  }

  Future<void> shareMemory() async {
    state = state.copyWith(isSharing: true);

    try {
      // Simulate share operation
      await Future.delayed(Duration(seconds: 1));

      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Memory shared successfully',
      );

      // Reset success message after showing
      Future.delayed(Duration(milliseconds: 2000), () {
        if (mounted) {
          state = state.copyWith(
            showSuccessMessage: false,
            successMessage: null,
          );
        }
      });
    } catch (e) {
      state = state.copyWith(
        isSharing: false,
        showSuccessMessage: true,
        successMessage: 'Failed to share memory',
      );
    }
  }

  @override
  void dispose() {
    state.titleController?.dispose();
    state.inviteLinkController?.dispose();
    super.dispose();
  }
}
