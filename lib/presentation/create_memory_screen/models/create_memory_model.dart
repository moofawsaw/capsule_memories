/// This class is used in the [CreateMemoryScreen] screen.

// ignore_for_file: must_be_immutable
class CreateMemoryModel {
  String? memoryName;
  bool isPublic;
  String? selectedGroup;
  String? selectedCategory;
  String? searchQuery;
  List<Map<String, dynamic>> searchResults;
  Set<String> invitedUserIds;
  List<Map<String, dynamic>> groupMembers;
  List<Map<String, dynamic>> availableGroups;
  List<Map<String, dynamic>> availableCategories;

  CreateMemoryModel({
    this.memoryName,
    this.isPublic = true,
    this.selectedGroup,
    this.selectedCategory,
    this.searchQuery,
    List<Map<String, dynamic>>? searchResults,
    Set<String>? invitedUserIds,
    List<Map<String, dynamic>>? groupMembers,
    List<Map<String, dynamic>>? availableGroups,
    List<Map<String, dynamic>>? availableCategories,
  })  : searchResults = searchResults ?? [],
        invitedUserIds = invitedUserIds ?? {},
        groupMembers = groupMembers ?? [],
        availableGroups = availableGroups ?? [],
        availableCategories = availableCategories ?? [];

  CreateMemoryModel copyWith({
    String? memoryName,
    bool? isPublic,
    String? selectedGroup,
    String? selectedCategory,
    String? searchQuery,
    List<Map<String, dynamic>>? searchResults,
    Set<String>? invitedUserIds,
    List<Map<String, dynamic>>? groupMembers,
    List<Map<String, dynamic>>? availableGroups,
    List<Map<String, dynamic>>? availableCategories,
  }) {
    return CreateMemoryModel(
      memoryName: memoryName ?? this.memoryName,
      isPublic: isPublic ?? this.isPublic,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      invitedUserIds: invitedUserIds ?? this.invitedUserIds,
      groupMembers: groupMembers ?? this.groupMembers,
      availableGroups: availableGroups ?? this.availableGroups,
      availableCategories: availableCategories ?? this.availableCategories,
    );
  }

  // Mock users for search results
  static List<Map<String, dynamic>> _getMockUsers() {
    return [
      {
        'id': 'user1',
        'name': 'Sarah Johnson',
        'username': 'sarahj',
        'avatar':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      },
      {
        'id': 'user2',
        'name': 'Michael Chen',
        'username': 'mchen',
        'avatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      },
      {
        'id': 'user3',
        'name': 'Emily Rodriguez',
        'username': 'emilyrod',
        'avatar':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
      },
      {
        'id': 'user4',
        'name': 'James Wilson',
        'username': 'jwilson',
        'avatar':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      },
      {
        'id': 'user5',
        'name': 'Lisa Anderson',
        'username': 'lisaa',
        'avatar':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      },
    ];
  }

  // Filter users based on search query
  List<Map<String, dynamic>> getFilteredUsers() {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return [];
    }

    final query = searchQuery!.toLowerCase();
    return _getMockUsers().where((user) {
      final name = (user['name'] as String).toLowerCase();
      final username = (user['username'] as String).toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }
}
