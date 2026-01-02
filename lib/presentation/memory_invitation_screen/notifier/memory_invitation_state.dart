import 'package:freezed_annotation/freezed_annotation.dart';

part 'memory_invitation_notifier.dart';

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