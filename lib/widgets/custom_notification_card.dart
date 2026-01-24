import '../core/app_export.dart';
import 'package:intl/intl.dart';

/**
 * CustomNotificationCard - A reusable card component for displaying notifications
 * 
 * Features:
 * - Clean card layout with interactive read/unread icon button
 * - Configurable read/unread visual states
 * - Separate tap handlers for card and icon button
 * - Envelope icons (open/closed) for read/unread state
 * - Customizable colors for title, description, and background
 * - Responsive design with proper spacing
 * - Timestamp display showing when notification was received
 */
class CustomNotificationCard extends StatelessWidget {
  const CustomNotificationCard({
    Key? key,
    required this.leadingIcon,
    required this.title,
    required this.description,
    required this.isRead,
    required this.onToggleRead,
    this.timestamp,
    this.iconColor,
    this.titleFontSize,
    this.descriptionAlignment,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.titleColor,
    this.descriptionColor,
  }) : super(key: key);

  final IconData leadingIcon;
  final Color? iconColor;
  final String title;
  final String description;
  final bool isRead;
  final VoidCallback onToggleRead;
  final DateTime? timestamp;
  final double? titleFontSize;
  final TextAlign? descriptionAlignment;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? descriptionColor;

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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint('🎯 Notification card tapped');
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            margin: margin ?? EdgeInsets.zero, // ✅ no outer inset
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h), // ✅ inner padding only
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  leadingIcon,
                  size: 28.h,
                  color: iconColor ?? appTheme.deep_purple_A100,
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyleHelper
                            .instance.title18BoldPlusJakartaSans
                            .copyWith(
                          color: titleColor ?? appTheme.gray_50,
                          height: 1.22,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: TextStyleHelper
                            .instance.body14RegularPlusJakartaSans
                            .copyWith(
                          color: descriptionColor ?? appTheme.blue_gray_300,
                          height: 1.29,
                        ),
                      ),
                      if (timestamp != null) ...[
                        SizedBox(height: 6.h),
                        Text(
                          _formatTimestamp(timestamp!),
                          style: TextStyleHelper
                              .instance.body12RegularPlusJakartaSans
                              .copyWith(
                            color: appTheme.blue_gray_300.withAlpha(153),
                            height: 1.33,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12.h),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      debugPrint('🎯 Toggle read button tapped');
                      onToggleRead();
                    },
                    borderRadius: BorderRadius.circular(24.h),
                    child: Container(
                      height: 48.h,
                      width: 48.h,
                      decoration: BoxDecoration(
                        color: appTheme.blue_gray_900_02,
                        borderRadius: BorderRadius.circular(24.h),
                      ),
                      padding: EdgeInsets.all(12.h),
                      child: Icon(
                        isRead
                            ? Icons.mark_email_read
                            : Icons.mark_email_unread,
                        size: 24.h,
                        color: isRead
                            ? appTheme.blue_gray_300
                            : appTheme.deep_purple_A100,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
