import '../../../core/app_export.dart';
import 'package:flutter/material.dart';

/// This class is used in the [VibeSelectionScreenTwo] screen.

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
