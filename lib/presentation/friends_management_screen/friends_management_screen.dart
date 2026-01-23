import '../../core/app_export.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import '../qr_code_share_screen_two_screen/qr_code_share_screen_two_screen.dart';
import './widgets/friends_section_widget.dart';
import './widgets/incoming_requests_section_widget.dart';
import './widgets/qr_scanner_overlay.dart';
import '../../services/supabase_service.dart';
import './widgets/sent_requests_section_widget.dart';
import 'notifier/friends_management_notifier.dart';

class FriendsManagementScreen extends ConsumerStatefulWidget {
  const FriendsManagementScreen({Key? key}) : super(key: key);

  @override
  FriendsManagementScreenState createState() => FriendsManagementScreenState();
}

class FriendsManagementScreenState
    extends ConsumerState<FriendsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsManagementNotifier.notifier).initialize();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(friendsManagementNotifier.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(friendsManagementNotifier);

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: appTheme.deep_purple_A100,
        backgroundColor: appTheme.gray_900_01,
        displacement: 30,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Column(
                    children: [
                      _buildFriendsHeaderSection(context),
                      SizedBox(height: 16.h),
                      _buildSearchSection(context),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 20.h),
                              FriendsSectionWidget(),
                              SizedBox(height: 20.h),
                              SentRequestsSectionWidget(),
                              SizedBox(height: 20.h),
                              IncomingRequestsSectionWidget(),
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsHeaderSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(friendsManagementNotifier);

      // ✅ state lists are non-null now
      final friendsCount = state.filteredFriendsList.length;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26.h,
            height: 26.h,
            margin: EdgeInsets.only(top: 2.h),
            child: CustomImageView(
              imagePath: ImageConstant.imgIconDeepPurpleA100,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 6.h),
          Container(
            margin: EdgeInsets.only(top: 2.h),
            child: Text(
              'Friends ($friendsCount)',
              style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans,
            ),
          ),
          Spacer(),
          CustomIconButtonRow(
            firstIconPath: ImageConstant.imgButtons,
            firstIconColor: appTheme.white_A700,
            secondIcon: Icons.camera_alt,
            onFirstIconTap: () => _openQRShareBottomSheet(context),
            onSecondIconTap: () => onTapCameraButton(context),
          ),
        ],
      );
    });
  }

  void _openQRShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QRCodeShareScreenTwoScreen(),
    );
  }

  Widget _buildSearchSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(friendsManagementNotifier);
      final notifier = ref.read(friendsManagementNotifier.notifier);

      final query = state.searchQuery.trim();
      final results = state.searchResults;
      final isSearching = state.isSearching;
      final showPanel = query.isNotEmpty;

      return Column(
        children: [
          CustomSearchView(
            controller: notifier.searchController,
            placeholder: 'Search for people...',
            onChanged: (value) => notifier.onSearchChanged(value),
          ),
          if (showPanel) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: appTheme.gray_900_01,
                borderRadius: BorderRadius.circular(14.h),
              ),
              child: isSearching
                  ? Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.h,
                  vertical: 14.h,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18.h,
                      height: 18.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: appTheme.deep_purple_A100,
                      ),
                    ),
                    SizedBox(width: 10.h),
                    Text(
                      'Searching...',
                      style: TextStyleHelper
                          .instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                  ],
                ),
              )
                  : (results.isEmpty
                  ? Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.h,
                  vertical: 14.h,
                ),
                child: Text(
                  'No users found',
                  style: TextStyleHelper
                      .instance.body14RegularPlusJakartaSans
                      .copyWith(
                    color: appTheme.gray_50.withAlpha(160),
                  ),
                ),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: appTheme.gray_50.withAlpha(12),
                ),
                itemBuilder: (context, index) {
                  final user = results[index];

                  final title =
                  (user.displayName?.isNotEmpty ?? false)
                      ? user.displayName!
                      : (user.userName ?? 'User');

                  final subtitle =
                  (user.userName?.isNotEmpty ?? false)
                      ? '@${user.userName}'
                      : '';

                  return InkWell(
                    onTap: () {
                      final userId = user.id ?? '';
                      if (userId.isNotEmpty) {
                        NavigatorService.pushNamed(
                          AppRoutes.appProfileUser,
                          arguments: {'userId': userId},
                        );
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.h,
                        vertical: 10.h,
                      ),
                      child: Row(
                        children: [
                          _buildAvatar(user.profileImagePath ?? ''),
                          SizedBox(width: 10.h),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyleHelper.instance
                                      .body14RegularPlusJakartaSans
                                      .copyWith(
                                    color: appTheme.gray_50,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyleHelper.instance
                                        .body12RegularPlusJakartaSans
                                        .copyWith(
                                      color: appTheme.gray_50
                                          .withAlpha(140),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 10.h),
                          _buildFriendActionPill(
                            ref: ref,
                            userId: user.id ?? '',
                            status: user.friendshipStatus,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
            ),
          ],
        ],
      );
    });
  }

  // Converts a raw profileImagePath into a usable URL.
  // - If it's already http(s), use it directly.
  // - If it's a storage key (e.g. "uid.png" or "avatars/uid.png"), convert to public URL.
  // NOTE: change bucket name if yours isn't "avatars".
  String _resolveAvatarUrl(String rawPath) {
    final path = rawPath.trim();
    if (path.isEmpty) return '';

    final lower = path.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return path;
    }

    try {
      final supabase = SupabaseService.instance.client;
      if (supabase == null) return '';

      // If your DB already stores "avatars/xxx.png", strip the folder if needed.
      // Keep as-is for most setups.
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
      return publicUrl;
    } catch (_) {
      return '';
    }
  }

  Widget _buildAvatar(String imagePath) {
    final url = _resolveAvatarUrl(imagePath);

    return Container(
      width: 34.h,
      height: 34.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appTheme.gray_900_02,
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(
          url,
          width: 34.h,
          height: 34.h,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, __, ___) {
            return Center(
              child: Icon(
                Icons.person,
                size: 18.h,
                color: appTheme.gray_50.withAlpha(120),
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 16.h,
                height: 16.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appTheme.deep_purple_A100.withAlpha(180),
                ),
              ),
            );
          },
        )
            : Center(
          child: Icon(
            Icons.person,
            size: 18.h,
            color: appTheme.gray_50.withAlpha(120),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendActionPill({
    required WidgetRef ref,
    required String userId,
    required String status,
  }) {
    final notifier = ref.read(friendsManagementNotifier.notifier);

    final normalized = status.startsWith('pending')
        ? 'pending'
        : (status == 'friends' ? 'friends' : 'none');

    if (normalized == 'none') {
      return GestureDetector(
        onTap: () async {
          if (userId.isEmpty) return;

          notifier.updateSearchUserStatus(userId, 'pending');
          await notifier.sendFriendRequest(userId);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
          decoration: BoxDecoration(
            color: appTheme.deep_purple_A100,
            borderRadius: BorderRadius.circular(14.h),
          ),
          child: Text(
            'Add Friend',
            style: TextStyleHelper.instance.body12RegularPlusJakartaSans.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (normalized == 'pending') return _statusPill('Requested');
    if (normalized == 'friends') return _statusPill('Friends');

    return const SizedBox.shrink();
  }

  Widget _statusPill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.circular(14.h),
      ),
      child: Text(
        text,
        style: TextStyleHelper.instance.body12RegularPlusJakartaSans.copyWith(
          color: appTheme.gray_50.withAlpha(160),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void onTapCameraButton(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QRScannerOverlay(
          scanType: 'friend',
          onSuccess: () {
            ref.read(friendsManagementNotifier.notifier).initialize();
          },
        ),
      ),
    );
  }
}
