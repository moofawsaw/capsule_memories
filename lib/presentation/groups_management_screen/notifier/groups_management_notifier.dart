import '../models/groups_management_model.dart';
import '../../../core/app_export.dart';

part 'groups_management_state.dart';

final groupsManagementNotifier = StateNotifierProvider.autoDispose<
    GroupsManagementNotifier, GroupsManagementState>(
  (ref) => GroupsManagementNotifier(
    GroupsManagementState(
      groupsManagementModel: GroupsManagementModel(),
    ),
  ),
);

class GroupsManagementNotifier extends StateNotifier<GroupsManagementState> {
  GroupsManagementNotifier(GroupsManagementState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      isLoading: false,
      groups: [
        GroupModel(
          name: 'Family',
          memberCount: 2,
          memberImages: [
            ImageConstant.imgEllipse81,
            ImageConstant.imgEllipse842x42,
          ],
        ),
        GroupModel(
          name: 'Work',
          memberCount: 1,
          memberImages: [
            ImageConstant.imgEllipse81,
          ],
        ),
        GroupModel(
          name: 'Friends',
          memberCount: 3,
          memberImages: [
            ImageConstant.imgEllipse81,
            ImageConstant.imgEllipse842x42,
            ImageConstant.imgFrame1,
          ],
        ),
      ],
      invitations: [
        GroupInvitationModel(
          groupName: 'Gang',
          memberCount: 3,
          avatarImage: ImageConstant.imgFrame403,
        ),
      ],
    );
  }

  void showGroupQR(String groupName) {
    state = state.copyWith(
      selectedGroupName: groupName,
      showQRCode: true,
    );
  }

  void deleteGroup(String groupName) {
    final updatedGroups =
        state.groups?.where((group) => group.name != groupName).toList() ?? [];
    state = state.copyWith(
      groups: updatedGroups,
      message: 'Group "$groupName" deleted successfully',
    );
  }

  void acceptInvitation() {
    final updatedInvitations = state.invitations
            ?.where((invite) => invite.groupName != 'Gang')
            .toList() ??
        [];
    state = state.copyWith(
      invitations: updatedInvitations,
      message: 'Invitation accepted successfully',
    );
  }

  void declineInvitation() {
    final updatedInvitations = state.invitations
            ?.where((invite) => invite.groupName != 'Gang')
            .toList() ??
        [];
    state = state.copyWith(
      invitations: updatedInvitations,
      message: 'Invitation declined',
    );
  }

  void clearMessage() {
    state = state.copyWith(message: null);
  }
}
