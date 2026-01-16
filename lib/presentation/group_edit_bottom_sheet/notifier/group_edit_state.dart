import '../models/group_edit_model.dart';
import 'package:equatable/equatable.dart';

class GroupEditState extends Equatable {
  final bool isLoadingMembers;
  final bool isLoadingFriends;
  final bool isSaving;
  final List<Map<String, dynamic>> currentMembers;
  final List<Map<String, dynamic>> availableFriends;
  final List<Map<String, dynamic>> selectedFriendsToAdd;
  final String? errorMessage;

  const GroupEditState({
    this.isLoadingMembers = false,
    this.isLoadingFriends = false,
    this.isSaving = false,
    this.currentMembers = const [],
    this.availableFriends = const [],
    this.selectedFriendsToAdd = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        isLoadingMembers,
        isLoadingFriends,
        isSaving,
        currentMembers,
        availableFriends,
        selectedFriendsToAdd,
        errorMessage,
      ];
}

class GroupEditInitial extends GroupEditState {
  @override
  GroupEditModel get groupEditModelObj => GroupEditModel();
}

class GroupEditLoaded extends GroupEditState {
  @override
  final GroupEditModel groupEditModelObj;

  GroupEditLoaded(this.groupEditModelObj);
}
