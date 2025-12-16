import '../models/group_qr_invite_model.dart';
import '../../../core/app_export.dart';

part 'group_qr_invite_state.dart';

final groupQRInviteNotifier = StateNotifierProvider.autoDispose<
    GroupQRInviteNotifier, GroupQRInviteState>(
  (ref) => GroupQRInviteNotifier(
    GroupQRInviteState(
      groupQRInviteModel: GroupQRInviteModel(),
    ),
  ),
);

class GroupQRInviteNotifier extends StateNotifier<GroupQRInviteState> {
  GroupQRInviteNotifier(GroupQRInviteState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      isLoading: false,
      groupQRInviteModel: GroupQRInviteModel(
        groupName: "Jones Family",
        invitationUrl:
            ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08,
        groupDescription: "Scan to join the group",
        qrCodeData:
            ImageConstant.imgNetworkR812309r72309r572093t722323t23t23t08,
      ),
    );
  }

  void updateUrl(String newUrl) {
    final updatedModel = state.groupQRInviteModel?.copyWith(
      invitationUrl: newUrl,
      qrCodeData: newUrl,
    );

    state = state.copyWith(
      groupQRInviteModel: updatedModel,
    );
  }

  void onDownloadQR() {
    state = state.copyWith(isDownloading: true);

    // Download functionality will be handled in the UI
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        state = state.copyWith(
          isDownloading: false,
          downloadSuccess: true,
        );
      }
    });
  }

  void onShareLink() {
    state = state.copyWith(isSharing: true);

    // Share functionality will be handled in the UI
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        state = state.copyWith(
          isSharing: false,
          shareSuccess: true,
        );
      }
    });
  }

  void onCopyUrl() {
    state = state.copyWith(
      copySuccess: true,
    );

    // Reset copy success after a delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(copySuccess: false);
      }
    });
  }

  void resetActions() {
    state = state.copyWith(
      downloadSuccess: false,
      shareSuccess: false,
      copySuccess: false,
    );
  }
}
