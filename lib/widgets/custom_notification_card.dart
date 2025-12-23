import '../core/app_export.dart';

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
 */
class CustomNotificationCard extends StatelessWidget {
  const CustomNotificationCard({
    Key? key,
    required this.iconPath,
    required this.title,
    required this.description,
    required this.isRead,
    required this.onToggleRead,
    this.titleFontSize,
    this.descriptionAlignment,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.titleColor,
    this.descriptionColor,
  }) : super(key: key);

  final String iconPath;
  final String title;
  final String description;
  final bool isRead;
  final VoidCallback onToggleRead;
  final double? titleFontSize;
  final TextAlign? descriptionAlignment;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? descriptionColor;

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
            margin: margin ?? EdgeInsets.symmetric(horizontal: 20.h),
            padding: EdgeInsets.all(16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
