/// Typed navigation contract for memory-related screens
///
/// This ensures consistent, type-safe memory data transfer throughout the app.
/// Required memory ID prevents silent failures with dummy data.
class MemoryNavArgs {
  final String memoryId;
  final MemorySnapshot? snapshot;
  final String? initialStoryId; // NEW: For deep link story navigation

  MemoryNavArgs({
    required this.memoryId,
    this.snapshot,
    this.initialStoryId, // NEW
  });

  bool get isValid => memoryId.isNotEmpty;

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
      initialStoryId: map['initialStoryId'] as String?, // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memoryId': memoryId,
      'id': memoryId,
      if (snapshot != null) 'snapshot': snapshot!.toMap(),
      if (initialStoryId != null) 'initialStoryId': initialStoryId, // NEW
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
