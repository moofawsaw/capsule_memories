import '../../../core/app_export.dart';

/// This class is used in the [CreateMemoryScreen] screen.

// ignore_for_file: must_be_immutable
class CreateMemoryModel extends Equatable {
  CreateMemoryModel({
    this.memoryName,
    this.isPublic,
  }) {
    memoryName = memoryName ?? "";
    isPublic = isPublic ?? true;
  }

  String? memoryName;
  bool? isPublic;

  CreateMemoryModel copyWith({
    String? memoryName,
    bool? isPublic,
  }) {
    return CreateMemoryModel(
      memoryName: memoryName ?? this.memoryName,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  List<Object?> get props => [
        memoryName,
        isPublic,
      ];
}
