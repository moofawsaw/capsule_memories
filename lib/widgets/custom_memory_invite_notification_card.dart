import 'package:intl/intl.dart';

import '../core/app_export.dart';
import '../services/notification_service.dart';

class _InviteCtx {
  final String? inviteId;
  final String? memoryId;
  final String? notificationId;
  final String inviterName;
  final String memoryTitle;

  const _InviteCtx({
    required this.inviteId,
    required this.memoryId,
    required this.notificationId,
    required this.inviterName,
    required this.memoryTitle,
  });
}
/// A notification card specifically for memory invites with Accept/Decline buttons
class MemoryInviteNotificationCard extends StatefulWidget {
  const MemoryInviteNotificationCard({
    Key? key,
    required this.notification,
    required this.onActionCompleted,
    required this.onNavigateToMemory,
  }) : super(key: key);

  final Map<String, dynamic> notification;
  final VoidCallback onActionCompleted;
  final Function(String memoryId) onNavigateToMemory;

  @override
  State<MemoryInviteNotificationCard> createState() =>
      _MemoryInviteNotificationCardState();
}

class _MemoryInviteNotificationCardState
    extends State<MemoryInviteNotificationCard> {
  bool _isLoading = false;
  bool _syncedInviteAction = false;
  String? _syncedActionTaken;
  String? _syncedActionDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncInviteActionIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant MemoryInviteNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If notification data changed, allow re-sync once.
    if (oldWidget.notification['id'] != widget.notification['id']) {
      _syncedInviteAction = false;
      _syncedActionTaken = null;
      _syncedActionDate = null;
    }
    _syncInviteActionIfNeeded();
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  String _formatActionDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('MMM d, yyyy').format(date);
  }

  _InviteCtx _inviteCtx() {
  final raw = widget.notification;

  final data = (raw['data'] as Map?)?.cast<String, dynamic>() ?? {};
  final enriched =
  (raw['enriched_data'] as Map?)?.cast<String, dynamic>() ?? {};

  // Be permissive: these payload keys tend to drift as you enrich/transform.
  final inviteId = (data['invite_id'] ??
  data['memory_invite_id'] ??
  enriched['invite_id'] ??
  enriched['memory_invite_id'])
      ?.toString();

  final memoryId = (data['memory_id'] ??
  enriched['memory_id'] ??
  enriched['memoryId'] ??
  raw['memory_id'])
      ?.toString();

  final notificationId = raw['id']?.toString();

  final inviterName = (data['inviter_name'] ??
  enriched['inviter_name'] ??
  enriched['inviterName'] ??
  'Someone')
      .toString();

  final memoryTitle = (data['memory_title'] ??
  enriched['memory_name'] ??
  enriched['memory_title'] ??
  enriched['memoryTitle'] ??
  'a memory')
      .toString();

  return _InviteCtx(
  inviteId: inviteId,
  memoryId: memoryId,
  notificationId: notificationId,
  inviterName: inviterName,
  memoryTitle: memoryTitle,
  );
  }

  Future<void> _syncInviteActionIfNeeded() async {
    if (_syncedInviteAction) return;
    _syncedInviteAction = true;

    final data = (widget.notification['data'] as Map?)?.cast<String, dynamic>() ?? {};
    // If the notification already contains an action, trust it.
    if ((data['action_taken'] as String?)?.trim().isNotEmpty == true &&
        (data['action_date'] as String?)?.trim().isNotEmpty == true) {
      return;
    }

    final ctx = _inviteCtx();
    final inviteId = (ctx.inviteId ?? '').trim();
    final notificationId = (ctx.notificationId ?? '').trim();
    if (inviteId.isEmpty || notificationId.isEmpty) return;

    final invite = await NotificationService.instance.getMemoryInviteById(inviteId);
    if (!mounted) return;
    if (invite == null) return;

    final status = (invite['status'] ?? '').toString().trim();
    final respondedAt = invite['responded_at']?.toString();
    if (status != 'accepted' || respondedAt == null || respondedAt.trim().isEmpty) {
      return;
    }

    // Locally reflect accepted state immediately (even before notification row updates).
    setState(() {
      _syncedActionTaken = 'accepted';
      _syncedActionDate = respondedAt;
    });

    // Persist the same "accepted" markers the notifications screen uses when accepting in-card.
    try {
      final formattedDate = _formatActionDate(respondedAt);
      await NotificationService.instance.updateNotificationContent(
        notificationId: notificationId,
        newMessage: 'You joined "${ctx.memoryTitle}" on $formattedDate',
        additionalData: {
          'action_taken': 'accepted',
          'action_date': respondedAt,
          if (ctx.memoryId != null) 'memory_id': ctx.memoryId,
          if (ctx.inviteId != null) 'invite_id': ctx.inviteId,
          'inviter_name': ctx.inviterName,
          'memory_title': ctx.memoryTitle,
        },
      );
    } catch (_) {
      // Best-effort: UI is already updated locally.
    }

    // Ensure parent list reloads so this card reflects the persisted update too.
    widget.onActionCompleted();
  }

  Future<void> _handleAccept() async {
  final ctx = _inviteCtx();

  // Notification id is mandatory (we update the notification regardless).
  if (ctx.notificationId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Invalid invite - missing notification id'),
  ),
  );
  return;
  }

  // For sealed memories, invite_id might be missing (or invite row may be gone),
  // but memory_id should still allow joining. Require at least ONE.
  if (ctx.inviteId == null && ctx.memoryId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Invalid invite - missing invite and memory information'),
  ),
  );
  return;
  }

  setState(() => _isLoading = true);

  try {
  // If the notification was already acted on (client-side), don’t do it twice.
  final existingData =
  (widget.notification['data'] as Map?)?.cast<String, dynamic>() ?? {};
  final alreadyActioned = existingData['action_taken'] != null;
  if (alreadyActioned) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('This invite has already been responded to'),
  ),
  );
  }
  widget.onActionCompleted();
  return;
  }

  bool joined = false;

  // 1) Preferred path: accept by invite id (works for normal, unsealed flows)
  if (ctx.inviteId != null) {
  // IMPORTANT: we no longer hard-fail sealed/old invites here.
  // We attempt pending-check, but if it fails due to sealed/expired logic,
  // we fall back to joining by memory_id (keeps invites “always valid”).
  try {
  final isPending =
  await NotificationService.instance.isInviteStillPending(ctx.inviteId!);

  if (!isPending) {
  // If it’s not pending, it may be already accepted OR it may be sealed logic.
  // We still allow join-by-memory fallback if memoryId exists.
  if (ctx.memoryId != null) {
  await NotificationService.instance.joinMemoryById(ctx.memoryId!);
  joined = true;
  } else {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('This invite has already been responded to'),
  ),
  );
  }
  widget.onActionCompleted();
  return;
  }
  } else {
  await NotificationService.instance.acceptMemoryInvite(ctx.inviteId!);
  joined = true;
  }
  } catch (_) {
  // Pending-check or accept failed (often due to sealed/expired invite logic).
  if (ctx.memoryId != null) {
  await NotificationService.instance.joinMemoryById(ctx.memoryId!);
  joined = true;
  } else {
  rethrow;
  }
  }
  } else {
  // 2) Sealed-safe path: join directly by memory id
  await NotificationService.instance.joinMemoryById(ctx.memoryId!);
  joined = true;
  }

  if (!joined) {
  throw Exception('Unable to join memory');
  }

  // Optional small delay to let triggers settle (if any)
  await Future.delayed(const Duration(milliseconds: 400));

  final actionDate = DateTime.now().toIso8601String();
  final formattedDate = _formatActionDate(actionDate);

  await NotificationService.instance.updateNotificationContent(
  notificationId: ctx.notificationId!,
  newMessage: 'You joined "${ctx.memoryTitle}" on $formattedDate',
  additionalData: {
  'action_taken': 'accepted',
  'action_date': actionDate,

  // Keep these so future UI always has what it needs
  if (ctx.memoryId != null) 'memory_id': ctx.memoryId,
  if (ctx.inviteId != null) 'invite_id': ctx.inviteId,
  'inviter_name': ctx.inviterName,
  'memory_title': ctx.memoryTitle,
  },
  );

  if (mounted) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  content: const Text('You joined the memory!'),
  duration: const Duration(seconds: 3),
  action: ctx.memoryId != null
  ? SnackBarAction(
  label: 'View',
  textColor: Colors.white,
  onPressed: () => widget.onNavigateToMemory(ctx.memoryId!),
  )
      : null,
  ),
  );
  }

  await Future.delayed(const Duration(milliseconds: 200));

  if (ctx.memoryId != null && mounted) {
  widget.onNavigateToMemory(ctx.memoryId!);
  }

  widget.onActionCompleted();
  } catch (error) {
  debugPrint('❌ Failed to accept invite: $error');
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  content: Text('Failed to accept invite: $error'),
  ),
  );
  }
  } finally {
  if (mounted) {
  setState(() => _isLoading = false);
  }
  }
  }

  Future<void> _handleDecline() async {
  final ctx = _inviteCtx();

  if (ctx.notificationId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Invalid invite - missing notification id'),
  ),
  );
  return;
  }

  // For decline, invite_id is optional (sealed invites may not have it).
  // If we have neither invite_id nor memory_id, we still can’t do anything meaningful.
  if (ctx.inviteId == null && ctx.memoryId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Invalid invite - missing invite and memory information'),
  ),
  );
  return;
  }

  setState(() => _isLoading = true);

  try {
  final existingData =
  (widget.notification['data'] as Map?)?.cast<String, dynamic>() ?? {};
  final alreadyActioned = existingData['action_taken'] != null;
  if (alreadyActioned) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('This invite has already been responded to'),
  ),
  );
  }
  widget.onActionCompleted();
  return;
  }

  // If we have an invite id, attempt to decline it. If it fails (sealed logic),
  // we still mark the notification declined (UX requirement).
  if (ctx.inviteId != null) {
  try {
  final isPending =
  await NotificationService.instance.isInviteStillPending(ctx.inviteId!);
  if (isPending) {
  await NotificationService.instance.declineMemoryInvite(ctx.inviteId!);
  }
  } catch (_) {
  // ignore and still update notification
  }
  }

  final actionDate = DateTime.now().toIso8601String();
  final formattedDate = _formatActionDate(actionDate);

  await NotificationService.instance.updateNotificationContent(
  notificationId: ctx.notificationId!,
  newMessage: 'You declined "${ctx.memoryTitle}" on $formattedDate',
  additionalData: {
  'action_taken': 'declined',
  'action_date': actionDate,
  if (ctx.memoryId != null) 'memory_id': ctx.memoryId,
  if (ctx.inviteId != null) 'invite_id': ctx.inviteId,
  'inviter_name': ctx.inviterName,
  'memory_title': ctx.memoryTitle,
  },
  );

  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
  content: Text('Invite declined'),
  duration: Duration(seconds: 2),
  ),
  );
  }

  widget.onActionCompleted();
  } catch (error) {
  debugPrint('❌ Failed to decline invite: $error');
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
  content: Text('Failed to decline invite: $error'),
  ),
  );
  }
  } finally {
  if (mounted) {
  setState(() => _isLoading = false);
  }
  }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = widget.notification['is_read'] as bool? ?? false;
    final data = widget.notification['data'] as Map<String, dynamic>?;
    final actionTaken = (data?['action_taken'] as String?) ?? _syncedActionTaken;
    final actionDate = (data?['action_date'] as String?) ?? _syncedActionDate;
    final memoryId = (data?['memory_id'] as String?) ?? _inviteCtx().memoryId;

    final inviterName = data?['inviter_name'] as String? ??
        widget.notification['enriched_data']?['inviter_name'] as String? ??
        'Someone';
    final memoryTitle = data?['memory_title'] as String? ??
        widget.notification['enriched_data']?['memory_name'] as String? ??
        'a memory';

    DateTime? timestamp;
    if (widget.notification['created_at'] != null) {
      timestamp = DateTime.parse(widget.notification['created_at'] as String);
    }

    return GestureDetector(
      onTap: memoryId != null
          ? () {
              debugPrint(
                  '🎯 Memory invite notification tapped - navigating to memory: $memoryId');
              widget.onNavigateToMemory(memoryId);
            }
          : null,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: isRead ? Colors.transparent : appTheme.deep_purple_A100.withAlpha(20),
          borderRadius: BorderRadius.circular(12.h),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color: appTheme.deep_purple_A100.withAlpha(30),
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    color: appTheme.deep_purple_A100,
                    size: 24.h,
                  ),
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Memory Invitation',
                        style: TextStyleHelper
                            .instance.title18BoldPlusJakartaSans
                            .copyWith(
                          color: isRead
                              ? appTheme.blue_gray_300
                              : appTheme.gray_50,
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyleHelper
                              .instance.body12RegularPlusJakartaSans
                              .copyWith(
                            color: appTheme.blue_gray_300.withAlpha(153),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            // Invite message
            Text(
              actionTaken != null
                  ? 'Invitation from $inviterName to join "$memoryTitle"'
                  : '$inviterName invited you to join "$memoryTitle"',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(
                color: isRead ? appTheme.blue_gray_300 : appTheme.blue_gray_300,
              ),
            ),
            SizedBox(height: 16.h),
            // Show badge if action was taken, otherwise show buttons
            if (actionTaken != null && actionDate != null)
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: actionTaken == 'accepted'
                          ? Colors.green.withAlpha(30)
                          : Colors.grey.withAlpha(30),
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          actionTaken == 'accepted'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 18.h,
                          color: actionTaken == 'accepted'
                              ? Colors.green
                              : Colors.grey,
                        ),
                        SizedBox(width: 8.h),
                        Text(
                          actionTaken == 'accepted' ? 'Accepted' : 'Declined',
                          style: TextStyle(
                            color: actionTaken == 'accepted'
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(width: 8.h),
                        Text(
                          '• ${_formatActionDate(actionDate)}',
                          style: TextStyle(
                            color: (actionTaken == 'accepted'
                                    ? Colors.green
                                    : Colors.grey)
                                .withAlpha(180),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionTaken == 'accepted' && memoryId != null)
                    Padding(
                      padding: EdgeInsets.only(left: 8.h),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16.h,
                        color: Colors.green.withAlpha(180),
                      ),
                    ),
                ],
              )
            else if (actionTaken == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: appTheme.blue_gray_300,
                        side: BorderSide(color: appTheme.blue_gray_300),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 16.h,
                              width: 16.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: appTheme.blue_gray_300,
                              ),
                            )
                          : const Text('Decline'),
                    ),
                  ),
                  SizedBox(width: 12.h),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.deep_purple_A100,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 16.h,
                              width: 16.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
