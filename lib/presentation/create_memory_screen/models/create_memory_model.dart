/// This class is used in the [CreateMemoryScreen] screen.

// ignore_for_file: must_be_immutable
class CreateMemoryModel {
  String? memoryName;
  bool isPublic;
  String? selectedGroup;
  String? searchQuery;
  List<Map<String, dynamic>> searchResults;
  Set<String> invitedUserIds;
  List<Map<String, dynamic>> groupMembers;

  CreateMemoryModel({
    this.memoryName,
    this.isPublic = true,
    this.selectedGroup,
    this.searchQuery,
    List<Map<String, dynamic>>? searchResults,
    Set<String>? invitedUserIds,
    List<Map<String, dynamic>>? groupMembers,
  })  : searchResults = searchResults ?? [],
        invitedUserIds = invitedUserIds ?? {},
        groupMembers = groupMembers ?? [];

  CreateMemoryModel copyWith({
    String? memoryName,
    bool? isPublic,
    String? selectedGroup,
    String? searchQuery,
    List<Map<String, dynamic>>? searchResults,
    Set<String>? invitedUserIds,
    List<Map<String, dynamic>>? groupMembers,
  }) {
    return CreateMemoryModel(
      memoryName: memoryName ?? this.memoryName,
      isPublic: isPublic ?? this.isPublic,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      invitedUserIds: invitedUserIds ?? this.invitedUserIds,
      groupMembers: groupMembers ?? this.groupMembers,
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

  // Get group members based on selected group
  static List<Map<String, dynamic>> getGroupMembers(String groupId) {
    final Map<String, List<Map<String, dynamic>>> groupData = {
      'family': [
        {
          'id': 'member1',
          'name': 'John Smith',
          'username': 'johnsmith',
          'avatar':
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        },
        {
          'id': 'member2',
          'name': 'Emma Smith',
          'username': 'emmasmith',
          'avatar':
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        },
        {
          'id': 'member3',
          'name': 'David Smith',
          'username': 'davidsmith',
          'avatar':
              'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
        },
      ],
      'friends': [
        {
          'id': 'friend1',
          'name': 'Alex Martinez',
          'username': 'alexm',
          'avatar':
              'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
        },
        {
          'id': 'friend2',
          'name': 'Taylor Brown',
          'username': 'taylorbrown',
          'avatar':
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
        },
        {
          'id': 'friend3',
          'name': 'Jordan Lee',
          'username': 'jordanlee',
          'avatar':
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
        },
        {
          'id': 'friend4',
          'name': 'Casey Morgan',
          'username': 'caseym',
          'avatar':
              'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=150',
        },
      ],
      'work': [
        {
          'id': 'work1',
          'name': 'Jennifer Davis',
          'username': 'jdavis',
          'avatar':
              'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
        },
        {
          'id': 'work2',
          'name': 'Robert Garcia',
          'username': 'rgarcia',
          'avatar':
              'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
        },
        {
          'id': 'work3',
          'name': 'Patricia Miller',
          'username': 'pmiller',
          'avatar':
              'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
        },
      ],
      'school': [
        {
          'id': 'school1',
          'name': 'Chris Thompson',
          'username': 'cthompson',
          'avatar':
              'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150',
        },
        {
          'id': 'school2',
          'name': 'Morgan White',
          'username': 'mwhite',
          'avatar':
              'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150',
        },
        {
          'id': 'school3',
          'name': 'Ashley Clark',
          'username': 'aclark',
          'avatar':
              'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150',
        },
        {
          'id': 'school4',
          'name': 'Ryan Lewis',
          'username': 'rlewis',
          'avatar':
              'https://images.unsplash.com/photo-1552374196-c4e7ffc6e126?w=150',
        },
        {
          'id': 'school5',
          'name': 'Nicole Walker',
          'username': 'nwalker',
          'avatar':
              'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150',
        },
      ],
    };

    return groupData[groupId] ?? [];
  }
}
