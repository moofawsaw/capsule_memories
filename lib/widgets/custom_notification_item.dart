import 'package:intl/intl.dart';
import '../core/app_export.dart';

class CustomNotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const CustomNotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData _getNotificationIcon() {
    switch (notification['type']) {
      case 'memory_invite':
        return Icons.event;
      case 'friend_request':
        return Icons.person_add;
      case 'new_story':
        return Icons.video_library;
      case 'followed':
        return Icons.person;
      case 'memory_expiring':
        return Icons.timer;
      case 'memory_sealed':
        return Icons.lock;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification['type']) {
      case 'memory_invite':
        return Colors.blue;
      case 'friend_request':
        return Colors.green;
      case 'new_story':
        return Colors.purple;
      case 'followed':
        return Colors.orange;
      case 'memory_expiring':
        return Colors.amber;
      case 'memory_sealed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['is_read'] as bool;
    final iconColor = _getNotificationColor();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isRead ? Colors.transparent : Colors.blue.withAlpha(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _getNotificationIcon(),
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _formatTimestamp(notification['created_at']),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
