import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/memory_selection_model.dart';

@freezed
class MemorySelectionState with _$MemorySelectionState {
  const factory MemorySelectionState({
    MemorySelectionModel? memorySelectionModel,
    @Default(false) bool isLoading,
    List<MemoryItem>? activeMemories,
    List<MemoryItem>? filteredMemories,
    String? errorMessage,
    String? searchQuery,
  }) = _MemorySelectionState;

  factory MemorySelectionState.initial() => const MemorySelectionState();
}