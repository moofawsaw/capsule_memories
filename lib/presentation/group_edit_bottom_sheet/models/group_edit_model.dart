import '../../../core/app_export.dart';

class GroupEditModel extends Equatable {
  final String? groupId;
  final String? groupName;
  final List<Map<String, dynamic>> currentMembers;
  final List<Map<String, dynamic>> availableFriends;
  final List<Map<String, dynamic>> selectedFriendsToAdd;
  final bool isLoadingMembers;
  final bool isLoadingFriends;
  final bool isSaving;
  final String? error;

  GroupEditModel({
    this.groupId,
    this.groupName,
    this.currentMembers = const [],
    this.availableFriends = const [],
    this.selectedFriendsToAdd = const [],
    this.isLoadingMembers = false,
    this.isLoadingFriends = false,
    this.isSaving = false,
    this.error,
  });

  GroupEditModel copyWith({
    String? groupId,
    String? groupName,
    List<Map<String, dynamic>>? currentMembers,
    List<Map<String, dynamic>>? availableFriends,
    List<Map<String, dynamic>>? selectedFriendsToAdd,
    bool? isLoadingMembers,
    bool? isLoadingFriends,
    bool? isSaving,
    String? error,
  }) {
    return GroupEditModel(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      currentMembers: currentMembers ?? this.currentMembers,
      availableFriends: availableFriends ?? this.availableFriends,
      selectedFriendsToAdd: selectedFriendsToAdd ?? this.selectedFriendsToAdd,
      isLoadingMembers: isLoadingMembers ?? this.isLoadingMembers,
      isLoadingFriends: isLoadingFriends ?? this.isLoadingFriends,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        groupId,
        groupName,
        currentMembers,
        availableFriends,
        selectedFriendsToAdd,
        isLoadingMembers,
        isLoadingFriends,
        isSaving,
        error,
      ];
}
