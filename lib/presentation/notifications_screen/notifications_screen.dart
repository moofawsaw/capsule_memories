import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_notification_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeSubscription();
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _notificationService.unsubscribeFromNotifications();
    super.dispose();
  }

  Future<void> _setupRealtimeSubscription() async {
    try {
      _notificationService.subscribeToNotifications(
        onNewNotification: (notification) {
          _loadNotifications();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(notification['message'] ?? 'New notification'),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'View',
                  onPressed: () => _handleNotificationTap(notification),
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
      debugPrint('❌ Error loading notifications: $error');
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

  Future<void> _toggleReadState(
      String notificationId, bool currentReadState) async {
    try {
      await _notificationService.toggleReadState(
          notificationId, currentReadState);
      await _loadNotifications();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to toggle notification state: $error')),
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

  Future<void> _deleteNotification(String notificationId) async {
    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Delete Notification?',
      message: 'Are you sure you want to delete this notification?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      try {
        // Add delete notification logic here
        await _loadNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification deleted')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete notification: $error')),
          );
        }
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Delete All Notifications?',
      message:
          'Are you sure you want to delete all notifications? This action cannot be undone.',
      confirmText: 'Delete All',
      cancelText: 'Cancel',
      icon: Icons.delete_sweep_outlined,
    );

    if (confirmed == true) {
      try {
        // Add delete all notifications logic here
        await _loadNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications deleted')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete notifications: $error')),
          );
        }
      }
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    debugPrint('🔔 Notification tapped - Type: ${notification['type']}');

    final notificationId = notification['id'] as String?;
    final type = notification['type'] as String?;
    final data = notification['data'] as Map<String, dynamic>?;
    final isRead = notification['is_read'] as bool? ?? false;

    // Mark as read if unread
    if (!isRead && notificationId != null) {
      _markAsRead(notificationId);
    }

    // Navigate based on type
    if (type == null) {
      debugPrint('⚠️ Notification type is null');
      return;
    }

    switch (type) {
      case 'memory_invite':
        final memoryId = data?['memory_id'];
        if (memoryId != null) {
          debugPrint('🔔 Navigating to memory: $memoryId');
          Navigator.pushNamed(
            context,
            AppRoutes.appTimelineSealed,
            arguments: {'memoryId': memoryId},
          );
        } else {
          debugPrint('⚠️ Missing memory_id');
        }
        break;

      case 'friend_request':
        debugPrint('🔔 Navigating to friends screen');
        Navigator.pushNamed(context, AppRoutes.appFriends);
        break;

      case 'new_story':
        final memoryId = data?['memory_id'];
        if (memoryId != null) {
          debugPrint('🔔 Navigating to story: $memoryId');
          Navigator.pushNamed(
            context,
            AppRoutes.appBsStories,
            arguments: {'memoryId': memoryId},
          );
        } else {
          debugPrint('⚠️ Missing memory_id');
        }
        break;

      case 'followed':
        final followerId = data?['follower_id'];
        if (followerId != null) {
          debugPrint('🔔 Navigating to profile: $followerId');
          Navigator.pushNamed(
            context,
            AppRoutes.appProfileUser,
            arguments: {'userId': followerId},
          );
        } else {
          debugPrint('⚠️ Missing follower_id');
        }
        break;

      case 'memory_expiring':
      case 'memory_sealed':
        final memoryId = data?['memory_id'];
        if (memoryId != null) {
          debugPrint('🔔 Navigating to sealed memory: $memoryId');
          Navigator.pushNamed(
            context,
            AppRoutes.appTimelineSealed,
            arguments: {'memoryId': memoryId},
          );
        } else {
          debugPrint('⚠️ Missing memory_id');
        }
        break;

      default:
        debugPrint('⚠️ Unknown notification type: $type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: Column(
        children: [
          SizedBox(height: 26.h),
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(8.h, 0, 8.h, 62.h),
              child: Column(
                spacing: 32.h,
                children: [
                  _buildNotificationsHeader(context),
                  Expanded(child: _buildNotificationsList())
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(notificationsNotifier);
        final notifications = state.notificationsModel?.notifications ?? [];
        final hasUnread =
            notifications.any((n) => !(n['is_read'] as bool? ?? false));
        final buttonText = hasUnread ? 'mark all read' : 'mark all unread';

        return Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgIconDeepPurpleA10032x32,
                height: 26.h,
                width: 26.h,
              ),
              SizedBox(width: 6.h),
              Text(
                'Notifications',
                style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans,
              ),
              Spacer(),
              GestureDetector(
                onTap: _onMarkAllTap,
                child: Container(
                  margin: EdgeInsets.only(top: 4.h),
                  padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
                  child: Text(
                    buttonText,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getNotificationIconPath(String type) {
    switch (type) {
      case 'memory_invite':
      case 'new_story':
      case 'memory_expiring':
      case 'memory_sealed':
        return ImageConstant.imgIconDeepPurpleA10032x32;
      case 'friend_request':
      case 'followed':
        return ImageConstant.imgIcon5;
      default:
        return ImageConstant.imgIconDeepPurpleA10032x32;
    }
  }

  Color? _getNotificationBackgroundColor(bool isRead) {
    return isRead
        ? Colors.transparent
        : appTheme.deep_purple_A100.withAlpha(20);
  }

  Color _getNotificationTextColor(bool isRead) {
    return isRead ? appTheme.blue_gray_300 : appTheme.gray_50;
  }

  Color _getNotificationDescriptionColor(bool isRead) {
    return isRead
        ? appTheme.blue_gray_300.withAlpha(179)
        : appTheme.blue_gray_300;
  }

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
              style: TextStyle(fontSize: 16.fSize, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 2.h),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final isRead = notification['is_read'] as bool? ?? false;
          final notificationId = notification['id'] as String;

          return Dismissible(
            key: Key(notificationId),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              // Show delete confirmation
              return await CustomConfirmationDialog.show(
                context: context,
                title: 'Delete Notification?',
                message: 'Are you sure you want to delete this notification?',
                confirmText: 'Delete',
                cancelText: 'Cancel',
                icon: Icons.delete_outline,
              );
            },
            onDismissed: (direction) async {
              // Delete notification from database
              try {
                await _notificationService.deleteNotification(notificationId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification deleted'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }

                // Reload notifications to update UI
                await _loadNotifications();
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete notification: $error'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20.w),
              decoration: BoxDecoration(
                color: appTheme.red_500,
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: appTheme.white_A700,
                    size: 28.h,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: appTheme.white_A700,
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            child: CustomNotificationCard(
              iconPath: _getNotificationIconPath(
                  notification['type'] as String? ?? ''),
              title: notification['title'] as String? ?? 'Notification',
              description: notification['message'] as String? ?? '',
              isRead: isRead,
              backgroundColor: _getNotificationBackgroundColor(isRead),
              titleColor: _getNotificationTextColor(isRead),
              descriptionColor: _getNotificationDescriptionColor(isRead),
              onTap: () {
                debugPrint('🎯 Card tapped at index $index');
                _handleNotificationTap(notification);
              },
              onToggleRead: () {
                debugPrint(
                    '🔄 Toggle read state for notification $notificationId');
                _toggleReadState(notificationId, isRead);
              },
            ),
          );
        },
      ),
    );
  }

  void _onMarkAllTap() {
    final notifications =
        ref.read(notificationsNotifier).notificationsModel?.notifications ?? [];
    final hasUnread =
        notifications.any((n) => !(n['is_read'] as bool? ?? false));

    if (hasUnread) {
      _markAllAsRead();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications already read')),
        );
      }
    }
  }
}
