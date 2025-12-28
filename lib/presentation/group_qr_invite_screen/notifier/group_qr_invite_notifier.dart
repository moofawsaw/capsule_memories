import '../../../core/app_export.dart';
import '../../../services/groups_service.dart';
import '../models/group_qr_invite_model.dart';

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
  GroupQRInviteNotifier(GroupQRInviteState state) : super(state);

  /// Initialize with group ID to load real data
  Future<void> initialize(String groupId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final groupData = await GroupsService.fetchGroupById(groupId);

      if (groupData != null && mounted) {
        final inviteCode = groupData['invite_code'] as String;
        final groupName = groupData['name'] as String;
        final inviteUrl = 'https://capapp.co/group/join/$inviteCode';

        state = state.copyWith(
          isLoading: false,
          groupQRInviteModel: GroupQRInviteModel(
            id: groupData['id'] as String,
            groupName: groupName,
            invitationUrl: inviteUrl,
            qrCodeData: inviteUrl,
            groupDescription: 'Scan to join the group',
            iconPath: ImageConstant.imgButtons,
          ),
        );
      } else if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load group data',
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error loading group: ${e.toString()}',
        );
      }
    }
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
