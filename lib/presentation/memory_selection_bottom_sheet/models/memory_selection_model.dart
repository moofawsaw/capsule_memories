import 'package:freezed_annotation/freezed_annotation.dart';

part 'memory_selection_model.freezed.dart';
part 'memory_selection_model.g.dart';

@freezed
class MemorySelectionModel with _$MemorySelectionModel {
  const factory MemorySelectionModel({
    @Default([]) List<MemoryItem> activeMemories,
    @Default([]) List<MemoryItem> filteredMemories,
    @Default(false) bool isLoading,
    String? errorMessage,
    String? searchQuery,
  }) = _MemorySelectionModel;

  factory MemorySelectionModel.fromJson(Map<String, dynamic> json) =>
      _$MemorySelectionModelFromJson(json);
}

@freezed
class MemoryItem with _$MemoryItem {
  const factory MemoryItem({
    String? id,
    String? title,
    String? categoryIcon,
    String? categoryName,
    int? memberCount,
    String? timeRemaining,
    DateTime? expiresAt,
  }) = _MemoryItem;

  factory MemoryItem.fromJson(Map<String, dynamic> json) =>
      _$MemoryItemFromJson(json);
}