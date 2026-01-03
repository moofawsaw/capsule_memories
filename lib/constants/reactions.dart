/// Reaction type definitions matching the database schema
class ReactionType {
  final String id;
  final String display;
  final bool isEmoji;

  const ReactionType({
    required this.id,
    required this.display,
    required this.isEmoji,
  });
}

class Reactions {
  // Text reactions (matching reaction_text enum values in database)
  static const lol = ReactionType(id: 'lol', display: 'LOL', isEmoji: false);
  static const hot = ReactionType(id: 'hot', display: 'HOTT', isEmoji: false);
  static const wild = ReactionType(id: 'wild', display: 'WILD', isEmoji: false);
  static const omg = ReactionType(id: 'omg', display: 'OMG', isEmoji: false);

  // Emoji reactions (matching reaction_emoji enum values in database)
  static const fire = ReactionType(id: 'fire', display: '🔥', isEmoji: true);
  static const cry = ReactionType(id: 'cry', display: '😂', isEmoji: true);
  static const heart = ReactionType(id: 'heart', display: '❤️', isEmoji: true);
  static const thumbsUp =
      ReactionType(id: 'thumbs_up', display: '👍', isEmoji: true);

  // Text reactions first, emojis second
  static const List<ReactionType> textReactions = [
    lol,
    hot,
    wild,
    omg,
  ];

  static const List<ReactionType> emojiReactions = [
    fire,
    cry,
    heart,
    thumbsUp,
  ];

  static const List<ReactionType> all = [
    ...textReactions,
    ...emojiReactions,
  ];

  static ReactionType? fromId(String id) {
    try {
      return all.firstWhere((r) => r.id == id);
    } catch (e) {
      return fire; // Default fallback
    }
  }
}
