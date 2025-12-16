import '../models/memory_invitation_model.dart';
import '../../../core/app_export.dart';

part 'memory_invitation_state.dart';

final memoryInvitationNotifier = StateNotifierProvider.autoDispose<
    MemoryInvitationNotifier, MemoryInvitationState>(
  (ref) => MemoryInvitationNotifier(
    MemoryInvitationState(
      memoryInvitationModel: MemoryInvitationModel(),
    ),
  ),
);

class MemoryInvitationNotifier extends StateNotifier<MemoryInvitationState> {
  MemoryInvitationNotifier(MemoryInvitationState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      isLoading: false,
      isJoined: false,
      memoryInvitationModel: MemoryInvitationModel(
        memoryTitle: 'Fmaily Xmas 2025',
        creatorName: 'Jane Doe',
        creatorImage: ImageConstant.imgEllipse81,
        membersCount: 2,
        storiesCount: 0,
        status: 'Open',
        invitationMessage: 'You\'ve been invited to join this memory',
      ),
    );
  }

  void joinMemory() {
    state = state.copyWith(isLoading: true);

    // Simulate joining process
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          isJoined: true,
        );
      }
    });
  }
}
