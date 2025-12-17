class MemoryCategory {
  final String name;
  final String emoji;
  final String subtext;

  const MemoryCategory({
    required this.name,
    required this.emoji,
    required this.subtext,
  });
}

class MemoryCategories {
  static const hangout = MemoryCategory(
    name: 'Hangout',
    emoji: '😻',
    subtext: 'just hangin around',
  );

  static const party = MemoryCategory(
    name: 'Party',
    emoji: '🎉',
    subtext: 'Ok lesgooooo',
  );

  static const school = MemoryCategory(
    name: 'School',
    emoji: '📚',
    subtext: 'ring my bellllll',
  );

  static const roadTrip = MemoryCategory(
    name: 'Road Trip',
    emoji: '🚗',
    subtext: 'hop in loser',
  );

  static const festival = MemoryCategory(
    name: 'Festival',
    emoji: '🔥',
    subtext: 'jump around',
  );

  static const concert = MemoryCategory(
    name: 'Concert',
    emoji: '🎵',
    subtext: 'back.streets.back',
  );

  static const wedding = MemoryCategory(
    name: 'Wedding',
    emoji: '💒',
    subtext: 'always a bridesmaid',
  );

  static const vacation = MemoryCategory(
    name: 'Vacation',
    emoji: '✈️',
    subtext: 'up up & away',
  );

  static const custom = MemoryCategory(
    name: 'Custom',
    emoji: '⭐',
    subtext: 'and so it begins',
  );

  static List<MemoryCategory> get all => [
        hangout,
        party,
        school,
        roadTrip,
        festival,
        concert,
        wedding,
        vacation,
        custom,
      ];

  static MemoryCategory getByName(String name) {
    return all.firstWhere(
      (category) => category.name.toLowerCase() == name.toLowerCase(),
      orElse: () => custom,
    );
  }
}
