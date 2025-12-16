import '../../../core/app_export.dart';

/// This class is used in the [notifications_screen] screen.

// ignore_for_file: must_be_immutable
class NotificationsModel extends Equatable {
  NotificationsModel({this.notificationsList}) {
    notificationsList = notificationsList ?? [];
  }

  List<NotificationItemModel>? notificationsList;

  NotificationsModel copyWith({
    List<NotificationItemModel>? notificationsList,
  }) {
    return NotificationsModel(
      notificationsList: notificationsList ?? this.notificationsList,
    );
  }

  @override
  List<Object?> get props => [notificationsList];
}

// ignore_for_file: must_be_immutable
class NotificationItemModel extends Equatable {
  NotificationItemModel({
    this.title,
    this.subtitle,
    this.timestamp,
    this.iconPath,
    this.isRead,
  }) {
    title = title ?? "Jane sent you a friend request!";
    subtitle = subtitle ?? "Click here to view";
    timestamp = timestamp ?? "2 hrs ago";
    iconPath = iconPath ?? ImageConstant.imgButton;
    isRead = isRead ?? false;
  }

  String? title;
  String? subtitle;
  String? timestamp;
  String? iconPath;
  bool? isRead;

  NotificationItemModel copyWith({
    String? title,
    String? subtitle,
    String? timestamp,
    String? iconPath,
    bool? isRead,
  }) {
    return NotificationItemModel(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      timestamp: timestamp ?? this.timestamp,
      iconPath: iconPath ?? this.iconPath,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [title, subtitle, timestamp, iconPath, isRead];
}
