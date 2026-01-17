import '../../core/app_export.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import './widgets/following_user_item_widget.dart';
import 'models/following_list_model.dart';
import 'notifier/following_list_notifier.dart';

class FollowingListScreen extends ConsumerStatefulWidget {
  FollowingListScreen({Key? key}) : super(key: key);

  @override
  FollowingListScreenState createState() => FollowingListScreenState();
}

class FollowingListScreenState extends ConsumerState<FollowingListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(followingListNotifier.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: SizedBox(
          width: double.maxFinite,
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Column(
                    children: [
                      _buildTabSection(context),
                      SizedBox(height: 14.h),

                      // ✅ Search lives on Following screen
                      _buildSearchSection(context),

                      SizedBox(height: 14.h),
                      Expanded(child: _buildFollowingList(context)),
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

  /// Tab header
  Widget _buildTabSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(followingListNotifier);
        final followingCount =
            state.followingListModel?.followingUsers?.length ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 2.h),
              child: CustomImageView(
                imagePath: ImageConstant.imgIcon11,
                height: 26.h,
                width: 26.h,
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(6.h, 4.h, 0, 0),
              child: Text(
                'Following ($followingCount)',
                style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans
                    .copyWith(height: 1.3),
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                onTapFollowersTab(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
                decoration: BoxDecoration(
                  color: appTheme.color41C124,
                  border: Border.all(
                    color: appTheme.blue_gray_900,
                    width: 1.h,
                  ),
                  borderRadius: BorderRadius.circular(22.h),
                ),
                child: Text(
                  'Followers',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50, height: 1.31),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Search box + dropdown results (RPC-backed)
  Widget _buildSearchSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(followingListNotifier);
      final notifier = ref.read(followingListNotifier.notifier);

      final query = (state.searchQuery ?? '').trim();
      final results = state.searchResults ?? <FollowingSearchUserModel>[];
      final isSearching = state.isSearching ?? false;

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
                border: Border.all(
                  color: appTheme.gray_50.withAlpha(25),
                  width: 1,
                ),
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
                      if (userId.isEmpty) return;

                      NavigatorService.pushNamed(
                        AppRoutes.appProfileUser,
                        arguments: {'userId': userId},
                      );
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
                          _buildSearchActionPill(
                            context: context,
                            ref: ref,
                            user: user,
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

  Widget _buildAvatar(String imagePath) {
    return Container(
      width: 34.h,
      height: 34.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appTheme.gray_900_02,
        border: Border.all(
          color: appTheme.gray_50.withAlpha(18),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: imagePath.isNotEmpty
            ? CustomImageView(
          imagePath: imagePath,
          fit: BoxFit.cover,
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

  Widget _buildSearchActionPill({
    required BuildContext context,
    required WidgetRef ref,
    required FollowingSearchUserModel user,
  }) {
    final notifier = ref.read(followingListNotifier.notifier);
    final userId = user.id ?? '';
    final isFollowing = user.isFollowing ?? false;

    if (userId.isEmpty) return const SizedBox.shrink();

    if (isFollowing) {
      return GestureDetector(
        onTap: () async {
          final display = (user.displayName?.isNotEmpty ?? false)
              ? user.displayName!
              : (user.userName ?? 'this user');

          final confirmed = await CustomConfirmationDialog.show(
            context: context,
            title: 'Unfollow $display?',
            message:
            'Are you sure you want to unfollow this user? You can always follow them again later.',
            confirmText: 'Unfollow',
            cancelText: 'Cancel',
            confirmColor: appTheme.red_500,
            icon: Icons.person_remove_outlined,
          );

          if (confirmed == true) {
            // optimistic UI
            notifier.updateSearchUserFollowing(userId, false);
            await notifier.unfollowUser(userId);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            borderRadius: BorderRadius.circular(14.h),
            border: Border.all(
              color: appTheme.gray_50.withAlpha(40),
              width: 1,
            ),
          ),
          child: Text(
            'Following',
            style: TextStyleHelper.instance.body12RegularPlusJakartaSans.copyWith(
              color: appTheme.gray_50.withAlpha(160),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        // optimistic UI
        notifier.updateSearchUserFollowing(userId, true);

        final ok = await notifier.followUser(userId);
        if (!ok) {
          notifier.updateSearchUserFollowing(userId, false);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
        decoration: BoxDecoration(
          color: appTheme.deep_purple_A100,
          borderRadius: BorderRadius.circular(14.h),
        ),
        child: Text(
          'Follow',
          style: TextStyleHelper.instance.body12RegularPlusJakartaSans.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Following list
  Widget _buildFollowingList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(followingListNotifier);

        if (state.isLoading ?? false) {
          return Center(
            child: CircularProgressIndicator(
              color: appTheme.deep_purple_A100,
            ),
          );
        }

        final followingUsers = state.followingListModel?.followingUsers ?? [];

        if (followingUsers.isEmpty) {
          return Center(
            child: Text(
              'No following yet',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
            ),
          );
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8.h),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: BouncingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) => SizedBox(height: 20.h),
            itemCount: followingUsers.length,
            itemBuilder: (context, index) {
              final user = followingUsers[index];
              return FollowingUserItemWidget(
                user: user,
                onUserTap: () {
                  onTapFollowingUser(context, user);
                },
                onActionTap: () {
                  onTapUserAction(context, user);
                },
              );
            },
          ),
        );
      },
    );
  }

  void onTapFollowersTab(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appFollowers);
  }

  void onTapFollowingUser(BuildContext context, FollowingUserModel? user) {
    if (user?.id == null || user!.id!.isEmpty) return;

    NavigatorService.pushNamed(
      AppRoutes.appProfileUser,
      arguments: {'userId': user.id},
    );
  }

  void onTapUserAction(BuildContext context, FollowingUserModel? user) async {
    if (user == null) return;

    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Unfollow ${user.name}?',
      message:
      'Are you sure you want to unfollow this user? You can always follow them again later.',
      confirmText: 'Unfollow',
      cancelText: 'Cancel',
      confirmColor: appTheme.red_500,
      icon: Icons.person_remove_outlined,
    );

    if (confirmed == true) {
      await ref.read(followingListNotifier.notifier).unfollowUser(user.id ?? '');
    }
  }
}
