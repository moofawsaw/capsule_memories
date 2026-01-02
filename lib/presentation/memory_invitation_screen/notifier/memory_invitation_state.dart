import 'package:freezed_annotation/freezed_annotation.dart';

// Remove this line - comment out the part directive until freezed file is generated
// part 'memory_invitation_state.freezed.dart';

// Note: Run 'flutter pub run build_runner build' to generate the freezed file

@freezed
class MemoryInvitationState with _$MemoryInvitationState {
  const factory MemoryInvitationState({
    Map<String, dynamic>? memoryInvitationModel,
    @Default(false) bool isLoading,
    @Default(false) bool isDownloading,
    @Default(false) bool isSharing,
    @Default(false) bool downloadSuccess,
    @Default(false) bool shareSuccess,
    @Default(false) bool copySuccess,
    String? errorMessage,
  }) = _MemoryInvitationState;
}