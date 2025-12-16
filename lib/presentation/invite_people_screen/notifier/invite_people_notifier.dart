import 'package:flutter/material.dart';

import '../models/invite_people_model.dart';

import '../../../core/app_export.dart';

part 'invite_people_state.dart';

final invitePeopleNotifier =
    StateNotifierProvider.autoDispose<InvitePeopleNotifier, InvitePeopleState>(
  (ref) => InvitePeopleNotifier(
    InvitePeopleState(
      invitePeopleModel: InvitePeopleModel(),
    ),
  ),
);

class InvitePeopleNotifier extends StateNotifier<InvitePeopleState> {
  InvitePeopleNotifier(InvitePeopleState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      searchController: TextEditingController(),
      isLoading: false,
      isNavigating: false,
    );
  }

  void updateSelectedGroup(String? group) {
    final updatedModel =
        state.invitePeopleModel?.copyWith(selectedGroup: group);
    state = state.copyWith(
      invitePeopleModel: updatedModel,
    );
  }

  void updateSearchQuery(String query) {
    final updatedModel = state.invitePeopleModel?.copyWith(searchQuery: query);
    state = state.copyWith(
      invitePeopleModel: updatedModel,
    );
  }

  void handleQRCodeTap() {
    // Handle QR code scanning functionality
    state = state.copyWith(
      isLoading: true,
    );

    // Simulate QR code action
    Future.delayed(Duration(milliseconds: 500), () {
      state = state.copyWith(
        isLoading: false,
      );
    });
  }

  void handleCameraTap() {
    // Handle camera functionality
    state = state.copyWith(
      isLoading: true,
    );

    // Simulate camera action
    Future.delayed(Duration(milliseconds: 500), () {
      state = state.copyWith(
        isLoading: false,
      );
    });
  }

  void createMemory() {
    state = state.copyWith(
      isLoading: true,
    );

    // Simulate memory creation
    Future.delayed(Duration(seconds: 1), () {
      state = state.copyWith(
        isLoading: false,
        isNavigating: true,
        navigationRoute: AppRoutes.hangoutCallScreen,
      );
    });
  }

  @override
  void dispose() {
    state.searchController?.dispose();
    super.dispose();
  }
}
