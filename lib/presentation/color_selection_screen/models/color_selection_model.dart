import '../../../core/app_export.dart';

/// This class is used in the [ColorSelectionScreen] screen.

// ignore_for_file: must_be_immutable
class ColorSelectionModel extends Equatable {
  ColorSelectionModel({
    this.colors,
    this.themes,
    this.id,
  }) {
    colors = colors ?? [];
    themes = themes ?? [];
    id = id ?? "";
  }

  List<ColorOptionModel>? colors;
  List<ThemeOptionModel>? themes;
  String? id;

  ColorSelectionModel copyWith({
    List<ColorOptionModel>? colors,
    List<ThemeOptionModel>? themes,
    String? id,
  }) {
    return ColorSelectionModel(
      colors: colors ?? this.colors,
      themes: themes ?? this.themes,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [colors, themes, id];
}

// ignore_for_file: must_be_immutable
class ColorOptionModel extends Equatable {
  ColorOptionModel({
    this.color,
    this.isSelected,
    this.id,
  }) {
    color = color ?? Colors.white;
    isSelected = isSelected ?? false;
    id = id ?? "";
  }

  Color? color;
  bool? isSelected;
  String? id;

  ColorOptionModel copyWith({
    Color? color,
    bool? isSelected,
    String? id,
  }) {
    return ColorOptionModel(
      color: color ?? this.color,
      isSelected: isSelected ?? this.isSelected,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [color, isSelected, id];
}

// ignore_for_file: must_be_immutable
class ThemeOptionModel extends Equatable {
  ThemeOptionModel({
    this.title,
    this.fontFamily,
    this.isSelected,
    this.id,
  }) {
    title = title ?? "";
    fontFamily = fontFamily ?? "";
    isSelected = isSelected ?? false;
    id = id ?? "";
  }

  String? title;
  String? fontFamily;
  bool? isSelected;
  String? id;

  ThemeOptionModel copyWith({
    String? title,
    String? fontFamily,
    bool? isSelected,
    String? id,
  }) {
    return ThemeOptionModel(
      title: title ?? this.title,
      fontFamily: fontFamily ?? this.fontFamily,
      isSelected: isSelected ?? this.isSelected,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [title, fontFamily, isSelected, id];
}
