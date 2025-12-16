import '../../../core/app_export.dart';

/// This class is used in the [add_memory_upload_screen] screen.

// ignore_for_file: must_be_immutable
class AddMemoryUploadModel extends Equatable {
  AddMemoryUploadModel({
    this.memoryName,
    this.maxFileSize,
    this.allowedFileTypes,
    this.id,
  }) {
    memoryName = memoryName ?? "memory name";
    maxFileSize = maxFileSize ?? 50; // 50MB
    allowedFileTypes = allowedFileTypes ?? ["photo", "video"];
    id = id ?? "";
  }

  String? memoryName;
  int? maxFileSize;
  List<String>? allowedFileTypes;
  String? id;

  AddMemoryUploadModel copyWith({
    String? memoryName,
    int? maxFileSize,
    List<String>? allowedFileTypes,
    String? id,
  }) {
    return AddMemoryUploadModel(
      memoryName: memoryName ?? this.memoryName,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      allowedFileTypes: allowedFileTypes ?? this.allowedFileTypes,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        memoryName,
        maxFileSize,
        allowedFileTypes,
        id,
      ];
}
