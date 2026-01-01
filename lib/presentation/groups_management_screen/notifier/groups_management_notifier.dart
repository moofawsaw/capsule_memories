import '../models/groups_management_model.dart';
import '../../../core/app_export.dart';
import '../../../services/groups_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  RealtimeChannel? _groupsChannel;
  RealtimeChannel? _membershipChannel;
  final Map<String, RealtimeChannel> _groupMembersChannels = {};

  GroupsManagementNotifier(GroupsManagementState state) : super(state) {
    initialize();
  }

  @override
  void dispose() {
    _unsubscribeFromAllChannels();
    super.dispose();
  }

  void _unsubscribeFromAllChannels() {
    _groupsChannel?.unsubscribe();
    _membershipChannel?.unsubscribe();

    for (final channel in _groupMembersChannels.values) {
      channel.unsubscribe();
    }
    _groupMembersChannels.clear();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    await loadGroups();
    _setupRealtimeSubscriptions();
    state = state.copyWith(isLoading: false);
  }

  void _setupRealtimeSubscriptions() {
    // Subscribe to groups table changes
    _groupsChannel = GroupsService.subscribeToGroupChanges(
      onInsert: (record) => _handleGroupInserted(record),
      onUpdate: (record) => _handleGroupUpdated(record),
      onDelete: (record) => _handleGroupDeleted(record),
    );

    // Subscribe to user's group membership changes
    _membershipChannel = GroupsService.subscribeToUserGroupMembershipChanges(
      onMembershipChanged: () => _handleMembershipChanged(),
    );

    // Subscribe to member changes for each group
    if (state.groups != null) {
      for (final group in state.groups!) {
        if (group.id != null) {
          _subscribeToGroupMembers(group.id!);
        }
      }
    }
  }

  void _subscribeToGroupMembers(String groupId) {
    if (_groupMembersChannels.containsKey(groupId)) return;

    final channel = GroupsService.subscribeToGroupMembersChanges(
      groupId: groupId,
      onMemberAdded: (record) => _handleMemberAdded(groupId, record),
      onMemberRemoved: (record) => _handleMemberRemoved(groupId, record),
    );

    _groupMembersChannels[groupId] = channel;
  }

  void _handleGroupInserted(Map<String, dynamic> record) async {
    // Reload groups to include the new group
    await loadGroups();
  }

  void _handleGroupUpdated(Map<String, dynamic> record) async {
    final groupId = record['id'] as String;
    final updatedGroups = state.groups?.map((group) {
      if (group.id == groupId) {
        return GroupModel.fromJson(record).copyWith(
          memberImages: group.memberImages,
        );
      }
      return group;
    }).toList();

    if (updatedGroups != null) {
      state = state.copyWith(groups: updatedGroups);
    }
  }

  void _handleGroupDeleted(Map<String, dynamic> record) {
    final groupId = record['id'] as String;

    // Remove subscription for this group
    _groupMembersChannels[groupId]?.unsubscribe();
    _groupMembersChannels.remove(groupId);

    // Remove from state
    final updatedGroups = state.groups?.where((g) => g.id != groupId).toList();
    state = state.copyWith(groups: updatedGroups);
  }

  void _handleMembershipChanged() async {
    // User joined or left a group - reload all groups
    await loadGroups();
  }

  void _handleMemberAdded(String groupId, Map<String, dynamic> record) async {
    // Refetch member avatars and update member count for this group
    await _updateGroupMemberData(groupId);
  }

  void _handleMemberRemoved(String groupId, Map<String, dynamic> record) async {
    // Refetch member avatars and update member count for this group
    await _updateGroupMemberData(groupId);
  }

  Future<void> _updateGroupMemberData(String groupId) async {
    try {
      // Fetch updated group data with new member count
      final groupData = await GroupsService.fetchGroupById(groupId);
      if (groupData == null) return;

      // Fetch updated member avatars
      final avatars = await GroupsService.fetchGroupMemberAvatars(
        groupId,
        limit: 3,
      );

      // Update the specific group in state
      final updatedGroups = state.groups?.map((group) {
        if (group.id == groupId) {
          return GroupModel.fromJson(groupData).copyWith(
            memberImages: avatars,
          );
        }
        return group;
      }).toList();

      if (updatedGroups != null) {
        state = state.copyWith(groups: updatedGroups);
      }
    } catch (e) {
      print('Error updating group member data: $e');
    }
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

        // Subscribe to this group's member changes if not already subscribed
        if (group.id != null) {
          _subscribeToGroupMembers(group.id!);
        }
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
