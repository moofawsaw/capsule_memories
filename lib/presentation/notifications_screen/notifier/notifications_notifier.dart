import '../../../core/app_export.dart';
import '../models/notifications_model.dart';

part 'notifications_state.dart';

// NOTE: This provider is used by the global header (AppBar) for unread count,
// so it must NOT autoDispose; otherwise startup updates can be lost before the
// header starts watching it.
final notificationsNotifier = StateNotifierProvider<
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
  /// Remove a notification from local state by ID
  void removeNotification(String notificationId) {
    final currentNotifications = state.notificationsModel?.notifications ?? [];
    final updatedNotifications = currentNotifications
        .where((n) => n['id'] != notificationId)
        .toList();

    state = state.copyWith(
      notificationsModel: NotificationsModel(notifications: updatedNotifications),
    );
  }

  /// Add a notification back to local state (maintains sort order)
  void addNotification(Map<String, dynamic> notification) {
    final currentNotifications = state.notificationsModel?.notifications ?? [];

    // Insert and re-sort by created_at descending
    final updatedNotifications = [...currentNotifications, notification];
    updatedNotifications.sort((a, b) {
      final aTime = DateTime.parse(a['created_at'] as String);
      final bTime = DateTime.parse(b['created_at'] as String);
      return bTime.compareTo(aTime); // Descending order (newest first)
    });

    state = state.copyWith(
      notificationsModel: NotificationsModel(notifications: updatedNotifications),
    );
  }

  void toggleMarkAllNotifications() {
    final notificationsData = state.notificationsModel?.notifications;
    if (notificationsData == null || notificationsData.isEmpty) return;

    // Check if there are any unread notifications
    final hasUnread = notificationsData
        .any((notification) => !(notification['is_read'] as bool? ?? false));

    // If there are unread notifications, mark all as read
    // Otherwise, mark all as unread
    final updatedNotifications = notificationsData.map((notification) {
      return {
        ...notification,
        'is_read': hasUnread ? true : false,
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
      };

      state = state.copyWith(
        notificationsModel: state.notificationsModel?.copyWith(
          notifications: updatedNotifications,
        ),
      );
    }
  }
}
