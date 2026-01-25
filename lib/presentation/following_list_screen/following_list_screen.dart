import '../../core/app_export.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/custom_story_list.dart';
import '../../widgets/custom_story_skeleton.dart';
import './widgets/following_user_item_widget.dart';
import 'models/following_list_model.dart';
import 'models/following_story_item_model.dart';
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
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),

          // ✅ Stationary header (Following title + Followers pill)
          SliverPersistentHeader(
            pinned: true,
            delegate: _FixedSliverHeaderDelegate(
              height: 52.h,
              child: Container(
                color: appTheme.gray_900_02,
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                alignment: Alignment.center,
                child: _buildTabSection(context),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 14.h)),

          // Latest Stories should run edge-to-edge (no horizontal padding).
          SliverToBoxAdapter(child: _buildLatestStoriesSection(context)),

          SliverToBoxAdapter(child: SizedBox(height: 14.h)),

          // ✅ Pinned search (list scrolls BELOW it, not under it)
          Consumer(builder: (context, ref, _) {
            final state = ref.watch(followingListNotifier);
            final query = (state.searchQuery ?? '').trim();
            final resultsLen = state.searchResults?.length ?? 0;
            final isSearching = state.isSearching ?? false;

            final showPanel = query.isNotEmpty;

            // Best-effort height to prevent overlap. This doesn't need to be exact—
            // it just needs to be >= the rendered content height.
            final double base = 56.h; // search bar
            final double panel = showPanel
                ? (isSearching || resultsLen == 0
                    ? 56.h
                    : (resultsLen.clamp(0, 8) * 52.h) + 16.h)
                : 0;
            final double height = base + (showPanel ? (10.h + panel) : 0);

            return SliverPersistentHeader(
              pinned: true,
              delegate: _FixedSliverHeaderDelegate(
                height: height,
                child: Container(
                  color: appTheme.gray_900_02,
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  child: _buildSearchSection(context),
                ),
              ),
            );
          }),

          SliverToBoxAdapter(child: SizedBox(height: 14.h)),

          SliverPadding(
            // Match Followers list effective padding (16 + 8).
            padding: EdgeInsets.symmetric(horizontal: 24.h),
            sliver: _buildFollowingSliver(context),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        ],
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
              child: Icon(
                Icons.person_add_alt_1_rounded,
                size: 26.h,
                color: appTheme.deep_purple_A100,
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

  Widget _buildLatestStoriesSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(followingListNotifier);

      final List<FollowingStoryItemModel> items =
          state.latestStories ?? const <FollowingStoryItemModel>[];
      final bool isLoading = state.isLoadingStories ?? false;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.h),
            child: Text(
              'Latest Stories',
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 121.h,
            child: isLoading
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: 5,
                    itemBuilder: (_, __) => Container(
                      width: 90.h,
                      margin: EdgeInsets.only(right: 8.h),
                      child: CustomStorySkeleton(isCompact: true),
                    ),
                  )
                : items.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.h),
                        child: Text(
                          'No stories yet',
                          style: TextStyleHelper
                              .instance.body14RegularPlusJakartaSans
                              .copyWith(
                            color: appTheme.gray_50.withAlpha(128),
                          ),
                        ),
                      )
                    : CustomStoryList(
                        storyItems: items
                            .map(
                              (e) => CustomStoryItem(
                                backgroundImage: e.backgroundImage ?? '',
                                profileImage: e.profileImage ?? '',
                                timestamp: e.timestamp ?? '',
                                storyId: e.id,
                                isRead: e.isRead,
                              ),
                            )
                            .toList(),
                        onStoryTap: (index) => _onStoryTap(context, index),
                      ),
          ),
        ],
      );
    });
  }

  void _onStoryTap(BuildContext context, int index) {
    final items = ref.read(followingListNotifier).latestStories ??
        const <FollowingStoryItemModel>[];
    if (index < 0 || index >= items.length) return;

    final id = (items[index].id ?? '').trim();
    if (id.isEmpty) return;

    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: id,
    );
  }

// ONLY THE AVATAR PART MATTERS — everything else stays the same

  Widget _buildAvatar(String imagePath) {
    return SizedBox.square(
      dimension: 34.h,
      child: CustomImageView(
        imagePath: imagePath,
        height: 34.h,
        width: 34.h,
        fit: BoxFit.cover,
        isCircular: true,
        networkOnly: true,
        enableCategoryIconResolution: false,
        // CustomImageView now renders a safe built-in placeholder when empty/fails.
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

  Widget _buildFollowingSliver(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(followingListNotifier);

        if (state.isLoading ?? false) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                color: appTheme.deep_purple_A100,
              ),
            ),
          );
        }

        final followingUsers = state.followingListModel?.followingUsers ?? [];

        if (followingUsers.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No following yet',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final user = followingUsers[index];
              return Column(
                children: [
                  FollowingUserItemWidget(
                    user: user,
                    onUserTap: () {
                      onTapFollowingUser(context, user);
                    },
                    onActionTap: () {
                      onTapUserAction(context, user);
                    },
                  ),
                  if (index != followingUsers.length - 1)
                    SizedBox(height: 20.h),
                ],
              );
            },
            childCount: followingUsers.length,
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

class _FixedSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedSliverHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _FixedSliverHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
