import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/custom_memory_invite_notification_card.dart';
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

  // Stack to maintain deleted notifications (most recent at end)
  final List<Map<String, dynamic>> _deletedNotificationsStack = [];

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
          // CRITICAL FIX: Reload notifications list silently without showing snackbar
          // This prevents duplicate notifications when user restores deleted notifications
          _loadNotifications();

          // ONLY show snackbar for truly new notifications (not restored ones)
          // Check if this notification was just created (within last 2 seconds)
          final createdAt = notification['created_at'] as String?;
          if (createdAt != null) {
            final notificationTime = DateTime.parse(createdAt);
            final timeDifference = DateTime.now().difference(notificationTime);

            // Only show snackbar if notification is brand new (created within last 2 seconds)
            if (timeDifference.inSeconds <= 2 && mounted) {
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

    // Friend-related notifications → navigate to /friends
    if (type == 'friend_request' || type == 'friend_accepted') {
      debugPrint('🔔 Navigating to friends screen');
      Navigator.pushNamed(context, AppRoutes.appFriends);
      return;
    }

    // Memory-related notifications → navigate to /timeline with memory ID
    if (type == 'memory_invite' ||
        type == 'memory_expiring' ||
        type == 'memory_sealed' ||
        type == 'memory_update' ||
        type.startsWith('memory_')) {
      final memoryId = data?['memory_id'];
      if (memoryId != null) {
        debugPrint('🔔 Navigating to memory timeline: $memoryId');
        // CRITICAL FIX: Use 'id' key instead of 'memoryId' to match MemoryNavArgs.fromMap expectation
        Navigator.pushNamed(
          context,
          AppRoutes.appTimelineSealed,
          arguments: {'id': memoryId}, // Changed from 'memoryId' to 'id'
        );
      } else {
        debugPrint('⚠️ Missing memory_id for memory notification');
      }
      return;
    }

    // Story-related notifications → navigate to specific story
    if (type == 'new_story' ||
        type == 'story_mention' ||
        type == 'story_reaction' ||
        type.startsWith('story_')) {
      final memoryId = data?['memory_id'];
      final storyId = data?['story_id'];

      if (memoryId != null) {
        debugPrint(
            '🔔 Navigating to story view: memory=$memoryId, story=$storyId');
        Navigator.pushNamed(
          context,
          AppRoutes.appBsStories,
          arguments: {
            'memoryId': memoryId,
            if (storyId != null) 'storyId': storyId,
          },
        );
      } else {
        debugPrint('⚠️ Missing memory_id for story notification');
      }
      return;
    }

    // Follower/following notifications
    if (type == 'followed' || type == 'new_follower') {
      final followerId = data?['follower_id'] ?? data?['user_id'];
      if (followerId != null) {
        debugPrint('🔔 Navigating to user profile: $followerId');
        Navigator.pushNamed(
          context,
          AppRoutes.appProfileUser,
          arguments: {'userId': followerId},
        );
      } else {
        debugPrint('⚠️ Missing follower_id for follow notification');
      }
      return;
    }

    // Default case for unknown notification types
    debugPrint('⚠️ Unknown notification type: $type - no navigation handler');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: Column(
        children: [
          SizedBox(height: 24.h),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.h),
              child: Column(
                children: [
                  _buildNotificationsHeader(context),
                  SizedBox(height: 16.h),
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
          final notificationType = notification['type'] as String? ?? '';

          // ============================================
          // SPECIAL HANDLING FOR MEMORY INVITE NOTIFICATIONS
          // ============================================
          if (notificationType == 'memory_invite') {
            return Dismissible(
              key: Key(notificationId),
              direction: DismissDirection.endToStart, // Only allow delete swipe for invites
              confirmDismiss: (direction) async => true,
              onDismissed: (direction) async {
                // Store notification data in stack (most recent at end)
                final deletedNotification = Map<String, dynamic>.from(notification);
                _deletedNotificationsStack.add(deletedNotification);

                // Delete notification from database
                try {
                  await _notificationService.deleteNotification(notificationId);
                  await _loadNotifications();

                  if (mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Notification deleted'),
                        duration: const Duration(seconds: 5),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(bottom: 80.h, left: 16.w, right: 16.w),
                        action: SnackBarAction(
                          label: 'UNDO',
                          textColor: appTheme.deep_purple_A100,
                          onPressed: () async {
                            if (_deletedNotificationsStack.isNotEmpty) {
                              final notificationToRestore = _deletedNotificationsStack.removeLast();
                              try {
                                await _notificationService.restoreNotification(notificationToRestore);
                                await _loadNotifications();
                              } catch (error) {
                                _deletedNotificationsStack.add(notificationToRestore);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to restore: $error')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }
                } catch (error) {
                  _deletedNotificationsStack.removeLast();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $error')),
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
                    Icon(Icons.delete_outline, color: appTheme.white_A700, size: 28.h),
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
              child: MemoryInviteNotificationCard(
                notification: notification,
                onActionCompleted: _loadNotifications,
                onNavigateToMemory: (memoryId) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.appTimelineSealed,
                    arguments: {'id': memoryId},
                  );
                },
              ),
            );
          }

          // ============================================
          // DEFAULT HANDLING FOR ALL OTHER NOTIFICATIONS
          // ============================================
          return Dismissible(
            key: Key(notificationId),
            direction: DismissDirection.horizontal,
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                // Swiped left - delete action
                return true;
              } else if (direction == DismissDirection.startToEnd) {
                // Swiped right - toggle read/unread action
                await _toggleReadState(notificationId, isRead);
                return false; // Don't dismiss, just toggle state
              }
              return false;
            },
            onDismissed: (direction) async {
              if (direction == DismissDirection.endToStart) {
                // Store notification data in stack (most recent at end)
                final deletedNotification =
                Map<String, dynamic>.from(notification);
                _deletedNotificationsStack.add(deletedNotification);

                // Delete notification from database
                try {
                  await _notificationService.deleteNotification(notificationId);

                  // Reload notifications to update UI
                  await _loadNotifications();

                  if (mounted) {
                    // Dismiss any existing snackbar to show new one
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    // Show undo toast with countdown timer at bottom
                    int remainingSeconds = 5;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: StatefulBuilder(
                          builder: (context, setState) {
                            // Start countdown timer
                            Future.delayed(Duration.zero, () async {
                              for (int i = remainingSeconds; i > 0; i--) {
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                if (context.mounted) {
                                  setState(() {
                                    remainingSeconds = i - 1;
                                  });
                                }
                              }
                            });

                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Notification deleted (${_deletedNotificationsStack.length} in stack)',
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    appTheme.deep_purple_A100.withAlpha(77),
                                    borderRadius: BorderRadius.circular(4.h),
                                  ),
                                  child: Text(
                                    '${remainingSeconds}s',
                                    style: TextStyle(
                                      color: appTheme.white_A700,
                                      fontSize: 12.fSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        duration: const Duration(seconds: 5),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: 80.h,
                          left: 16.w,
                          right: 16.w,
                        ),
                        action: SnackBarAction(
                          label: 'UNDO',
                          textColor: appTheme.deep_purple_A100,
                          onPressed: () async {
                            // Restore the most recently deleted notification (LIFO)
                            if (_deletedNotificationsStack.isNotEmpty) {
                              final notificationToRestore =
                              _deletedNotificationsStack.removeLast();

                              try {
                                await _notificationService
                                    .restoreNotification(notificationToRestore);
                                await _loadNotifications();

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Notification restored (${_deletedNotificationsStack.length} remaining in stack)',
                                      ),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        bottom: 80.h,
                                        left: 16.w,
                                        right: 16.w,
                                      ),
                                    ),
                                  );
                                }
                              } catch (error) {
                                // If restore fails, add it back to stack
                                _deletedNotificationsStack
                                    .add(notificationToRestore);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                      Text('Failed to restore: $error'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        bottom: 80.h,
                                        left: 16.w,
                                        right: 16.w,
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }
                } catch (error) {
                  // If delete fails, remove from stack
                  _deletedNotificationsStack.removeLast();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete notification: $error'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: 80.h,
                          left: 16.w,
                          right: 16.w,
                        ),
                      ),
                    );
                  }
                }
              }
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 20.w),
              decoration: BoxDecoration(
                color: isRead ? appTheme.deep_purple_A100 : appTheme.green_500,
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRead
                        ? Icons.mark_email_unread_outlined
                        : Icons.mark_email_read_outlined,
                    color: appTheme.white_A700,
                    size: 28.h,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isRead ? 'Mark\nUnread' : 'Mark\nRead',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: appTheme.white_A700,
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            secondaryBackground: Container(
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
              timestamp: notification['created_at'] != null
                  ? DateTime.parse(notification['created_at'] as String)
                  : null,
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
