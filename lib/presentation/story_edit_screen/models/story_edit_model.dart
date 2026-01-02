class StoryEditModel {
  final String videoPath;
  final String memoryId;
  final String memoryTitle;
  final String? categoryIcon;
  final String caption;
  final List<TextOverlay> textOverlays;
  final List<String> stickers;
  final List<Drawing> drawings;
  final String? backgroundMusic;

  StoryEditModel({
    required this.videoPath,
    required this.memoryId,
    required this.memoryTitle,
    this.categoryIcon,
    this.caption = '',
    this.textOverlays = const [],
    this.stickers = const [],
    this.drawings = const [],
    this.backgroundMusic,
  });

  StoryEditModel copyWith({
    String? videoPath,
    String? memoryId,
    String? memoryTitle,
    String? categoryIcon,
    String? caption,
    List<TextOverlay>? textOverlays,
    List<String>? stickers,
    List<Drawing>? drawings,
    String? backgroundMusic,
  }) {
    return StoryEditModel(
      videoPath: videoPath ?? this.videoPath,
      memoryId: memoryId ?? this.memoryId,
      memoryTitle: memoryTitle ?? this.memoryTitle,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      caption: caption ?? this.caption,
      textOverlays: textOverlays ?? this.textOverlays,
      stickers: stickers ?? this.stickers,
      drawings: drawings ?? this.drawings,
      backgroundMusic: backgroundMusic ?? this.backgroundMusic,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'video_path': videoPath,
      'memory_id': memoryId,
      'memory_title': memoryTitle,
      if (categoryIcon != null) 'category_icon': categoryIcon,
      'caption': caption,
      'text_overlays': textOverlays.map((overlay) => overlay.toJson()).toList(),
      'stickers': stickers,
      'drawings': drawings.map((drawing) => drawing.toJson()).toList(),
      if (backgroundMusic != null) 'background_music': backgroundMusic,
    };
  }
}

class TextOverlay {
  final String text;
  final double x;
  final double y;
  final String fontFamily;
  final double fontSize;
  final String color;

  TextOverlay({
    required this.text,
    required this.x,
    required this.y,
    this.fontFamily = 'PlusJakartaSans',
    this.fontSize = 24.0,
    this.color = '#FFFFFF',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'x': x,
      'y': y,
      'font_family': fontFamily,
      'font_size': fontSize,
      'color': color,
    };
  }
}

class Drawing {
  final List<DrawingPoint> points;
  final String color;
  final double strokeWidth;

  Drawing({
    required this.points,
    required this.color,
    this.strokeWidth = 3.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => point.toJson()).toList(),
      'color': color,
      'stroke_width': strokeWidth,
    };
  }
}

class DrawingPoint {
  final double x;
  final double y;

  DrawingPoint({required this.x, required this.y});

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}
