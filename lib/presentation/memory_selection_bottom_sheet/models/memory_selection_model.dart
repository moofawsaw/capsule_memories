import 'package:freezed_annotation/freezed_annotation.dart';

part 'memory_selection_model.freezed.dart';

@freezed
class MemorySelectionModel with _$MemorySelectionModel {
  const factory MemorySelectionModel({
    @Default([]) List<MemoryItem> activeMemories,
    @Default([]) List<MemoryItem> filteredMemories,
    @Default(false) bool isLoading,
    String? errorMessage,
    String? searchQuery,
  }) = _MemorySelectionModel;
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
}
