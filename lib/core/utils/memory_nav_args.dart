/// Typed navigation contract for memory-related screens
///
/// This ensures consistent, type-safe memory data transfer throughout the app.
/// Required memory ID prevents silent failures with dummy data.
class MemoryNavArgs {
  /// Required: Memory ID for database queries
  final String memoryId;

  /// Optional: Memory snapshot for immediate display while loading full data
  final MemorySnapshot? snapshot;

  MemoryNavArgs({
    required this.memoryId,
    this.snapshot,
  });

  /// Validate that memory ID is non-empty
  bool get isValid => memoryId.isNotEmpty;

  /// Create from Map (for ModalRoute arguments)
  ///
  /// Supports multiple keys for backward compatibility:
  /// - memoryId (preferred)
  /// - id (legacy)
  /// - memory_id (legacy)
  factory MemoryNavArgs.fromMap(Map<String, dynamic> map) {
    final String id =
        (map['memoryId'] as String?) ??
            (map['id'] as String?) ??
            (map['memory_id'] as String?) ??
            '';

    return MemoryNavArgs(
      memoryId: id,
      snapshot: map['snapshot'] is Map<String, dynamic>
          ? MemorySnapshot.fromMap(map['snapshot'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to Map (for navigation)
  ///
  /// Emits both keys for compatibility across older call sites.
  Map<String, dynamic> toMap() {
    return {
      'memoryId': memoryId,
      'id': memoryId, // legacy compatibility
      if (snapshot != null) 'snapshot': snapshot!.toMap(),
    };
  }
}

/// Optional memory snapshot for immediate display
/// Contains essential display fields to show while full data loads
class MemorySnapshot {
  final String title;
  final String date;
  final String? location;
  final String? categoryIcon;
  final List<String>? participantAvatars;
  final bool isPrivate;

  MemorySnapshot({
    required this.title,
    required this.date,
    this.location,
    this.categoryIcon,
    this.participantAvatars,
    this.isPrivate = false,
  });

  factory MemorySnapshot.fromMap(Map<String, dynamic> map) {
    return MemorySnapshot(
      title: map['title'] as String? ?? 'Memory',
      date: map['date'] as String? ?? '',
      location: map['location'] as String?,
      categoryIcon: map['category_icon'] as String?,
      participantAvatars: map['contributor_avatars'] != null
          ? (map['contributor_avatars'] as List).map((e) => e.toString()).toList()
          : null,
      isPrivate: map['visibility'] == 'private',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      if (location != null) 'location': location,
      if (categoryIcon != null) 'category_icon': categoryIcon,
      if (participantAvatars != null) 'contributor_avatars': participantAvatars,
      'visibility': isPrivate ? 'private' : 'public',
    };
  }
}
