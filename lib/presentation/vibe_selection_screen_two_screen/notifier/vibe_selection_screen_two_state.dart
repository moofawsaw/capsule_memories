part of 'vibe_selection_screen_two_notifier.dart';

class VibeSelectionScreenTwoState extends Equatable {
  VibeSelectionScreenTwoState({
    this.vibeSelectionScreenTwoModel,
    this.selectedCategory,
  });

  VibeSelectionScreenTwoModel? vibeSelectionScreenTwoModel;
  String? selectedCategory;

  @override
  List<Object?> get props => [
        vibeSelectionScreenTwoModel,
        selectedCategory,
      ];

  VibeSelectionScreenTwoState copyWith({
    VibeSelectionScreenTwoModel? vibeSelectionScreenTwoModel,
    String? selectedCategory,
  }) {
    return VibeSelectionScreenTwoState(
      vibeSelectionScreenTwoModel:
          vibeSelectionScreenTwoModel ?? this.vibeSelectionScreenTwoModel,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}
