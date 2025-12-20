import '../../../core/app_export.dart';
import '../models/notifications_model.dart';

part 'notifications_state.dart';

final notificationsNotifier = StateNotifierProvider.autoDispose<
    NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(
    NotificationsState(
      notificationsModel: NotificationsModel(),
    ),
  ),
);

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(super.state);

  void setNotifications(List<Map<String, dynamic>> notifications) {
    final unreadCount =
        notifications.where((n) => !(n['is_read'] as bool)).length;
    state = state.copyWith(
      notificationsModel: state.notificationsModel?.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      ),
    );
  }

  void updateUnreadCount(int count) {
    state = state.copyWith(
      notificationsModel: state.notificationsModel?.copyWith(
        unreadCount: count,
      ),
    );
  }

  void initialize() {
    state = state.copyWith(
      isLoading: true,
    );

    _loadNotifications();
  }

  void _loadNotifications() {
    // Simulate loading notifications
    List<NotificationItemModel> notifications = [
      NotificationItemModel(
        title: 'Jane sent you a friend request!',
        subtitle: 'Click here to view',
        timestamp: '2 hrs ago',
        iconPath: ImageConstant.imgButton,
        isRead: false,
      ),
      NotificationItemModel(
        title: 'Jane sent you a friend request!',
        subtitle: 'Click here to view',
        timestamp: '2 hrs ago',
        iconPath: ImageConstant.imgButton,
        isRead: false,
      ),
      NotificationItemModel(
        title: 'Jane sent you a friend request!',
        subtitle: 'Click here to view',
        timestamp: '2 hrs ago',
        iconPath: ImageConstant.imgButtonsBlueGray300,
        isRead: true,
      ),
      NotificationItemModel(
        title: 'Jane sent you a friend request!',
        subtitle: 'Click here to view',
        timestamp: '2 hrs ago',
        iconPath: ImageConstant.imgButtonsBlueGray300,
        isRead: true,
      ),
    ];

    state = state.copyWith(
      notificationsModel: NotificationsModel(
        notifications: notifications.map((item) => {
          'title': item.title,
          'subtitle': item.subtitle,
          'timestamp': item.timestamp,
          'icon_path': item.iconPath,
          'is_read': item.isRead,
        }).toList(),
      ),
      isLoading: false,
    );
  }

  void toggleMarkAllNotifications() {
    final notificationsData = state.notificationsModel?.notifications;
    if (notificationsData == null || notificationsData.isEmpty) return;

    // Check if there are any unread notifications
    final hasUnread =
        notificationsData.any((notification) => !(notification['is_read'] as bool? ?? false));

    // If there are unread notifications, mark all as read
    // Otherwise, mark all as unread
    final updatedNotifications = notificationsData.map((notification) {
      return {
        ...notification,
        'is_read': hasUnread ? true : false,
        'icon_path': hasUnread
            ? ImageConstant.imgButtonsBlueGray300
            : ImageConstant.imgButton,
      };
    }).toList();

    state = state.copyWith(
      notificationsModel: state.notificationsModel?.copyWith(
        notifications: updatedNotifications,
      ),
      isMarkAsReadSuccess: true,
      toggleMessage: hasUnread
          ? 'All notifications marked as read'
          : 'All notifications marked as unread',
    );

    // Reset success flag after a short delay
    Future.delayed(Duration(milliseconds: 100), () {
      state = state.copyWith(isMarkAsReadSuccess: false, toggleMessage: null);
    });
  }

  void markAllAsRead() {
    final notificationsData = state.notificationsModel?.notifications;
    final updatedNotifications =
        notificationsData?.map((notification) {
      return {
        ...notification,
        'is_read': true,
        'icon_path': ImageConstant.imgButtonsBlueGray300,
      };
    }).toList();

    state = state.copyWith(
      notificationsModel: state.notificationsModel?.copyWith(
        notifications: updatedNotifications,
      ),
      isMarkAsReadSuccess: true,
    );

    // Reset success flag after a short delay
    Future.delayed(Duration(milliseconds: 100), () {
      state = state.copyWith(isMarkAsReadSuccess: false);
    });
  }

  void handleNotificationTap(int index) {
    final notificationsData = state.notificationsModel?.notifications;
    if (notificationsData != null && index < notificationsData.length) {
      final notification = notificationsData[index];

      // Toggle notification read status
      final updatedNotifications =
          List<Map<String, dynamic>>.from(notificationsData);
      updatedNotifications[index] = {
        ...notification,
        'is_read': !(notification['is_read'] as bool? ?? false),
        'icon_path': !(notification['is_read'] as bool? ?? false)
            ? ImageConstant.imgButtonsBlueGray300
            : ImageConstant.imgButton,
      };

      state = state.copyWith(
        notificationsModel: state.notificationsModel?.copyWith(
          notifications: updatedNotifications,
        ),
      );

      // Handle navigation or action based on notification type
      // For friend requests, navigate to friends management
    }
  }
}