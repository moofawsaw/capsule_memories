import '../../../core/app_export.dart';
part 'memory_invitation_state.dart';

final memoryInvitationNotifier =
    StateNotifierProvider<MemoryInvitationNotifier, MemoryInvitationState>(
  (ref) => MemoryInvitationNotifier(MemoryInvitationState(
    memoryInvitationModel: null,
  )),
);

class MemoryInvitationNotifier extends StateNotifier<MemoryInvitationState> {
  MemoryInvitationNotifier(MemoryInvitationState state) : super(state);

  // Removed joinMemory() method - join functionality now handled directly in screen
}