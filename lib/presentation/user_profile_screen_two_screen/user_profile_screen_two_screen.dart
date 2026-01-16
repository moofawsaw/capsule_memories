// lib/presentation/user_profile_screen_two/user_profile_screen_two.dart

import '../../core/app_export.dart';
import '../../services/avatar_state_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_profile_header.dart';
import '../../widgets/custom_stat_card.dart';
import '../../widgets/custom_story_card.dart';
import '../../widgets/custom_story_skeleton.dart';
import 'notifier/user_profile_screen_two_notifier.dart';
import '../../core/models/feed_story_context.dart';

class UserProfileScreenTwo extends ConsumerStatefulWidget {
  /// Optional: target user (deep link / profile tap)
  final String? userId;

  const UserProfileScreenTwo({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  ConsumerState<UserProfileScreenTwo> createState() =>
      _UserProfileScreenTwoState();
}

class _UserProfileScreenTwoState
    extends ConsumerState<UserProfileScreenTwo> {
  String? _userId;
  bool _initialized = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initialized = true;

      // Priority 1: constructor (deep link)
      String? resolvedUserId = widget.userId;

      // Priority 2: route args
      if (resolvedUserId == null) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          resolvedUserId = args['userId'] as String?;
        } else if (args is String) {
          resolvedUserId = args;
        }
      }

      _userId = resolvedUserId;

      // IMPORTANT:
      // Call initialize WITHOUT named params to avoid signature mismatch
      ref.read(userProfileScreenTwoNotifier.notifier).initialize();


      // Load avatar only for current user
      if (_userId == null) {
        ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(userProfileScreenTwoNotifier.notifier).initialize();


    if (_userId == null) {
      await ref.read(avatarStateProvider.notifier).refreshAvatar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(userProfileScreenTwoNotifier);

            if (state.isLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: appTheme.color3BD81E,
                ),
              );
            }

            return RefreshIndicator(
              color: appTheme.deep_purple_A100,
              backgroundColor: appTheme.gray_900_02,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: 24.h,
                  left: 18.h,
                  right: 18.h,
                ),
                child: Column(
                  children: [
                    _buildProfileHeader(context),
                    SizedBox(height: 12.h),
                    _buildStatsSection(context),
                    if (_userId != null) ...[
                      SizedBox(height: 16.h),
                      _buildActionButtons(context),
                    ],
                    SizedBox(height: 28.h),
                    _buildStoriesGrid(context),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================
  // HEADER
  // ===========================

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final model = state.userProfileScreenTwoModel;
        final isCurrentUser = _userId == null;

        final avatarState = ref.watch(avatarStateProvider);

        return Stack(
          children: [
            GestureDetector(
              onTap: isCurrentUser
                  ? () => ref
                  .read(userProfileScreenTwoNotifier.notifier)
                  .uploadAvatar()
                  : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomProfileHeader(
                    avatarImagePath:
                    (isCurrentUser ? avatarState.avatarUrl : null) ??
                        model?.avatarImagePath ??
                        ImageConstant.imgEllipse896x96,
                    userName: model?.userName ?? 'Loading...',
                    email: isCurrentUser ? (model?.email ?? '') : '',
                    onEditTap:
                    isCurrentUser ? () => onTapEditProfile(context) : null,
                    allowUsernameEdit: isCurrentUser,
                    onUserNameChanged: isCurrentUser
                        ? (name) => ref
                        .read(userProfileScreenTwoNotifier.notifier)
                        .updateUsername(name)
                        : null,
                    margin: EdgeInsets.symmetric(horizontal: 68.h),
                  ),
                  if (state.isUploading && isCurrentUser)
                    Container(
                      width: 96.h,
                      height: 96.h,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================
  // STATS
  // ===========================

  Widget _buildStatsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final model =
            ref.watch(userProfileScreenTwoNotifier).userProfileScreenTwoModel;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomStatCard(
              count: model?.followersCount ?? '0',
              label: 'followers',
            ),
            SizedBox(width: 12.h),
            CustomStatCard(
              count: model?.followingCount ?? '0',
              label: 'following',
            ),
          ],
        );
      },
    );
  }

  // ===========================
  // ACTIONS
  // ===========================

  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final notifier = ref.read(userProfileScreenTwoNotifier.notifier);

        return Row(
          children: [
            Expanded(
              child: CustomButton(
                text: state.isFollowing ? 'Unfollow' : 'Follow',
                onPressed: notifier.toggleFollow,
              ),
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: CustomButton(
                text: state.isFriend
                    ? 'Unfriend'
                    : state.hasPendingFriendRequest
                    ? 'Pending'
                    : 'Add Friend',
                onPressed: state.hasPendingFriendRequest
                    ? null
                    : () {
                  state.isFriend
                      ? _showUnfriendConfirmationDialog(
                      context, notifier.unfriendUser)
                      : notifier.sendFriendRequest();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================
  // STORIES
  // ===========================

  Widget _buildStoriesGrid(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(userProfileScreenTwoNotifier);
        final stories = state.userProfileScreenTwoModel?.storyItems ?? [];

        if (state.isLoadingStories) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: 3,
            itemBuilder: (_, __) => CustomStorySkeleton(),
          );
        }

        if (stories.isEmpty) {
          return _buildEmptyStoriesState(context);
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemCount: stories.length,
          itemBuilder: (_, index) {
            final story = stories[index];
            return CustomStoryCard(
              userName: story.userName ?? 'User',
              userAvatar:
              story.userAvatar ?? ImageConstant.imgEllipse896x96,
              backgroundImage:
              story.backgroundImage ?? ImageConstant.imgImg,
              categoryText: story.categoryText ?? 'Memory',
              categoryIcon:
              story.categoryIcon ?? ImageConstant.imgVector,
              timestamp: story.timestamp ?? 'Just now',
              onTap: () => onTapStoryCard(context, index),
            );
          },
        );
      },
    );
  }

  // ===========================
  // HELPERS
  // ===========================

  Widget _buildEmptyStoriesState(BuildContext context) {
    return Text(
      _userId == null
          ? 'Share your first memory to get started'
          : 'This user hasn’t shared any public stories yet',
      style: TextStyle(color: appTheme.blue_gray_300),
      textAlign: TextAlign.center,
    );
  }

  void onTapEditProfile(BuildContext context) {}

  void onTapStoryCard(BuildContext context, int index) {
    final stories = ref
        .read(userProfileScreenTwoNotifier)
        .userProfileScreenTwoModel
        ?.storyItems ??
        [];

    if (stories.isEmpty) return;

    final ids =
    stories.map((s) => s.storyId).whereType<String>().toList();

    final initialId = stories[index].storyId;
    if (initialId == null) return;

    NavigatorService.pushNamed(
      AppRoutes.appStoryView,
      arguments: FeedStoryContext(
        feedType: 'user_profile',
        storyIds: ids,
        initialStoryId: initialId,
      ),
    );
  }

  void _showUnfriendConfirmationDialog(
      BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unfriend User?'),
        content: const Text(
            'This will remove your friendship connection.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Unfriend')),
        ],
      ),
    );
  }
}
