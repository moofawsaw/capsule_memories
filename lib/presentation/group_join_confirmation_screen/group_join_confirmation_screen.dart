import '../../core/app_export.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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
    final topInset = MediaQuery.of(context).padding.top;
    // Add extra breathing room above the modal header (especially on notched devices).
    final headerTop = topInset + 22.h;

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      // Modal-style overlay: full-screen content + close (X) in top-right.
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.h, headerTop + 62.h, 20.h, 16.h),
              child: _buildContent(context),
            ),
          ),
          Positioned(
            top: headerTop,
            left: 26.h,
            right: 26.h,
            child: Row(
              children: [
                SizedBox(width: 40.h, height: 40.h),
                Expanded(
                  child: Center(
                    child: Text(
                      'Group Invitation',
                      style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40.h,
                  height: 40.h,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20.h),
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).maybePop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: appTheme.gray_900_01.withAlpha(200),
                          borderRadius: BorderRadius.circular(20.h),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: appTheme.gray_50,
                          size: 20.h,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final createdAt = state.createdAt;
    final members = state.members ?? const <GroupMemberPreview>[];
    final creatorId = (state.creatorId ?? '').trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: appTheme.deep_purple_A100.withAlpha(51),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                child: Icon(
                  Icons.group,
                  color: appTheme.deep_purple_A100,
                  size: 28.h,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.people,
                            color: appTheme.blue_gray_300, size: 16.h),
                        SizedBox(width: 6.h),
                        Text(
                          '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                          style: TextStyleHelper
                              .instance.body14RegularPlusJakartaSans
                              .copyWith(color: appTheme.blue_gray_300),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Creator + Created date (tight, info-dense)
          Row(
            children: [
              _buildAvatar(24.h, state.creatorAvatar),
              SizedBox(width: 8.h),
              Expanded(
                child: Text(
                  'Created by $creatorName',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  color: appTheme.blue_gray_300, size: 16.h),
              SizedBox(width: 8.h),
              Text(
                'Created ${_formatCreatedDate(createdAt)}',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),

          SizedBox(height: 16.h),
          Divider(color: appTheme.blue_gray_900_02.withAlpha(120), height: 1),
          SizedBox(height: 14.h),

          Text(
            'Members',
            style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          SizedBox(height: 10.h),

          // Vertical list of members (inside the card, scrolls with page)
          if (members.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, __) =>
                  Divider(color: appTheme.blue_gray_900_02.withAlpha(90), height: 14.h),
              itemBuilder: (context, index) {
                final m = members[index];
                final isCreator = creatorId.isNotEmpty && m.userId == creatorId;
                return _buildMemberRow(m, isCreator: isCreator);
              },
            )
          else ...[
            // Fallback: keep old preview row if member list isn't available.
            _buildMembersAvatarsRow(avatars, memberCount),
          ],
        ],
      ),
    );
  }

  String _formatCreatedDate(DateTime? dt) {
    if (dt == null) return '—';
    try {
      return DateFormat.yMMMd().format(dt.toLocal());
    } catch (_) {
      return '—';
    }
  }

  Widget _buildMemberRow(GroupMemberPreview member, {required bool isCreator}) {
    return Row(
      children: [
        _buildAvatar(36.h, member.avatarUrl),
        SizedBox(width: 12.h),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      member.displayName,
                      style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCreator) ...[
                    SizedBox(width: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: appTheme.deep_purple_A100.withAlpha(38),
                        borderRadius: BorderRadius.circular(999.h),
                      ),
                      child: Text(
                        'Creator',
                        style: TextStyleHelper
                            .instance.body12RegularPlusJakartaSans
                            .copyWith(color: appTheme.deep_purple_A100),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(double size, String? raw) {
    final url = StorageUtils.resolveAvatarUrl(raw) ?? (raw ?? '').trim();
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: appTheme.blue_gray_900_02,
        ),
        child: Icon(
          Icons.person,
          color: appTheme.gray_50,
          size: (size * 0.58),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(color: appTheme.blue_gray_900_02, width: size, height: size),
        errorWidget: (_, __, ___) => Container(
          width: size,
          height: size,
          color: appTheme.blue_gray_900_02,
          child: Icon(Icons.person, color: appTheme.gray_50, size: (size * 0.58)),
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
