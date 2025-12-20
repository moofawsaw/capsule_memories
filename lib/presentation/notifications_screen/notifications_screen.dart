import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_notification_item.dart';
import 'notifier/notifications_notifier.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
    _loadNotifications();
  }

  @override
  void dispose() {
    _notificationService.unsubscribeFromNotifications();
    super.dispose();
  }

  Future<void> _setupRealtimeSubscription() async {
    try {
      await _notificationService.subscribeToNotifications(
        onNewNotification: (notification) {
          // Reload notifications when new one arrives
          _loadNotifications();

          // Show in-app notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(notification['message'] ?? 'New notification'),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () {
                    _handleNotificationTap(notification);
                  },
                ),
              ),
            );
          }
        },
      );
    } catch (error) {
      debugPrint('Failed to setup notification subscription: $error');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifier = ref.read(notificationsNotifier.notifier);
      final notifications = await _notificationService.getNotifications();
      notifier.setNotifications(notifications);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $error')),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await _loadNotifications();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as read: $error')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $error')),
        );
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'] as Map<String, dynamic>?;

    if (!notification['is_read']) {
      _markAsRead(notification['id']);
    }

    switch (type) {
      case 'memory_invite':
        if (data != null && data['memory_id'] != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.appTimelineSealed,
            arguments: {'memoryId': data['memory_id']},
          );
        }
        break;
      case 'friend_request':
        Navigator.pushNamed(context, AppRoutes.appFriends);
        break;
      case 'new_story':
        if (data != null && data['memory_id'] != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.appBsStories,
            arguments: {'memoryId': data['memory_id']},
          );
        }
        break;
      case 'followed':
        if (data != null && data['follower_id'] != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.appProfileTwo,
            arguments: {'userId': data['follower_id']},
          );
        }
        break;
      case 'memory_expiring':
      case 'memory_sealed':
        if (data != null && data['memory_id'] != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.appTimelineSealed,
            arguments: {'memoryId': data['memory_id']},
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.maxFinite,
        child: Column(children: [
          SizedBox(height: 26.h),
          Expanded(
              child: Container(
                  margin: EdgeInsets.fromLTRB(8.h, 0, 8.h, 62.h),
                  child: Column(spacing: 32.h, children: [
                    _buildNotificationsHeader(context),
                    _buildNotificationsList()
                  ]))),
        ]));
  }

  /// Section Widget
  Widget _buildNotificationsHeader(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(notificationsNotifier);
      final notifications = state.notificationsModel?.notifications ?? [];

      // Check if there are any unread notifications to determine button text
      final hasUnread = notifications
          .any((notification) => !(notification['is_read'] ?? false));
      final buttonText = hasUnread ? 'mark as read' : 'mark as unread';

      return Container(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        CustomImageView(
            imagePath: ImageConstant.imgIconDeepPurpleA10032x32,
            height: 26.h,
            width: 26.h),
        SizedBox(width: 6.h),
        Text('Notifications',
            style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans),
        Spacer(),
        GestureDetector(
            onTap: () => _onMarkAsReadTap(),
            child: Container(
                margin: EdgeInsets.only(top: 4.h),
                child: Text(buttonText,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50)))),
      ]));
    });
  }

  /// Section Widget
  Widget _buildNotificationsList() {
    final state = ref.watch(notificationsNotifier);
    final notifications = state.notificationsModel?.notifications ?? [];

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64.h, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 16.h, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => Divider(height: 1, thickness: 1),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return CustomNotificationItem(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
          );
        },
      ),
    );
  }

  /// Handles icon button tap in app bar
  void _onIconButtonTap() {
    // Handle add/plus button tap
  }

  /// Navigates to profile screen
  void _onProfileTap() {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  /// Handles mark as read/unread toggle functionality
  void _onMarkAsReadTap() {
    ref.read(notificationsNotifier.notifier).toggleMarkAllNotifications();
  }

  /// Handles notification card tap to mark as read
  void _onNotificationTap(int index) {
    ref.read(notificationsNotifier.notifier).handleNotificationTap(index);
  }

  /// Handles notification icon tap
  void _onNotificationIconTap(int index) {
    ref.read(notificationsNotifier.notifier).handleNotificationTap(index);
  }
}