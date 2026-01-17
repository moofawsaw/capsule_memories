class AppUser {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: (map['id'] ?? '') as String,
      username: map['username'] as String?,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  String get displayLabel {
    final name = (fullName ?? '').trim();
    final user = (username ?? '').trim();
    if (name.isNotEmpty && user.isNotEmpty) return '$name • @$user';
    if (name.isNotEmpty) return name;
    if (user.isNotEmpty) return '@$user';
    return 'User';
  }

  bool matchesQuery(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return false;

    final u = (username ?? '').toLowerCase();
    final n = (fullName ?? '').toLowerCase();

    return u.contains(query) ||
        n.contains(query) ||
        displayLabel.toLowerCase().contains(query);
  }
}
