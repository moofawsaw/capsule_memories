import 'dart:async';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/custom_memory_invite_notification_card.dart';
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

  // Stack to maintain deleted notifications for undo (most recent at end)
  final List<Map<String, dynamic>> _deletedNotificationsStack = [];

  // Suppress "new notification" snackbar for notifications restored via UNDO
  final Set<String> _suppressNewSnackbarsForNotificationIds = {};

  // Undo snackbar countdown plumbing
  ValueNotifier<int>? _undoCountdown;
  Timer? _undoCountdownTimer;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
      _undoSnackBarController;

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
    _cancelUndoCountdown(closeSnackBar: false);
    _notificationService.unsubscribeFromNotifications();
    super.dispose();
  }

  void _cancelUndoCountdown({required bool closeSnackBar}) {
    _undoCountdownTimer?.cancel();
    _undoCountdownTimer = null;

    _undoCountdown?.dispose();
    _undoCountdown = null;

    if (closeSnackBar) {
      _undoSnackBarController?.close();
    }
    _undoSnackBarController = null;
  }

  Future<void> _setupRealtimeSubscription() async {
    try {
      _notificationService.subscribeToNotifications(
        onNewNotification: (notification) {
          // Always refresh list silently to reflect latest DB state
          _loadNotifications();

          // If this notification was restored via UNDO, don't show snackbar
          final id = notification['id'] as String?;
          if (id != null &&
              _suppressNewSnackbarsForNotificationIds.remove(id)) {
            return;
          }

          // Only show snackbar for truly new notifications
          final createdAt = notification['created_at'] as String?;
          if (createdAt != null) {
            final notificationTime = DateTime.parse(createdAt);
            final timeDifference = DateTime.now().difference(notificationTime);

            // Only show snackbar if notification is brand new (within last 2 seconds)
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

  // ignore: unused_element
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
        await _notificationService.deleteNotification(notificationId);
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

  // ignore: unused_element
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
        // TODO: Implement bulk soft delete
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
        Navigator.pushNamed(
          context,
          AppRoutes.appTimeline,
          arguments: {'id': memoryId},
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

  /// Handle swipe-to-delete with optimistic UI update
  void _handleSwipeDelete(Map<String, dynamic> notification, String notificationId) {
    // 1. Save notification for potential undo
    final deletedNotification = Map<String, dynamic>.from(notification);
    _deletedNotificationsStack.add(deletedNotification);

    // 2. IMMEDIATE: Remove from local state (fixes Dismissible error)
    final notifier = ref.read(notificationsNotifier.notifier);
    notifier.removeNotification(notificationId);

    // 3. Call API async (soft delete)
    _notificationService.deleteNotification(notificationId).catchError((error) {
      // On error, restore to local state
      _deletedNotificationsStack.removeLast();
      notifier.addNotification(deletedNotification);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $error')),
        );
      }
    });

    // 4. Show undo snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showUndoSnackbar(deletedNotification, notificationId);
    }
  }

  /// Show undo snackbar with countdown
  void _showUndoSnackbar(
      Map<String, dynamic> deletedNotification, String notificationId) {
    // Ensure we only ever have ONE countdown + ONE snackbar active.
    _cancelUndoCountdown(closeSnackBar: true);

    _undoCountdown = ValueNotifier<int>(5);

    final snackBar = SnackBar(
      backgroundColor: appTheme.gray_900_01,
      content: ValueListenableBuilder<int>(
        valueListenable: _undoCountdown!,
        builder: (context, remainingSeconds, _) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  'Notification deleted${_deletedNotificationsStack.length > 1 ? ' (${_deletedNotificationsStack.length} in stack)' : ''}',
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: appTheme.deep_purple_A100.withAlpha(77),
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
      margin: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: appTheme.deep_purple_A100,
        onPressed: () {
          if (!mounted) return;
          _cancelUndoCountdown(closeSnackBar: true);
          _handleUndo();
        },
      ),
    );

    final controller = ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _undoSnackBarController = controller;
    controller.closed.then((_) {
      if (!mounted) return;
      _cancelUndoCountdown(closeSnackBar: false);
    });

    // Drive countdown + make sure snackbar is dismissed exactly at 0.
    _undoCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _undoCountdown == null) {
        t.cancel();
        return;
      }

      final next = _undoCountdown!.value - 1;
      _undoCountdown!.value = next;

      if (next <= 0) {
        t.cancel();
        _undoCountdownTimer = null;

        // Requirement: dismiss when countdown reaches 0 (not just via duration).
        _undoSnackBarController?.close();
        _cancelUndoCountdown(closeSnackBar: false);
      }
    });
  }

  /// Handle undo action - restore the last deleted notification
  void _handleUndo() {
    if (_deletedNotificationsStack.isEmpty) return;

    final notificationToRestore = _deletedNotificationsStack.removeLast();
    final restoreId = notificationToRestore['id'] as String;

    // Suppress snackbar for this restored notification
    _suppressNewSnackbarsForNotificationIds.add(restoreId);

    // IMMEDIATE: Add back to local state
    final notifier = ref.read(notificationsNotifier.notifier);
    notifier.addNotification(notificationToRestore);

    // Call restore API (UPDATE, not INSERT - no push triggered!)
    _notificationService.restoreNotification(restoreId).then((_) {
      debugPrint('✅ Notification restored in DB');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification restored${_deletedNotificationsStack.isNotEmpty ? ' (${_deletedNotificationsStack.length} remaining)' : ''}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
          ),
        );
      }
    }).catchError((error) {
      // On error, remove from local state again
      _suppressNewSnackbarsForNotificationIds.remove(restoreId);
      notifier.removeNotification(restoreId);
      _deletedNotificationsStack.add(notificationToRestore);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore: $error')),
        );
      }
    });
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
              Icon(
                Icons.notifications_outlined,
                size: 26.h,
                color: appTheme.deep_purple_A100,
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

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'memory_invite':
      case 'new_story':
      case 'memory_expiring':
      case 'memory_sealed':
        return Icons.photo_library_outlined;
      case 'public_story_nearby':
        return Icons.photo_library_outlined;
      case 'friend_new_story':
        return Icons.person_pin_outlined;
      case 'friend_request':
      case 'followed':
        return Icons.person_add_alt_1_outlined;
      default:
        return Icons.notifications_outlined;
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
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none, size: 64.h, color: Colors.grey),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.h),
                child: Text(
                  'No notifications yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.fSize, color: Colors.grey),
                ),
              ),
            ],
          ),
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
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async => true,
              onDismissed: (direction) {
                // Use centralized delete handler with optimistic UI
                _handleSwipeDelete(notification, notificationId);
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
                    Icon(Icons.delete_outline,
                        color: appTheme.white_A700, size: 28.h),
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
              child: SizedBox(
                width: double.infinity,
                child: MemoryInviteNotificationCard(
                  notification: notification,
                  onActionCompleted: _loadNotifications,
                  onNavigateToMemory: (memoryId) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.appTimeline,
                      arguments: {'id': memoryId},
                    );
                  },
                ),
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
                // Delete - allow dismissal
                return true;
              } else if (direction == DismissDirection.startToEnd) {
                // Toggle read state - don't dismiss, just toggle
                await _toggleReadState(notificationId, isRead);
                return false;
              }
              return false;
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                // Use centralized delete handler with optimistic UI
                _handleSwipeDelete(notification, notificationId);
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
              leadingIcon: _getNotificationIcon(
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