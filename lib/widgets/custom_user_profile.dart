import '../core/app_export.dart';

class CustomUserProfile extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String? avatarImagePath;
  final VoidCallback? onTap;

  const CustomUserProfile({
    Key? key,
    required this.userName,
    required this.userEmail,
    this.avatarImagePath,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate avatar letter from email
    final avatarLetter =
        userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar - show letter or image
          Container(
            width: 52.h,
            height: 52.h,
            decoration: BoxDecoration(
              color: avatarImagePath != null ? null : appTheme.deep_purple_A100,
              shape: BoxShape.circle,
              image: avatarImagePath != null
                  ? DecorationImage(
                      image: NetworkImage(avatarImagePath!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarImagePath == null
                ? Center(
                    child: Text(
                      avatarLetter,
                      style: TextStyle(
                        color: appTheme.white_A700,
                        fontSize: 24.fSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: 12.h),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    color: appTheme.white_A700,
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: appTheme.gray_50,
                    fontSize: 14.fSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
