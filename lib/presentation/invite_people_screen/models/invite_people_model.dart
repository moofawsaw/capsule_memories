import '../../../core/app_export.dart';

/// This class is used in the [InvitePeopleScreen] screen.

// ignore_for_file: must_be_immutable
class InvitePeopleModel extends Equatable {
  InvitePeopleModel({
    this.selectedGroup,
    this.searchQuery,
    this.invitedPeople,
    this.id,
  }) {
    selectedGroup = selectedGroup ?? "";
    searchQuery = searchQuery ?? "";
    invitedPeople = invitedPeople ?? [];
    id = id ?? "";
  }

  String? selectedGroup;
  String? searchQuery;
  List<String>? invitedPeople;
  String? id;

  InvitePeopleModel copyWith({
    String? selectedGroup,
    String? searchQuery,
    List<String>? invitedPeople,
    String? id,
  }) {
    return InvitePeopleModel(
      selectedGroup: selectedGroup ?? this.selectedGroup,
      searchQuery: searchQuery ?? this.searchQuery,
      invitedPeople: invitedPeople ?? this.invitedPeople,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        selectedGroup,
        searchQuery,
        invitedPeople,
        id,
      ];
}
