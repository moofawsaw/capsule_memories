import '../models/group_join_confirmation_model.dart';
import '../../../core/app_export.dart';

part 'group_join_confirmation_state.dart';

final groupJoinConfirmationNotifier = StateNotifierProvider.autoDispose<
    GroupJoinConfirmationNotifier, GroupJoinConfirmationState>(
  (ref) => GroupJoinConfirmationNotifier(
    GroupJoinConfirmationState(
      groupJoinConfirmationModel: GroupJoinConfirmationModel(),
    ),
  ),
);

class GroupJoinConfirmationNotifier
    extends StateNotifier<GroupJoinConfirmationState> {
  GroupJoinConfirmationNotifier(GroupJoinConfirmationState state)
      : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      shouldNavigateToCreateMemory: false,
      shouldClose: false,
      isLoading: false,
    );
  }

  void onCreateStoryPressed() {
    state = state.copyWith(
      shouldNavigateToCreateMemory: true,
    );

    // Reset navigation flag after a brief moment
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        state = state.copyWith(
          shouldNavigateToCreateMemory: false,
        );
      }
    });
  }

  void onClosePressed() {
    state = state.copyWith(
      shouldClose: true,
    );

    // Reset navigation flag after a brief moment
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        state = state.copyWith(
          shouldClose: false,
        );
      }
    });
  }
}
