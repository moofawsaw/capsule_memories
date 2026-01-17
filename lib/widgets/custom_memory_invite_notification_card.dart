import 'package:intl/intl.dart';

import '../core/app_export.dart';
import '../services/notification_service.dart';

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

  Future<void> _handleAccept() async {
    final data = widget.notification['data'] as Map<String, dynamic>?;
    final inviteId = data?['invite_id'] as String?;
    final memoryId = data?['memory_id'] as String?;
    final notificationId = widget.notification['id'] as String?;

    if (inviteId == null || notificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid invite - missing required information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if invite is still pending
      final isPending =
          await NotificationService.instance.isInviteStillPending(inviteId);
      if (!isPending) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This invite has already been responded to'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        widget.onActionCompleted();
        return;
      }

      // Accept the invite in database
      await NotificationService.instance.acceptMemoryInvite(inviteId);

      // Wait for database trigger to complete
      await Future.delayed(const Duration(milliseconds: 800));

      // Get memory title for updated message
      final inviterName = data?['inviter_name'] as String? ??
          widget.notification['enriched_data']?['inviter_name'] as String? ??
          'Someone';
      final memoryTitle = data?['memory_title'] as String? ??
          widget.notification['enriched_data']?['memory_name'] as String? ??
          'a memory';

      final actionDate = DateTime.now().toIso8601String();
      final formattedDate = _formatActionDate(actionDate);

      // Update notification with accepted message
      await NotificationService.instance.updateNotificationContent(
        notificationId: notificationId,
        newMessage: 'You joined "$memoryTitle" on $formattedDate',
        additionalData: {
          'action_taken': 'accepted',
          'action_date': actionDate,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You joined the memory!'),
            backgroundColor: Colors.green,
            action: memoryId != null
                ? SnackBarAction(
                    label: 'View',
                    textColor: Colors.white,
                    onPressed: () => widget.onNavigateToMemory(memoryId),
                  )
                : null,
          ),
        );
      }

      // Add delay before navigation
      await Future.delayed(const Duration(milliseconds: 200));

      if (memoryId != null && mounted) {
        widget.onNavigateToMemory(memoryId);
      }

      widget.onActionCompleted();
    } catch (error) {
      debugPrint('❌ Failed to accept invite: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invite: $error'),
            backgroundColor: Colors.red,
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
    final data = widget.notification['data'] as Map<String, dynamic>?;
    final inviteId = data?['invite_id'] as String?;
    final notificationId = widget.notification['id'] as String?;

    if (inviteId == null || notificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid invite - missing required information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if invite is still pending
      final isPending =
          await NotificationService.instance.isInviteStillPending(inviteId);
      if (!isPending) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This invite has already been responded to'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        widget.onActionCompleted();
        return;
      }

      // Decline the invite in the database
      await NotificationService.instance.declineMemoryInvite(inviteId);

      // Get memory title for updated message
      final memoryTitle = data?['memory_title'] as String? ??
          widget.notification['enriched_data']?['memory_name'] as String? ??
          'a memory';

      final actionDate = DateTime.now().toIso8601String();
      final formattedDate = _formatActionDate(actionDate);

      // Update notification with declined message instead of deleting
      await NotificationService.instance.updateNotificationContent(
        notificationId: notificationId,
        newMessage: 'You declined "$memoryTitle" on $formattedDate',
        additionalData: {
          'action_taken': 'declined',
          'action_date': actionDate,
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
            backgroundColor: Colors.red,
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
    final actionTaken = data?['action_taken'] as String?;
    final actionDate = data?['action_date'] as String?;
    final memoryId = data?['memory_id'] as String?;

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
        margin: EdgeInsets.symmetric(horizontal: 20.h),
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : appTheme.deep_purple_A100.withAlpha(20),
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
