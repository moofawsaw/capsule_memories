import '../../../core/app_export.dart';
import './story_item_model.dart';

/// Used in [UserProfileScreenTwo]
/// Email is OPTIONAL and must only be set for the current user
// ignore_for_file: must_be_immutable

class UserProfileScreenTwoModel extends Equatable {
  UserProfileScreenTwoModel({
    this.avatarImagePath,

    /// ✅ Canonical fields (match DB intent)
    this.displayName, // DB: display_name
    this.username, // DB: username

    /// ⚠️ PRIVATE FIELD — ONLY for current user
    this.email,

    this.followersCount,
    this.followingCount,
    this.storyItems,
    this.id,
  }) {
    avatarImagePath ??= ImageConstant.imgEllipse896x96;

    // Defaults
    displayName ??= 'User';
    username ??= ''; // do NOT force default username
    followersCount ??= '0';
    followingCount ??= '0';
    storyItems ??= [];
    id ??= '';
    // 🚫 DO NOT default email
  }

  String? avatarImagePath;

  /// ✅ display_name from DB (human-readable)
  String? displayName;

  /// ✅ username from DB (handle without @, store raw)
  String? username;

  /// ⚠️ PRIVATE FIELD — ONLY for current user
  String? email;

  String? followersCount;
  String? followingCount;
  List<StoryItemModel>? storyItems;
  String? id;

  /// ✅ Backward-compatible alias:
  /// existing code that uses model.userName will still work.
  String? get userName => displayName;
  set userName(String? v) => displayName = v;

  UserProfileScreenTwoModel copyWith({
    String? avatarImagePath,

    /// New canonical fields
    String? displayName,
    String? username,

    /// Backward compat: allow callers to pass userName and treat it as displayName
    String? userName,

    String? email,
    bool clearEmail = false,
    String? followersCount,
    String? followingCount,
    List<StoryItemModel>? storyItems,
    String? id,
  }) {
    return UserProfileScreenTwoModel(
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,

      // Prefer explicit displayName, then userName alias, then existing
      displayName: displayName ?? userName ?? this.displayName,
      username: username ?? this.username,

      email: clearEmail ? null : (email ?? this.email),
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      storyItems: storyItems ?? this.storyItems,
      id: id ?? this.id,
    );
  }

  @override
  List<Object?> get props => [
    avatarImagePath,
    displayName,
    username,
    email,
    followersCount,
    followingCount,
    storyItems,
    id,
  ];
}
