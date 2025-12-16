part of 'groups_management_notifier.dart';

class GroupsManagementState extends Equatable {
  final bool? isLoading;
  final String? message;
  final List<GroupModel>? groups;
  final List<GroupInvitationModel>? invitations;
  final String? selectedGroupName;
  final bool? showQRCode;
  final GroupsManagementModel? groupsManagementModel;

  GroupsManagementState({
    this.isLoading = false,
    this.message,
    this.groups,
    this.invitations,
    this.selectedGroupName,
    this.showQRCode = false,
    this.groupsManagementModel,
  });

  @override
  List<Object?> get props => [
        isLoading,
        message,
        groups,
        invitations,
        selectedGroupName,
        showQRCode,
        groupsManagementModel,
      ];

  GroupsManagementState copyWith({
    bool? isLoading,
    String? message,
    List<GroupModel>? groups,
    List<GroupInvitationModel>? invitations,
    String? selectedGroupName,
    bool? showQRCode,
    GroupsManagementModel? groupsManagementModel,
  }) {
    return GroupsManagementState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      groups: groups ?? this.groups,
      invitations: invitations ?? this.invitations,
      selectedGroupName: selectedGroupName ?? this.selectedGroupName,
      showQRCode: showQRCode ?? this.showQRCode,
      groupsManagementModel:
          groupsManagementModel ?? this.groupsManagementModel,
    );
  }
}
