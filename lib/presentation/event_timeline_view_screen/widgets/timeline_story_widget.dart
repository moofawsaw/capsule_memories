import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/app_export.dart';

/// Data model for timeline story items
class TimelineStoryItem {
  const TimelineStoryItem({
    required this.backgroundImage,
    required this.userAvatar,
    required this.postedAt,
    this.timeLabel,
    this.storyId,
    this.isVideo = true,
  });

  final String backgroundImage;
  final String userAvatar;
  final DateTime postedAt;
  final String? timeLabel;
  final String? storyId;
  final bool isVideo;
}

/// Individual timeline story widget with vertical layout
/// Card at top, connector, avatar at bottom
class TimelineStoryWidget extends StatelessWidget {
  final TimelineStoryItem item;
  final VoidCallback? onTap;
  final double barPosition; // Y position of the horizontal bar

  const TimelineStoryWidget({
    Key? key,
    required this.item,
    this.onTap,
    this.barPosition = 85.0,
  }) : super(key: key);

  bool _isNetworkUrl(String? s) {
    if (s == null) return false;
    final v = s.trim();
    if (v.isEmpty) return false;
    if (v == 'null' || v == 'undefined') return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story Card (phone-shaped) - ABOVE THE BAR
            _buildStoryCard(),

            // Vertical connector from card to bar
            Container(
              width: 3.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4A),
                borderRadius: BorderRadius.circular(1.5.w),
              ),
            ),

            SizedBox(height: 4.h),

            // Vertical connector from bar to avatar
            Container(
              width: 3.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A4A),
                borderRadius: BorderRadius.circular(1.5.w),
              ),
            ),

            // User Avatar with ring
            _buildAvatarWithRing(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard() {
    final bg = item.backgroundImage.trim();

    return Container(
      width: 48.w,
      height: 68.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.h),
        border: Border.all(
          color: const Color(0xFF8B5CF6),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(102),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.h),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isNetworkUrl(bg))
              CachedNetworkImage(
                imageUrl: bg,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFF2A2A3A),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 16.h,
                    height: 16.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        appTheme.deep_purple_A100.withAlpha(128),
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF2A2A3A),
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white38,
                    size: 20.h,
                  ),
                ),
              )
            else
              Container(
                color: const Color(0xFF2A2A3A),
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.white38,
                  size: 20.h,
                ),
              ),

            if (item.isVideo)
              Center(
                child: Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18.h,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithRing() {
    final avatar = item.userAvatar.trim();

    return Container(
      width: 40.h,
      height: 40.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B5CF6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withAlpha(102),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(2.5.h),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1A1A2E),
        ),
        child: ClipOval(
          child: _isNetworkUrl(avatar)
              ? CachedNetworkImage(
            imageUrl: avatar,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: const Color(0xFF2A2A3A),
              alignment: Alignment.center,
              child: SizedBox(
                width: 12.h,
                height: 12.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    appTheme.deep_purple_A100.withAlpha(128),
                  ),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFF2A2A3A),
              child: Icon(
                Icons.person,
                color: Colors.white38,
                size: 20.h,
              ),
            ),
          )
              : Container(
            color: const Color(0xFF2A2A3A),
            child: Icon(
              Icons.person,
              color: Colors.white38,
              size: 20.h,
            ),
          ),
        ),
      ),
    );
  }
}
