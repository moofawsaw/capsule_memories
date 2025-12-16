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
    this.profileImagePath,
    this.userName,
  });

  String? id;
  String? profileImagePath;
  String? userName;

  FriendModel copyWith({
    String? id,
    String? profileImagePath,
    String? userName,
  }) {
    return FriendModel(
      id: id ?? this.id,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [id, profileImagePath, userName];
}

class SentRequestModel extends Equatable {
  SentRequestModel({
    this.id,
    this.profileImagePath,
    this.userName,
    this.status,
  });

  String? id;
  String? profileImagePath;
  String? userName;
  String? status;

  SentRequestModel copyWith({
    String? id,
    String? profileImagePath,
    String? userName,
    String? status,
  }) {
    return SentRequestModel(
      id: id ?? this.id,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      userName: userName ?? this.userName,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, profileImagePath, userName, status];
}

class IncomingRequestModel extends Equatable {
  IncomingRequestModel({
    this.id,
    this.profileImagePath,
    this.userName,
    this.buttonText,
  });

  String? id;
  String? profileImagePath;
  String? userName;
  String? buttonText;

  IncomingRequestModel copyWith({
    String? id,
    String? profileImagePath,
    String? userName,
    String? buttonText,
  }) {
    return IncomingRequestModel(
      id: id ?? this.id,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      userName: userName ?? this.userName,
      buttonText: buttonText ?? this.buttonText,
    );
  }

  @override
  List<Object?> get props => [id, profileImagePath, userName, buttonText];
}
