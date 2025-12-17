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
  NotificationsNotifier(NotificationsState state) : super(state) {
    initialize();
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
      notificationsModel: state.notificationsModel?.copyWith(
        notificationsList: notifications,
      ),
      isLoading: false,
    );
  }

  void toggleMarkAllNotifications() {
    final notifications = state.notificationsModel?.notificationsList;
    if (notifications == null || notifications.isEmpty) return;

    // Check if there are any unread notifications
    final hasUnread =
        notifications.any((notification) => !(notification.isRead ?? false));

    // If there are unread notifications, mark all as read
    // Otherwise, mark all as unread
    final updatedNotifications = notifications.map((notification) {
      return notification.copyWith(
        isRead: hasUnread ? true : false,
        iconPath: hasUnread
            ? ImageConstant.imgButtonsBlueGray300
            : ImageConstant.imgButton,
      );
    }).toList();

    state = state.copyWith(
      notificationsModel: state.notificationsModel?.copyWith(
        notificationsList: updatedNotifications,
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
    final updatedNotifications =
        state.notificationsModel?.notificationsList?.map((notification) {
      return notification.copyWith(
        isRead: true,
        iconPath: ImageConstant.imgButtonsBlueGray300,
      );
    }).toList();

    state = state.copyWith(
      notificationsModel: state.notificationsModel?.copyWith(
        notificationsList: updatedNotifications,
      ),
      isMarkAsReadSuccess: true,
    );

    // Reset success flag after a short delay
    Future.delayed(Duration(milliseconds: 100), () {
      state = state.copyWith(isMarkAsReadSuccess: false);
    });
  }

  void handleNotificationTap(int index) {
    final notifications = state.notificationsModel?.notificationsList;
    if (notifications != null && index < notifications.length) {
      final notification = notifications[index];

      // Toggle notification read status
      final updatedNotifications =
          List<NotificationItemModel>.from(notifications);
      updatedNotifications[index] = notification.copyWith(
        isRead: !(notification.isRead ?? false),
        iconPath: !(notification.isRead ?? false)
            ? ImageConstant.imgButtonsBlueGray300
            : ImageConstant.imgButton,
      );

      state = state.copyWith(
        notificationsModel: state.notificationsModel?.copyWith(
          notificationsList: updatedNotifications,
        ),
      );

      // Handle navigation or action based on notification type
      // For friend requests, navigate to friends management
    }
  }
}
