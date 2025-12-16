part of 'vibe_selection_screen_two_notifier.dart';

class VibeSelectionScreenTwoState extends Equatable {
  final List<VibeItem> vibes;
  final int? selectedVibeIndex;
  final VibeItem? selectedVibe;

  VibeSelectionScreenTwoState({
    this.vibes = const [],
    this.selectedVibeIndex,
    this.selectedVibe,
  });

  @override
  List<Object?> get props => [
        vibes,
        selectedVibeIndex,
        selectedVibe,
      ];

  VibeSelectionScreenTwoState copyWith({
    List<VibeItem>? vibes,
    int? selectedVibeIndex,
    VibeItem? selectedVibe,
  }) {
    return VibeSelectionScreenTwoState(
      vibes: vibes ?? this.vibes,
      selectedVibeIndex: selectedVibeIndex ?? this.selectedVibeIndex,
      selectedVibe: selectedVibe ?? this.selectedVibe,
    );
  }
}
