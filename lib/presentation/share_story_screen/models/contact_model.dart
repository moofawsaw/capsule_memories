import '../../../core/app_export.dart';

/// This class represents a contact in the share story screen.
// ignore_for_file: must_be_immutable
class ContactModel extends Equatable {
  ContactModel({
    this.name,
    this.profileImage,
    this.isSelected,
  }) {
    name = name ?? "";
    profileImage = profileImage ?? "";
    isSelected = isSelected ?? false;
  }

  String? name;
  String? profileImage;
  bool? isSelected;

  ContactModel copyWith({
    String? name,
    String? profileImage,
    bool? isSelected,
  }) {
    return ContactModel(
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [name, profileImage, isSelected];
}
