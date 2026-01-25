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
import '../../core/utils/story_actions_sheet.dart';
import '../../services/supabase_service.dart';

// ✅ NEW: skeleton
import './widgets/user_profile_skeleton.dart';

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

class _UserProfileScreenTwoState extends ConsumerState<UserProfileScreenTwo> {
  String? _userId;
  final ScrollController _scrollController = ScrollController();

  // ✅ NEW: hard gate to prevent any “static flash” before we even trigger init
  bool _initTriggered = false;

  // ✅ NEW: best-effort for initial skeleton layout (actions visible when viewing other user)
  bool _initialViewingOtherUser = false;

  String? get _currentUserId =>
      SupabaseService.instance.client?.auth.currentUser?.id;

  /// If the target is the current user, return null so we always show "current user" variant.
  String? _normalizeUserId(String? candidate) {
    final c = candidate?.trim();
    if (c == null || c.isEmpty) return null;

    final me = _currentUserId;
    if (me != null && c == me) return null;

    return c;
  }

  @override
  void initState() {
    super.initState();

    // If the constructor provides a userId, we already know this is "other user"
    // (but normalize in case it points to the current user).
    _initialViewingOtherUser = _normalizeUserId(widget.userId) != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Priority 1: constructor
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

      // ✅ HARD RULE: never allow current user to be treated as "other user"
      _userId = _normalizeUserId(resolvedUserId);

      // ✅ flip gate BEFORE/AS we start loading
      if (mounted) {
        setState(() {
          _initTriggered = true;
          _initialViewingOtherUser = _userId != null;
        });
      }

      // ✅ Kick init (notifier should set isLoading true internally)
      ref.read(userProfileScreenTwoNotifier.notifier).initialize(userId: _userId);

      // Avatar only for current user
      if (_userId == null) {
        ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
      }
    });
  }

  @override
  void didUpdateWidget(covariant UserProfileScreenTwo oldWidget) {
    super.didUpdateWidget(oldWidget);

    final normalizedNew = _normalizeUserId(widget.userId);
    final normalizedOld = _normalizeUserId(oldWidget.userId);

    if (normalizedNew == normalizedOld) return;

    _userId = normalizedNew;

    // keep skeleton rules consistent
    _initTriggered = true;
    _initialViewingOtherUser = _userId != null;

    // re-init for new target
    ref.read(userProfileScreenTwoNotifier.notifier).initialize(userId: _userId);

    if (_userId == null) {
      ref.read(avatarStateProvider.notifier).loadCurrentUserAvatar();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref
        .read(userProfileScreenTwoNotifier.notifier)
        .initialize(userId: _userId);

    if (_userId == null) {
      await ref.read(avatarStateProvider.notifier).refreshAvatar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileScreenTwoNotifier);

    // ✅ HARD NO-FLASH RULE:
    // - Before we even trigger init (first frame), ALWAYS show skeleton.
    // - After init is triggered, keep skeleton until we have a model and not loading.
    final bool hasModel = state.userProfileScreenTwoModel != null;
    final bool isViewingOtherUser =
    _initTriggered ? (_userId != null) : _initialViewingOtherUser;

    final bool showSkeleton = !_initTriggered || state.isLoading || !hasModel;

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: showSkeleton
            ? UserProfileSkeleton(showActions: isViewingOtherUser)
            : RefreshIndicator(
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
                _buildStats(context),
                if (_userId != null) ...[
                  SizedBox(height: 16.h),
                  _buildActions(context),
                ],
                SizedBox(height: 28.h),
                _buildStories(context),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final state = ref.watch(userProfileScreenTwoNotifier);
    final model = state.userProfileScreenTwoModel;
    final isCurrentUser = _userId == null;
    final avatarState = ref.watch(avatarStateProvider);

    final displayName = (model?.displayName ?? '').trim();
    final usernameRaw = (model?.username ?? '').trim();

    return Stack(
      children: [
        GestureDetector(
          onTap: isCurrentUser
              ? () => ref
              .read(userProfileScreenTwoNotifier.notifier)
              .uploadAvatar()
              : null,
          child: CustomProfileHeader(
            avatarImagePath: (isCurrentUser ? avatarState.avatarUrl : null) ??
                model?.avatarImagePath ??
                '',
            displayName: displayName.isNotEmpty ? displayName : 'User',
            username: usernameRaw,
            email: isCurrentUser ? (model?.email ?? '') : '',
            allowEdit: isCurrentUser,
            onEditTap: isCurrentUser
                ? () => ref
                .read(userProfileScreenTwoNotifier.notifier)
                .uploadAvatar()
                : null,
            onDisplayNameChanged: isCurrentUser
                ? (newDisplayName) => ref
                .read(userProfileScreenTwoNotifier.notifier)
                .updateDisplayName(newDisplayName)
                : null,
            onUsernameChanged: isCurrentUser
                ? (newUsername) => ref
                .read(userProfileScreenTwoNotifier.notifier)
                .updateUsername(newUsername)
                : null,

            // 🔴 🔴 🔴 THIS IS #3 🔴 🔴 🔴
            isSavingDisplayName: state.isSavingDisplayName,
            isSavingUsername: state.isSavingUsername,
            displayNameSavedPulse: state.displayNameSavedPulse,
            usernameSavedPulse: state.usernameSavedPulse,
            displayNameError: state.displayNameError,
            usernameError: state.usernameError,

            margin: EdgeInsets.symmetric(horizontal: 68.h),
          ),
        ),
        if (!isCurrentUser)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                final notifier =
                ref.read(userProfileScreenTwoNotifier.notifier);
                _showBlockConfirmationDialog(context, state.isBlocked, () {
                  notifier.toggleBlock();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: state.isBlocked
                      ? appTheme.gray_900_01
                      : appTheme.red_500.withAlpha(26),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: state.isBlocked
                        ? appTheme.blue_gray_300
                        : appTheme.red_500,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  state.isBlocked ? Icons.lock_open : Icons.block,
                  color:
                  state.isBlocked ? appTheme.blue_gray_300 : appTheme.red_500,
                  size: 20.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStats(BuildContext context) {
    final model = ref.watch(userProfileScreenTwoNotifier).userProfileScreenTwoModel;
    final isCurrentUser = _userId == null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isCurrentUser
              ? () => NavigatorService.pushNamed(AppRoutes.appFollowers)
              : null,
          child: CustomStatCard(
            count: model?.followersCount ?? '0',
            label: 'followers',
          ),
        ),
        SizedBox(width: 12.h),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isCurrentUser
              ? () => NavigatorService.pushNamed(AppRoutes.appFollowing)
              : null,
          child: CustomStatCard(
            count: model?.followingCount ?? '0',
            label: 'following',
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final state = ref.watch(userProfileScreenTwoNotifier);
    final notifier = ref.read(userProfileScreenTwoNotifier.notifier);

    final unsetStyle = CustomButtonStyle(
      backgroundColor: appTheme.deep_purple_A100, // primary / default
      variant: CustomButtonVariant.fill,
    );

    final setStyle = CustomButtonStyle(
      backgroundColor: appTheme.blue_gray_900, // "set" state
      variant: CustomButtonVariant.fill,
    );

    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: state.isFollowing ? 'Unfollow' : 'Follow',
            leftIcon: state.isFollowing ? Icons.person_remove : Icons.person_add,
            buttonStyle: state.isFollowing ? setStyle : unsetStyle,
            onPressed: notifier.toggleFollow,
          ),
        ),
        SizedBox(width: 8.h),
        Expanded(
          child: CustomButton(
            text: state.isFriend ? 'Unfriend' : 'Add Friend',
            leftIcon: state.isFriend ? Icons.person_remove : Icons.group_add,
            buttonStyle: state.isFriend ? setStyle : unsetStyle,
            onPressed:
            state.isFriend ? notifier.unfriendUser : notifier.sendFriendRequest,
          ),
        ),
      ],
    );
  }

  Widget _buildStories(BuildContext context) {
    final state = ref.watch(userProfileScreenTwoNotifier);
    final stories = state.userProfileScreenTwoModel?.storyItems ?? [];

    const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 1,
      mainAxisSpacing: 1,
      childAspectRatio: 0.65,
    );

    if (state.isLoadingStories) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: gridDelegate,
        itemCount: 3,
        itemBuilder: (_, __) => const CustomStorySkeleton(),
      );
    }

    if (stories.isEmpty) {
      return _buildEmptyStoriesState(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: gridDelegate,
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        final me = _currentUserId;
        final isMyStory =
            me != null && me.isNotEmpty && (story.contributorId ?? '') == me;
        final rawName = (story.userName ?? '').trim();

        return CustomStoryCard(
          borderRadius: BorderRadius.circular(0.h),
          // Hide name for the current user's own stories (even if this screen is
          // reached via a route arg that temporarily sets _userId).
          userName: isMyStory ? '' : (rawName.isNotEmpty ? rawName : 'User'),
          userAvatar: story.userAvatar ?? '',
          backgroundImage: story.backgroundImage ?? '',
          categoryText: story.categoryText ?? 'Memory',
          categoryIcon: story.categoryIcon ?? '',
          timestamp: story.timestamp ?? 'Just now',
          onTap: () => _onTapStoryCard(context, index),

          // ✅ Long-press actions (SAFE, MATCHES MODEL)
          onLongPress: () {
            final String? storyId = story.storyId;
            if (storyId == null || storyId.isEmpty) return;

            StoryActionsSheet.show(
              context: context,

              // REQUIRED
              storyId: storyId,

              // Profile grid does not expose memoryId yet → pass empty
              memoryId: '',

              // Owner check: contributorId === owner for profile stories
              ownerUserId: story.contributorId ?? '',

              // Best available share target for now
              mediaUrl: story.backgroundImage ?? '',

              // Not available on this model (safe defaults)
              caption: '',
              isVideo: false,
              deepLink: null,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyStoriesState(BuildContext context) {
    return Text(
      _userId == null
          ? 'Share your first memory to get started'
          : 'This user hasn’t shared any public stories yet',
      style: TextStyle(color: appTheme.blue_gray_300),
      textAlign: TextAlign.center,
    );
  }

  void _onTapStoryCard(BuildContext context, int index) {
    final stories = ref
        .read(userProfileScreenTwoNotifier)
        .userProfileScreenTwoModel
        ?.storyItems ??
        [];

    if (stories.isEmpty || index < 0 || index >= stories.length) return;

    final ids = stories.map((s) => s.storyId).whereType<String>().toList();
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

  void _showBlockConfirmationDialog(
      BuildContext context,
      bool isBlocked,
      VoidCallback onConfirm,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: appTheme.gray_900_02,
        title: Text(
          isBlocked ? 'Unblock User?' : 'Block User?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isBlocked
              ? 'This user will be able to see your content and interact with you again.'
              : 'This user will no longer be able to see your content or interact with you. All existing relationships (friends, follows) will be removed.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[300])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              isBlocked ? 'Unblock' : 'Block',
              style: TextStyle(color: appTheme.deep_purple_A100),
            ),
          ),
        ],
      ),
    );
  }
}
