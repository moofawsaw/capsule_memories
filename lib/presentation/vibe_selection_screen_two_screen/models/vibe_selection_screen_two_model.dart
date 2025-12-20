import '../../../core/app_export.dart';

/// This class is used in the [VibeSelectionScreenTwo] screen.

// ignore_for_file: must_be_immutable
class VibeSelectionScreenTwoModel extends Equatable {
  VibeSelectionScreenTwoModel({
    this.selectedVibe,
    this.id,
  }) {
    selectedVibe = selectedVibe ?? "";
    id = id ?? "";
  }

  String? selectedVibe;
  String? id;

  VibeSelectionScreenTwoModel copyWith({
    String? selectedVibe,
    String? id,
  }) {
    return VibeSelectionScreenTwoModel(
      selectedVibe: selectedVibe ?? this.selectedVibe,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
        selectedVibe,
        id,
      ];
}

class VibeItem extends Equatable {
  VibeItem({
    required this.id,
    required this.label,
    required this.image,
    required this.isEmoji,
    required this.backgroundColor,
    required this.textColor,
  });

  String id;
  String label;
  String image;
  bool isEmoji;
  Color backgroundColor;
  Color textColor;

  VibeItem copyWith({
    String? id,
    String? label,
    String? image,
    bool? isEmoji,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return VibeItem(
      id: id ?? this.id,
      label: label ?? this.label,
      image: image ?? this.image,
      isEmoji: isEmoji ?? this.isEmoji,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        image,
        isEmoji,
        backgroundColor,
        textColor,
      ];
}
