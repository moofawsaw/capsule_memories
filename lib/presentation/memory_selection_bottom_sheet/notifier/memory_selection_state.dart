import '../models/memory_selection_model.dart';

class MemorySelectionState {
  final bool isLoading;
  final List<MemoryItem>? activeMemories;
  final List<MemoryItem>? filteredMemories;
  final String? errorMessage;
  final String? searchQuery;

  const MemorySelectionState({
    this.isLoading = false,
    this.activeMemories,
    this.filteredMemories,
    this.errorMessage,
    this.searchQuery,
  });

  factory MemorySelectionState.initial() => const MemorySelectionState();

  MemorySelectionState copyWith({
    bool? isLoading,
    List<MemoryItem>? activeMemories,
    List<MemoryItem>? filteredMemories,
    String? errorMessage,
    String? searchQuery,
  }) {
    return MemorySelectionState(
      isLoading: isLoading ?? this.isLoading,
      activeMemories: activeMemories ?? this.activeMemories,
      filteredMemories: filteredMemories ?? this.filteredMemories,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
