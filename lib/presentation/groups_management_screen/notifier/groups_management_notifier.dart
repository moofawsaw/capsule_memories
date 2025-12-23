import '../models/groups_management_model.dart';
import '../../../core/app_export.dart';
import '../../../services/groups_service.dart';

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

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    await loadGroups();
    state = state.copyWith(isLoading: false);
  }

  Future<void> loadGroups() async {
    try {
      final groupsData = await GroupsService.fetchUserGroups();

      final List<GroupModel> groups = [];

      for (final groupData in groupsData) {
        final group = GroupModel.fromJson(groupData);

        // Fetch member avatars for this group
        final avatars = await GroupsService.fetchGroupMemberAvatars(
          group.id ?? '',
          limit: 3,
        );

        groups.add(group.copyWith(memberImages: avatars));
      }

      state = state.copyWith(
        groups: groups,
        invitations: [],
      );
    } catch (e) {
      print('Error loading groups: $e');
      state = state.copyWith(
        message: 'Failed to load groups',
        groups: [],
      );
    }
  }

  void showGroupQR(String groupName) {
    state = state.copyWith(
      selectedGroupName: groupName,
      showQRCode: true,
    );
  }

  Future<void> deleteGroup(String groupName) async {
    try {
      final group = state.groups?.firstWhere(
        (g) => g.name == groupName,
        orElse: () => GroupModel(),
      );

      if (group?.id == null) return;

      final success = await GroupsService.deleteGroup(group!.id!);

      if (success) {
        final updatedGroups =
            state.groups?.where((g) => g.name != groupName).toList() ?? [];
        state = state.copyWith(
          groups: updatedGroups,
          message: 'Group "$groupName" deleted successfully',
        );
      } else {
        state = state.copyWith(
          message: 'Failed to delete group',
        );
      }
    } catch (e) {
      print('Error deleting group: $e');
      state = state.copyWith(
        message: 'Error deleting group',
      );
    }
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

  Future<void> refresh() async {
    await loadGroups();
  }
}
