part of 'color_selection_notifier.dart';

class ColorSelectionState extends Equatable {
  final ColorSelectionModel? colorSelectionModel;
  final int? selectedColorIndex;
  final int? selectedThemeIndex;
  final bool? isLoading;

  ColorSelectionState({
    this.colorSelectionModel,
    this.selectedColorIndex,
    this.selectedThemeIndex,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
        colorSelectionModel,
        selectedColorIndex,
        selectedThemeIndex,
        isLoading,
      ];

  ColorSelectionState copyWith({
    ColorSelectionModel? colorSelectionModel,
    int? selectedColorIndex,
    int? selectedThemeIndex,
    bool? isLoading,
  }) {
    return ColorSelectionState(
      colorSelectionModel: colorSelectionModel ?? this.colorSelectionModel,
      selectedColorIndex: selectedColorIndex ?? this.selectedColorIndex,
      selectedThemeIndex: selectedThemeIndex ?? this.selectedThemeIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
