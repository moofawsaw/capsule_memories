import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/memory_selection_model.dart';

part 'memory_selection_state.freezed.dart';

@freezed
class MemorySelectionState with _$MemorySelectionState {
  const factory MemorySelectionState({
    @Default(false) bool isLoading,
    List<MemoryItem>? activeMemories,
    List<MemoryItem>? filteredMemories,
    String? errorMessage,
    String? searchQuery,
  }) = _MemorySelectionState;

  factory MemorySelectionState.initial() => const MemorySelectionState();
}