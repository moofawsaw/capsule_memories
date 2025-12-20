import '../../../core/app_export.dart';
import './contact_model.dart';

/// This class is used in the [ShareStoryScreen] screen.
// ignore_for_file: must_be_immutable
class ShareStoryModel extends Equatable {
  ShareStoryModel({
    this.contacts,
    this.filteredContacts,
    this.searchQuery,
  }) {
    contacts = contacts ?? _getInitialContacts();
    filteredContacts = filteredContacts ?? contacts;
    searchQuery = searchQuery ?? "";
  }

  List<ContactModel>? contacts;
  List<ContactModel>? filteredContacts;
  String? searchQuery;

  ShareStoryModel copyWith({
    List<ContactModel>? contacts,
    List<ContactModel>? filteredContacts,
    String? searchQuery,
  }) {
    return ShareStoryModel(
      contacts: contacts ?? this.contacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [contacts, filteredContacts, searchQuery];

  List<ContactModel> _getInitialContacts() {
    // Use existing ellipse images as placeholders since contact images don't exist
    return [
      ContactModel(
        name: "Sarah Smith",
        profileImage: ImageConstant.imgEllipse864x64,
        isSelected: false,
      ),
      ContactModel(
        name: "John Doe",
        profileImage: ImageConstant.imgEllipse864x64,
        isSelected: false,
      ),
      ContactModel(
        name: "Emily Johnson",
        profileImage: ImageConstant.imgEllipse864x64,
        isSelected: false,
      ),
      ContactModel(
        name: "Michael Brown",
        profileImage: ImageConstant.imgEllipse864x64,
        isSelected: false,
      ),
      ContactModel(
        name: "Jessica Davis",
        profileImage: ImageConstant.imgEllipse864x64,
        isSelected: false,
      ),
      ContactModel(
        name: "William Garcia",
        profileImage: ImageConstant.imgEllipse864x64,
        isSelected: false,
      ),
    ];
  }
}
