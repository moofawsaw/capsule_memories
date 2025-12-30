import 'package:flutter/foundation.dart';

@immutable
class MemoryShareOptionsModel {
  final String memoryId;
  final String memoryName;
  final String? inviteCode;
  final bool isLoading;
  final bool isSendingInvites;
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> groups;
  final Set<String> selectedFriends;
  final Set<String> selectedGroups;
  final String friendSearchQuery;

  const MemoryShareOptionsModel({
    this.memoryId = '',
    this.memoryName = '',
    this.inviteCode,
    this.isLoading = true,
    this.isSendingInvites = false,
    this.friends = const [],
    this.groups = const [],
    this.selectedFriends = const {},
    this.selectedGroups = const {},
    this.friendSearchQuery = '',
  });

  List<Map<String, dynamic>> get filteredFriends {
    if (friendSearchQuery.isEmpty) return friends;

    final query = friendSearchQuery.toLowerCase();
    return friends.where((friend) {
      final name = (friend['display_name'] ?? '').toString().toLowerCase();
      final username = (friend['username'] ?? '').toString().toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  MemoryShareOptionsModel copyWith({
    String? memoryId,
    String? memoryName,
    String? inviteCode,
    bool? isLoading,
    bool? isSendingInvites,
    List<Map<String, dynamic>>? friends,
    List<Map<String, dynamic>>? groups,
    Set<String>? selectedFriends,
    Set<String>? selectedGroups,
    String? friendSearchQuery,
  }) {
    return MemoryShareOptionsModel(
      memoryId: memoryId ?? this.memoryId,
      memoryName: memoryName ?? this.memoryName,
      inviteCode: inviteCode ?? this.inviteCode,
      isLoading: isLoading ?? this.isLoading,
      isSendingInvites: isSendingInvites ?? this.isSendingInvites,
      friends: friends ?? this.friends,
      groups: groups ?? this.groups,
      selectedFriends: selectedFriends ?? this.selectedFriends,
      selectedGroups: selectedGroups ?? this.selectedGroups,
      friendSearchQuery: friendSearchQuery ?? this.friendSearchQuery,
    );
  }
}
