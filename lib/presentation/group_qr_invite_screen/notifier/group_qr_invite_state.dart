part of 'group_qr_invite_notifier.dart';

class GroupQRInviteState extends Equatable {
  final GroupQRInviteModel? groupQRInviteModel;
  final bool? isLoading;
  final bool? isDownloading;
  final bool? isSharing;
  final bool? downloadSuccess;
  final bool? shareSuccess;
  final bool? copySuccess;
  final String? errorMessage;

  GroupQRInviteState({
    this.groupQRInviteModel,
    this.isLoading = false,
    this.isDownloading = false,
    this.isSharing = false,
    this.downloadSuccess = false,
    this.shareSuccess = false,
    this.copySuccess = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        groupQRInviteModel,
        isLoading,
        isDownloading,
        isSharing,
        downloadSuccess,
        shareSuccess,
        copySuccess,
        errorMessage,
      ];

  GroupQRInviteState copyWith({
    GroupQRInviteModel? groupQRInviteModel,
    bool? isLoading,
    bool? isDownloading,
    bool? isSharing,
    bool? downloadSuccess,
    bool? shareSuccess,
    bool? copySuccess,
    String? errorMessage,
  }) {
    return GroupQRInviteState(
      groupQRInviteModel: groupQRInviteModel ?? this.groupQRInviteModel,
      isLoading: isLoading ?? this.isLoading,
      isDownloading: isDownloading ?? this.isDownloading,
      isSharing: isSharing ?? this.isSharing,
      downloadSuccess: downloadSuccess ?? this.downloadSuccess,
      shareSuccess: shareSuccess ?? this.shareSuccess,
      copySuccess: copySuccess ?? this.copySuccess,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
