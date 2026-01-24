import '../../../core/app_export.dart';

/// This class is used in the [CreateGroupScreen] screen.

// ignore_for_file: must_be_immutable
class CreateGroupModel extends Equatable {
  CreateGroupModel({
    this.friendsList,
    this.filteredFriends,
    this.selectedMembers,
    this.groupName,
  }) {
    friendsList = friendsList ?? [];
    filteredFriends = filteredFriends ?? [];
    selectedMembers = selectedMembers ?? [];
    groupName = groupName ?? '';
  }

  List<FriendModel>? friendsList;
  List<FriendModel>? filteredFriends;
  List<FriendModel>? selectedMembers;
  String? groupName;

  CreateGroupModel copyWith({
    List<FriendModel>? friendsList,
    List<FriendModel>? filteredFriends,
    List<FriendModel>? selectedMembers,
    String? groupName,
  }) {
    return CreateGroupModel(
      friendsList: friendsList ?? this.friendsList,
      filteredFriends: filteredFriends ?? this.filteredFriends,
      selectedMembers: selectedMembers ?? this.selectedMembers,
      groupName: groupName ?? this.groupName,
    );
  }

  @override
  List<Object?> get props => [
        friendsList,
        filteredFriends,
        selectedMembers,
        groupName,
      ];
}

// ignore_for_file: must_be_immutable
class FriendModel extends Equatable {
  FriendModel({
    this.id,
    this.name,
    this.profileImage,
    this.isSelected,
  }) {
    id = id ?? '';
    name = name ?? '';
    profileImage = profileImage ?? '';
    isSelected = isSelected ?? false;
  }

  String? id;
  String? name;
  String? profileImage;
  bool? isSelected;

  FriendModel copyWith({
    String? id,
    String? name,
    String? profileImage,
    bool? isSelected,
  }) {
    return FriendModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [id, name, profileImage, isSelected];
}
