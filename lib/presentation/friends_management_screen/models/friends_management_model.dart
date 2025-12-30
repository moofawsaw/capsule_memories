import '../../../core/app_export.dart';

/// This class is used in the [friends_management_screen] screen.

// ignore_for_file: must_be_immutable
class FriendsManagementModel extends Equatable {
  FriendsManagementModel({
    this.friendsList,
    this.sentRequestsList,
    this.incomingRequestsList,
  }) {
    friendsList = friendsList ?? [];
    sentRequestsList = sentRequestsList ?? [];
    incomingRequestsList = incomingRequestsList ?? [];
  }

  List<FriendModel>? friendsList;
  List<SentRequestModel>? sentRequestsList;
  List<IncomingRequestModel>? incomingRequestsList;

  FriendsManagementModel copyWith({
    List<FriendModel>? friendsList,
    List<SentRequestModel>? sentRequestsList,
    List<IncomingRequestModel>? incomingRequestsList,
  }) {
    return FriendsManagementModel(
      friendsList: friendsList ?? this.friendsList,
      sentRequestsList: sentRequestsList ?? this.sentRequestsList,
      incomingRequestsList: incomingRequestsList ?? this.incomingRequestsList,
    );
  }

  @override
  List<Object?> get props => [
        friendsList,
        sentRequestsList,
        incomingRequestsList,
      ];
}

class FriendModel extends Equatable {
  FriendModel({
    this.id,
    this.friendshipId,
    this.profileImagePath,
    this.userName,
    this.displayName,
  });

  String? id;
  String? friendshipId;
  String? profileImagePath;
  String? userName;
  String? displayName;

  FriendModel copyWith({
    String? id,
    String? friendshipId,
    String? profileImagePath,
    String? userName,
    String? displayName,
  }) {
    return FriendModel(
      id: id ?? this.id,
      friendshipId: friendshipId ?? this.friendshipId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      userName: userName ?? this.userName,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  List<Object?> get props =>
      [id, friendshipId, profileImagePath, userName, displayName];
}

class SentRequestModel extends Equatable {
  SentRequestModel({
    this.id,
    this.userId,
    this.profileImagePath,
    this.userName,
    this.displayName,
    this.status,
  });

  String? id;
  String? userId;
  String? profileImagePath;
  String? userName;
  String? displayName;
  String? status;

  SentRequestModel copyWith({
    String? id,
    String? userId,
    String? profileImagePath,
    String? userName,
    String? displayName,
    String? status,
  }) {
    return SentRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      userName: userName ?? this.userName,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, profileImagePath, userName, displayName, status];
}

class IncomingRequestModel extends Equatable {
  IncomingRequestModel({
    this.id,
    this.userId,
    this.profileImagePath,
    this.userName,
    this.displayName,
    this.bio,
    this.buttonText,
  });

  String? id;
  String? userId;
  String? profileImagePath;
  String? userName;
  String? displayName;
  String? bio;
  String? buttonText;

  IncomingRequestModel copyWith({
    String? id,
    String? userId,
    String? profileImagePath,
    String? userName,
    String? displayName,
    String? bio,
    String? buttonText,
  }) {
    return IncomingRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      userName: userName ?? this.userName,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      buttonText: buttonText ?? this.buttonText,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, profileImagePath, userName, displayName, bio, buttonText];
}

class SearchUserModel extends Equatable {
  SearchUserModel({
    this.id,
    this.profileImagePath,
    this.userName,
    this.displayName,
    this.bio,
    this.friendshipStatus = 'none',
  });

  String? id;
  String? profileImagePath;
  String? userName;
  String? displayName;
  String? bio;
  String friendshipStatus;

  SearchUserModel copyWith({
    String? id,
    String? profileImagePath,
    String? userName,
    String? displayName,
    String? bio,
    String? friendshipStatus,
  }) {
    return SearchUserModel(
      id: id ?? this.id,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      userName: userName ?? this.userName,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
    );
  }

  @override
  List<Object?> get props =>
      [id, profileImagePath, userName, displayName, bio, friendshipStatus];
}
