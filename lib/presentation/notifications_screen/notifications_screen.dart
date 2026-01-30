import 'dart:async';

import '../../core/app_export.dart';
import '../../core/services/deep_link_service.dart';
import '../../core/utils/memory_nav_args.dart';
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
  final Set<String> _pendingDeleteIds = {};
  final Set<String> _undoRequestedIds = {};

  // Suppress "new notification" snackbar for notifications restored via UNDO
  final Set<String> _suppressNewSnackbarsForNotificationIds = {};

  // Some notifications are inserted first, then enriched moments later (title/message/data).
  // When we receive an "empty" realtime insert, do a short follow-up refresh.
  Timer? _notificationEnrichmentRefreshTimer;

  Future<Map<String, dynamic>?> _fetchNotificationWithRetry(
    String notificationId, {
    int attempts = 4,
    Duration initialDelay = const Duration(milliseconds: 250),
  }) async {
    Duration delay = initialDelay;
    for (int i = 0; i < attempts; i++) {
      final n = await _notificationService.getNotificationById(notificationId);
      if (n != null) {
        final title = (n['title'] ?? '').toString().trim();
        final msg = (n['message'] ?? '').toString().trim();
        final data = n['data'];
        final hasData = data is Map && data.isNotEmpty;
        if (title.isNotEmpty || msg.isNotEmpty || hasData) {
          return n;
        }
      }
      await Future.delayed(delay);
      delay += const Duration(milliseconds: 250);
    }
    return await _notificationService.getNotificationById(notificationId);
  }

  String? _deepLinkFromNotificationRow(Map<String, dynamic> notification) {
    final raw = notification['data'];
    final Map<String, dynamic>? data =
        raw is Map ? Map<String, dynamic>.from(raw) : null;

    final direct = (data?['deep_link'] ?? data?['deepLink'])?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final memoryId = (data?['memory_id'] ?? '').toString().trim();
    final storyId = (data?['story_id'] ?? '').toString().trim();
    if (memoryId.isNotEmpty && storyId.isNotEmpty) {
      return 'https://capapp.co/memory/$memoryId/story/$storyId';
    }
    return null;
  }

  Future<void> _showForegroundSnackbarForNotificationId(
    String notificationId,
  ) async {
    final row = await _fetchNotificationWithRetry(notificationId);
    if (!mounted) return;

    final title = (row?['title'] ?? '').toString().trim();
    final message = (row?['message'] ?? '').toString().trim();
    final text = message.isNotEmpty
        ? message
        : (title.isNotEmpty ? title : 'New notification');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // IMPORTANT:
            // Foreground "View" must navigate exactly like tapping the in-app notification row.
            // Reuse the same handler to ensure parity across all notification types.
            if (!mounted) return;
            if (row is Map<String, dynamic>) {
              _handleNotificationTap(row);
              return;
            }
          },
        ),
      ),
    );
  }

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
    // IMPORTANT: close the snackbar first, and dispose the notifier only
    // after the snackbar is fully closed. Disposing early can crash because
    // SnackBar's ValueListenableBuilder may still read the notifier.
    _cancelUndoCountdown(closeSnackBar: true);
    _notificationEnrichmentRefreshTimer?.cancel();
    _notificationEnrichmentRefreshTimer = null;
    _notificationService.unsubscribeFromNotifications();
    super.dispose();
  }

  void _cancelUndoCountdown({required bool closeSnackBar}) {
    _undoCountdownTimer?.cancel();
    _undoCountdownTimer = null;

    if (closeSnackBar) {
      // If a snackbar is showing, close it and let its `closed` callback
      // dispose the notifier safely.
      if (_undoSnackBarController != null) {
        _undoSnackBarController?.close();
        return;
      }
    }

    // Safe to dispose now (no snackbar is showing).
    _undoCountdown?.dispose();
    _undoCountdown = null;
    _undoSnackBarController = null;
  }

  Future<void> _setupRealtimeSubscription() async {
    try {
      _notificationService.subscribeToNotifications(
        onNewNotification: (notification) {
          if (!mounted) return;

          // Always refresh list silently to reflect latest DB state
          _loadNotifications();

          // If this was inserted without payload fields (common when a follow-up update enriches it),
          // schedule a second refresh shortly after.
          final title = (notification['title'] ?? '').toString().trim();
          final message = (notification['message'] ?? '').toString().trim();
          final data = notification['data'];
          final hasData = data is Map && data.isNotEmpty;
          final isBlank = title.isEmpty && message.isEmpty && !hasData;
          if (isBlank) {
            _notificationEnrichmentRefreshTimer?.cancel();
            _notificationEnrichmentRefreshTimer = Timer(
              const Duration(milliseconds: 900),
              () {
                if (!mounted) return;
                _loadNotifications();
              },
            );
          }

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
              // Avoid showing a blank snackbar (common when row is enriched right after insert).
              // Also ensure View action doesn't depend on this widget still being alive.
              if (isBlank && id != null) {
                unawaited(_showForegroundSnackbarForNotificationId(id));
              } else {
                final text = message.isNotEmpty
                    ? message
                    : (title.isNotEmpty ? title : 'New notification');
                final link = _deepLinkFromNotificationRow(notification);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(text),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'View',
                      onPressed: () {
                        final deepLink = (link ?? '').trim();
                        if (deepLink.isNotEmpty) {
                          DeepLinkService().handleExternalDeepLink(deepLink);
                        }
                      },
                    ),
                  ),
                );
              }
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
      if (!mounted) return;
      final notifier = ref.read(notificationsNotifier.notifier);
      final notifications = await _notificationService.getNotifications();
      if (!mounted) return;
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
      if (!mounted) return;
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
      if (!mounted) return;
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
      if (!mounted) return;
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
    final rawData = notification['data'];
    final Map<String, dynamic>? data =
        rawData is Map ? Map<String, dynamic>.from(rawData) : null;
    final isRead = notification['is_read'] as bool? ?? false;

    // Mark as read if unread
    if (!isRead && notificationId != null) {
      _markAsRead(notificationId);
    }

    // ------------------------------------------------------------------
    // STORY-IN-MEMORY NAV (preferred):
    // These notifications ("A new story was added to {memory}") should open
    // inside the memory timeline context (playlist), same as push deep links.
    // This avoids opening EventStoriesViewScreen with a raw Map args.
    // ------------------------------------------------------------------
    final String memoryIdFromData =
        (data?['memory_id'] ?? data?['memoryId'] ?? data?['memoryID'] ?? '')
            .toString()
            .trim();
    final String storyIdFromData =
        (data?['story_id'] ?? data?['storyId'] ?? data?['storyID'] ?? '')
            .toString()
            .trim();

    if (memoryIdFromData.isNotEmpty && storyIdFromData.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.appTimeline,
        arguments: MemoryNavArgs(
          memoryId: memoryIdFromData,
          initialStoryId: storyIdFromData,
        ).toMap(),
      );
      return;
    }

    // ------------------------------------------------------------------
    // IMPORTANT: Prefer deep-link navigation when available.
    // Push notifications navigate via DeepLinkService; in-app taps should
    // behave identically to avoid “opens wrong screen / doesn’t open story”.
    // ------------------------------------------------------------------
    final String? deepLink = (data?['deep_link'] ?? data?['deepLink'])?.toString();
    final String deepLinkTrim = (deepLink ?? '').trim();
    if (deepLinkTrim.isNotEmpty) {
      DeepLinkService().handleExternalDeepLink(deepLinkTrim);
      return;
    }

    // Navigate based on type
    if (type == null) {
      debugPrint('⚠️ Notification type is null');
      return;
    }

    // Daily Capsule notifications → navigate to Daily Capsule screen
    if (type == 'daily_capsule_reminder' ||
        type == 'friend_daily_capsule_completed') {
      debugPrint('🔔 Navigating to Daily Capsule');
      Navigator.pushNamed(context, AppRoutes.appDailyCapsule);
      return;
    }

    // Friend-related notifications → navigate to /friends
    if (type == 'friend_request' || type == 'friend_accepted') {
      debugPrint('🔔 Navigating to friends screen');
      Navigator.pushNamed(context, AppRoutes.appFriends);
      return;
    }

    // Memory-related notifications → navigate to /timeline with memory ID
    // Only handle the memory notification types we still support.
    if (type == 'memory_invite' ||
        type == 'memory_expiring' ||
        type == 'memory_sealed') {
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

    // Story-related notifications → navigate to story inside memory (timeline->viewer)
    // NOTE: Most story notifications now include deep_link and are handled above.
    if (type.contains('story') || type.startsWith('story_')) {
      final memoryId = (data?['memory_id'] ?? '').toString().trim();
      final storyId = (data?['story_id'] ?? '').toString().trim();
      if (memoryId.isNotEmpty && storyId.isNotEmpty) {
        DeepLinkService().handleExternalDeepLink(
          'https://capapp.co/memory/$memoryId/story/$storyId',
        );
      } else if (memoryId.isNotEmpty) {
        Navigator.pushNamed(
          context,
          AppRoutes.appTimeline,
          arguments: {'id': memoryId},
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

    // Group-related notifications → navigate to /groups with group ID
    // Only handle group invites (we no longer generate group_join/group_added notifications).
    if (type == 'group_invite') {
      final groupId = data?['group_id'];
      if (groupId != null) {
        debugPrint('🔔 Navigating to group: $groupId');
        Navigator.pushNamed(
          context,
          AppRoutes.appGroups,
          arguments: {'groupId': groupId},
        );
      } else {
        debugPrint('⚠️ Missing group_id for group notification');
      }
      return;
    }


    // Default case for unknown notification types
    debugPrint('⚠️ Unknown notification type: $type - no navigation handler');
  }

  /// Handle swipe-to-delete with optimistic UI update
  void _handleSwipeDelete(Map<String, dynamic> notification, String notificationId) {
    if (_pendingDeleteIds.contains(notificationId)) return;
    _pendingDeleteIds.add(notificationId);

    // 1. Save notification for potential undo
    final deletedNotification = Map<String, dynamic>.from(notification);
    // Ensure stack only has one instance of this id
    _deletedNotificationsStack.removeWhere((n) => n['id'] == notificationId);
    _deletedNotificationsStack.add(deletedNotification);

    // 2. IMMEDIATE: Remove from local state (fixes Dismissible error)
    final notifier = ref.read(notificationsNotifier.notifier);
    notifier.removeNotification(notificationId);

    // 3. Call API async (soft delete)
    _notificationService.deleteNotification(notificationId).then((_) {
      _pendingDeleteIds.remove(notificationId);
    }).catchError((error) {
      _pendingDeleteIds.remove(notificationId);

      // If user already hit UNDO, don't try to pop/restore again.
      if (_undoRequestedIds.contains(notificationId)) {
        return;
      }

      // On error, remove the matching entry from the stack (by id) and restore
      _deletedNotificationsStack.removeWhere((n) => n['id'] == notificationId);
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

    // Each SnackBar owns its own notifier; dispose it only after `closed`.
    final countdown = ValueNotifier<int>(5);
    _undoCountdown = countdown;

    final snackBar = SnackBar(
      content: ValueListenableBuilder<int>(
        valueListenable: countdown,
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
      // Always clean up after the snackbar fully closes (even if this screen
      // has since been disposed).
      _undoCountdownTimer?.cancel();
      _undoCountdownTimer = null;

      try {
        countdown.dispose();
      } catch (_) {
        // ignore
      }

      if (identical(_undoCountdown, countdown)) {
        _undoCountdown = null;
      }
      _undoSnackBarController = null;
    });

    // Drive countdown + make sure snackbar is dismissed exactly at 0.
    _undoCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      final next = countdown.value - 1;
      countdown.value = next;

      if (next <= 0) {
        t.cancel();
        _undoCountdownTimer = null;

        // Requirement: dismiss when countdown reaches 0 (not just via duration).
        _undoSnackBarController?.close();
        // Do not dispose the notifier here; wait for SnackBar `closed`.
      }
    });
  }

  /// Handle undo action - restore the last deleted notification
  void _handleUndo() {
    if (_deletedNotificationsStack.isEmpty) return;

    final notificationToRestore = _deletedNotificationsStack.removeLast();
    final restoreId = notificationToRestore['id'] as String;
    _undoRequestedIds.add(restoreId);

    // Suppress snackbar for this restored notification
    _suppressNewSnackbarsForNotificationIds.add(restoreId);

    // IMMEDIATE: Add back to local state
    final notifier = ref.read(notificationsNotifier.notifier);
    notifier.addNotification(notificationToRestore);

    // Call restore API (UPDATE, not INSERT - no push triggered!)
    _notificationService.restoreNotification(restoreId).then((_) {
      debugPrint('✅ Notification restored in DB');
      _undoRequestedIds.remove(restoreId);
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
      _undoRequestedIds.remove(restoreId);
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
      case 'friend_daily_capsule_completed':
      case 'daily_capsule_reminder':
        return Icons.calendar_today_outlined;
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