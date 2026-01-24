import '../../../core/app_export.dart';
import '../models/color_selection_model.dart';

part 'color_selection_state.dart';

final colorSelectionNotifier = StateNotifierProvider.autoDispose<
    ColorSelectionNotifier, ColorSelectionState>(
  (ref) => ColorSelectionNotifier(
    ColorSelectionState(
      colorSelectionModel: ColorSelectionModel(),
    ),
  ),
);

class ColorSelectionNotifier extends StateNotifier<ColorSelectionState> {
  ColorSelectionNotifier(ColorSelectionState state) : super(state) {
    initialize();
  }

  void initialize() {
    final colors = [
      ColorOptionModel(color: appTheme.white_A700),
      ColorOptionModel(color: appTheme.black_900),
      ColorOptionModel(color: appTheme.amber_600),
      ColorOptionModel(color: appTheme.red_500),
      ColorOptionModel(color: appTheme.blue_A200),
      ColorOptionModel(color: appTheme.teal_400),
    ];

    final themes = [
      ThemeOptionModel(title: 'classic', fontFamily: 'Roboto'),
      ThemeOptionModel(title: 'neon', fontFamily: 'Playfair Display'),
      ThemeOptionModel(title: 'typewriter', fontFamily: 'Courier Prime'),
    ];

    state = state.copyWith(
      colorSelectionModel: ColorSelectionModel(
        colors: colors,
        themes: themes,
      ),
      selectedColorIndex: 0,
      selectedThemeIndex: 0,
    );
  }

  void selectColor(int index) {
    state = state.copyWith(
      selectedColorIndex: index,
    );
  }

  void selectTheme(int index) {
    state = state.copyWith(
      selectedThemeIndex: index,
    );
  }

  ColorOptionModel? getSelectedColor() {
    final colors = state.colorSelectionModel?.colors ?? [];
    final selectedIndex = state.selectedColorIndex ?? 0;

    if (selectedIndex >= 0 && selectedIndex < colors.length) {
      return colors[selectedIndex];
    }
    return null;
  }

  ThemeOptionModel? getSelectedTheme() {
    final themes = state.colorSelectionModel?.themes ?? [];
    final selectedIndex = state.selectedThemeIndex ?? 0;

    if (selectedIndex >= 0 && selectedIndex < themes.length) {
      return themes[selectedIndex];
    }
    return null;
  }
}
