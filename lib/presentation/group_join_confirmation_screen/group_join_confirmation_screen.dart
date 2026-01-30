import '../../core/app_export.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/custom_button.dart';
import './notifier/group_join_confirmation_notifier.dart';
import '../../utils/storage_utils.dart';

class GroupJoinConfirmationScreen extends ConsumerStatefulWidget {
  const GroupJoinConfirmationScreen({Key? key}) : super(key: key);

  @override
  GroupJoinConfirmationScreenState createState() =>
      GroupJoinConfirmationScreenState();
}

class GroupJoinConfirmationScreenState
    extends ConsumerState<GroupJoinConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupDetails();
    });
  }

  Future<void> _loadGroupDetails() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final inviteCode = (args?['inviteCode'] as String?)?.trim() ??
        (args?['invite_code'] as String?)?.trim() ??
        (args?['code'] as String?)?.trim();

    if (inviteCode == null || inviteCode.isEmpty) {
      print('❌ GROUP JOIN: No inviteCode provided in arguments');
      _showError('Group invitation not found');
      return;
    }

    print('✅ GROUP JOIN: Loading group details for inviteCode: $inviteCode');

    await ref
        .read(groupJoinConfirmationNotifier.notifier)
        .loadGroupDetailsByInviteCode(inviteCode);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      // Navigate back to memories after error
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          NavigatorService.pushNamed(AppRoutes.appGroups);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      appBar: AppBar(
        backgroundColor: appTheme.gray_900_02,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: appTheme.gray_50,
            size: 18.h,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Group Invitation',
          style: TextStyleHelper.instance.title16BoldPlusJakartaSans.copyWith(
            color: appTheme.gray_50,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.h),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupJoinConfirmationNotifier);

        // Show loading state
        if (state.isLoading ?? false) {
          return Container(
            padding: EdgeInsets.all(40.h),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: appTheme.deep_purple_A100),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading group details...',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
          );
        }

        // Show error state
        if (state.errorMessage != null) {
          return Container(
            padding: EdgeInsets.all(40.h),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48.h),
                  SizedBox(height: 16.h),
                  Text(
                    state.errorMessage!,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    text: 'Go to Memories',
                    buttonStyle: CustomButtonStyle.fillPrimary,
                    buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                    onPressed: () {
                      NavigatorService.pushNamed(AppRoutes.appMemories);
                    },
                  ),
                ],
              ),
            ),
          );
        }

        // Show memory details and actions
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupDetails(context, state),
            SizedBox(height: 24.h),
            _buildActionButtons(context, state),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// Section Widget - Group Details Card
  Widget _buildGroupDetails(
      BuildContext context, GroupJoinConfirmationState state) {
    final groupName = state.groupName ?? 'Unknown Group';
    final creatorName = state.creatorName ?? 'Unknown User';
    final memberCount = state.memberCount ?? 1;
    final avatars = state.memberAvatars ?? const <String>[];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(
          color: appTheme.blue_gray_300.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory Icon
          Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: appTheme.deep_purple_A100.withAlpha(51),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Icon(
              Icons.group,
              color: appTheme.deep_purple_A100,
              size: 32.h,
            ),
          ),
          SizedBox(height: 16.h),

          // Group Name
          Text(
            groupName,
            style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          SizedBox(height: 8.h),

          // Creator Info
          Row(
            children: [
              _buildAvatar24(state.creatorAvatar),
              SizedBox(width: 8.h),
              Text(
                'Created by $creatorName',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          _buildMembersAvatarsRow(avatars, memberCount),
          SizedBox(height: 16.h),

          // Member Count
          Row(
            children: [
              Icon(Icons.people, color: appTheme.blue_gray_300, size: 18.h),
              SizedBox(width: 8.h),
              Text(
                '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar24(String? raw) {
    final url = StorageUtils.resolveAvatarUrl(raw) ?? (raw ?? '').trim();
    if (url.isEmpty) {
      return Container(
        width: 24.h,
        height: 24.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: appTheme.blue_gray_900_02,
        ),
        child: Icon(Icons.person, color: appTheme.gray_50, size: 14.h),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 24.h,
        height: 24.h,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(color: appTheme.blue_gray_900_02, width: 24.h, height: 24.h),
        errorWidget: (_, __, ___) => Container(
          width: 24.h,
          height: 24.h,
          color: appTheme.blue_gray_900_02,
          child: Icon(Icons.person, color: appTheme.gray_50, size: 14.h),
        ),
      ),
    );
  }

  Widget _buildMembersAvatarsRow(List<String> avatars, int membersCount) {
    final visible = avatars.take(8).toList();
    final remaining = (membersCount - visible.length).clamp(0, 9999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visible.isNotEmpty)
          SizedBox(
            height: 36.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(visible.length, (i) {
                final left = i * 18.h;
                final url = visible[i];
                return Positioned(
                  left: left,
                  child: Container(
                    width: 36.h,
                    height: 36.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: appTheme.gray_900_01,
                        width: 2.h,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: appTheme.blue_gray_900_02),
                        errorWidget: (_, __, ___) => Container(
                          color: appTheme.blue_gray_900_02,
                          child: Icon(Icons.person, color: appTheme.gray_50, size: 18.h),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        SizedBox(height: 10.h),
        Text(
          remaining > 0
              ? '$membersCount members • +$remaining more'
              : '$membersCount members',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300),
        ),
      ],
    );
  }

  /// Section Widget - Action Buttons
  Widget _buildActionButtons(
      BuildContext context, GroupJoinConfirmationState state) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(groupJoinConfirmationNotifier, (previous, current) {
          // Navigate to groups on accept/decline
          if (current.shouldNavigateToGroups ?? false) {
            final groupId = current.groupId;
            print('✅ Navigating to groups');
            NavigatorService.pushNamed(
              AppRoutes.appGroups,
              arguments: groupId != null ? {'groupId': groupId} : null,
            );
          }
        });

        return Row(
          spacing: 12.h,
          children: [
            Expanded(
              child: CustomButton(
                text: 'Decline',
                buttonStyle: CustomButtonStyle.outlineDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                onPressed: () => onTapDecline(context),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Join Group',
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                onPressed: (state.isAccepting ?? false)
                    ? null
                    : () => onTapAccept(context),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handle Accept button tap
  Future<void> onTapAccept(BuildContext context) async {
    print('🔵 Accept button pressed');
    await ref.read(groupJoinConfirmationNotifier.notifier).acceptInvitation();
  }

  /// Handle Decline button tap
  void onTapDecline(BuildContext context) {
    print('🔴 Decline button pressed');
    ref.read(groupJoinConfirmationNotifier.notifier).declineInvitation();
  }
}
