class MemorySelectionModel {
  final List<MemoryItem> activeMemories;
  final List<MemoryItem> filteredMemories;
  final bool isLoading;
  final String? errorMessage;
  final String? searchQuery;

  const MemorySelectionModel({
    this.activeMemories = const [],
    this.filteredMemories = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery,
  });

  MemorySelectionModel copyWith({
    List<MemoryItem>? activeMemories,
    List<MemoryItem>? filteredMemories,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return MemorySelectionModel(
      activeMemories: activeMemories ?? this.activeMemories,
      filteredMemories: filteredMemories ?? this.filteredMemories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeMemories': activeMemories.map((item) => item.toJson()).toList(),
      'filteredMemories':
          filteredMemories.map((item) => item.toJson()).toList(),
      'isLoading': isLoading,
      'errorMessage': errorMessage,
      'searchQuery': searchQuery,
    };
  }

  factory MemorySelectionModel.fromJson(Map<String, dynamic> json) {
    return MemorySelectionModel(
      activeMemories: (json['activeMemories'] as List<dynamic>?)
              ?.map((e) => MemoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      filteredMemories: (json['filteredMemories'] as List<dynamic>?)
              ?.map((e) => MemoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isLoading: json['isLoading'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
      searchQuery: json['searchQuery'] as String?,
    );
  }
}

class MemoryItem {
  final String? id;
  final String? title;
  final String? categoryIcon;
  final String? categoryName;
  final int? memberCount;
  final String? timeRemaining;
  final DateTime? expiresAt;

  const MemoryItem({
    this.id,
    this.title,
    this.categoryIcon,
    this.categoryName,
    this.memberCount,
    this.timeRemaining,
    this.expiresAt,
  });

  MemoryItem copyWith({
    String? id,
    String? title,
    String? categoryIcon,
    String? categoryName,
    int? memberCount,
    String? timeRemaining,
    DateTime? expiresAt,
  }) {
    return MemoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryName: categoryName ?? this.categoryName,
      memberCount: memberCount ?? this.memberCount,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'categoryIcon': categoryIcon,
      'categoryName': categoryName,
      'memberCount': memberCount,
      'timeRemaining': timeRemaining,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String?,
      title: json['title'] as String?,
      categoryIcon: json['categoryIcon'] as String?,
      categoryName: json['categoryName'] as String?,
      memberCount: json['memberCount'] as int?,
      timeRemaining: json['timeRemaining'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}
