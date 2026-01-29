import 'package:equatable/equatable.dart';

class DailyCapsuleState extends Equatable {
  final bool isLoading;
  final bool isCompleting;
  final Map<String, dynamic>? todayEntry;
  final List<Map<String, dynamic>> archiveEntries;
  final int streakCount;
  final String? errorMessage;

  static const _Unset _unset = _Unset();

  const DailyCapsuleState({
    this.isLoading = false,
    this.isCompleting = false,
    this.todayEntry,
    this.archiveEntries = const [],
    this.streakCount = 0,
    this.errorMessage,
  });

  DailyCapsuleState copyWith({
    bool? isLoading,
    bool? isCompleting,
    Object? todayEntry = _unset,
    List<Map<String, dynamic>>? archiveEntries,
    int? streakCount,
    String? errorMessage,
  }) {
    return DailyCapsuleState(
      isLoading: isLoading ?? this.isLoading,
      isCompleting: isCompleting ?? this.isCompleting,
      // Allow explicitly clearing todayEntry by passing null.
      todayEntry: identical(todayEntry, _unset)
          ? this.todayEntry
          : todayEntry as Map<String, dynamic>?,
      archiveEntries: archiveEntries ?? this.archiveEntries,
      streakCount: streakCount ?? this.streakCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isCompleting,
        todayEntry,
        archiveEntries,
        streakCount,
        errorMessage,
      ];
}

class _Unset {
  const _Unset();
}