
/// This class is used in the [CreateMemoryScreen] screen.

// ignore_for_file: must_be_immutable
class CreateMemoryModel {
  String? memoryName;
  bool isPublic;
  String? selectedGroup;

  CreateMemoryModel({
    this.memoryName,
    this.isPublic = true,
    this.selectedGroup,
  });

  CreateMemoryModel copyWith({
    String? memoryName,
    bool? isPublic,
    String? selectedGroup,
  }) {
    return CreateMemoryModel(
      memoryName: memoryName ?? this.memoryName,
      isPublic: isPublic ?? this.isPublic,
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}
