import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/custom_group_card.dart';
import '../../widgets/custom_group_invitation_card.dart';
import '../../widgets/custom_image_view.dart';
import '../create_group_screen/create_group_screen.dart';
import '../group_edit_bottom_sheet/group_edit_bottom_sheet.dart';
import '../group_qr_invite_screen/group_qr_invite_screen.dart';
import './models/groups_management_model.dart';
import 'notifier/groups_management_notifier.dart';

class GroupsManagementScreen extends ConsumerStatefulWidget {
  GroupsManagementScreen({Key? key}) : super(key: key);

  @override
  GroupsManagementScreenState createState() => GroupsManagementScreenState();
}

class GroupsManagementScreenState
    extends ConsumerState<GroupsManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(groupsManagementNotifier.notifier).refresh();
                  },
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildGroupsSection(context),
                        _buildGroupsList(context),
                        _buildInvitesSection(context),
                        _buildGroupInvitation(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget - Groups section header
  Widget _buildGroupsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupsManagementNotifier);
        final groupCount = state.groups?.length ?? 0;

        return Container(
          margin: EdgeInsets.fromLTRB(16.h, 24.h, 16.h, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgIcon7,
                height: 26.h,
                width: 26.h,
              ),
              Container(
                margin: EdgeInsets.only(left: 6.h, top: 1.h),
                child: Text(
                  'Groups ($groupCount)',
                  style: TextStyleHelper
                      .instance.title20ExtraBoldPlusJakartaSans
                      .copyWith(height: 1.30),
                ),
              ),
              Spacer(),
              CustomButton(
                text: 'New Group',
                width: null,
                leftIcon: ImageConstant.imgIcon20x20,
                onPressed: () => onTapNewGroup(context),
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                padding: EdgeInsets.fromLTRB(16.h, 12.h, 16.h, 12.h),
                margin: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget - Groups list
  Widget _buildGroupsList(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.h, 20.h, 12.h, 0),
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(groupsManagementNotifier);
          final currentUserId =
              SupabaseService.instance.client?.auth.currentUser?.id;

          if (state.isLoading == true) {
            return Center(
              child:
                  CircularProgressIndicator(color: appTheme.deep_purple_A100),
            );
          }

          if (state.groups == null || state.groups!.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: Text(
                  'No groups yet. Create your first group!',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),
            );
          }

          return Column(
            children: state.groups!.map((group) {
              final isCreator = group.creatorId == currentUserId;

              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: CustomGroupCard(
                  groupData: CustomGroupData(
                    title: group.name ?? 'Unnamed Group',
                    memberCountText:
                        '${group.memberCount ?? 0} member${(group.memberCount ?? 0) == 1 ? '' : 's'}',
                    memberImages: group.memberImages?.isNotEmpty == true
                        ? group.memberImages!
                        : [ImageConstant.imgEllipse81],
                    isCreator: isCreator,
                  ),
                  onActionTap: () => onTapGroupQR(context, group.name ?? ''),
                  onDeleteTap: () =>
                      onTapDeleteGroup(context, group.name ?? ''),
                  onEditTap:
                      isCreator ? () => onTapEditGroup(context, group) : null,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  /// Section Widget - Invites section
  Widget _buildInvitesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupsManagementNotifier);
        final inviteCount = state.invitations?.length ?? 0;

        if (inviteCount == 0) return SizedBox.shrink();

        return Container(
          margin: EdgeInsets.only(top: 18.h),
          child: Text(
            'Invites ($inviteCount)',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50, height: 1.31),
          ),
        );
      },
    );
  }

  /// Section Widget - Group invitation card
  Widget _buildGroupInvitation(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupsManagementNotifier);

        if (state.invitations == null || state.invitations!.isEmpty) {
          return SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.fromLTRB(12.h, 10.h, 12.h, 0),
          child: Column(
            children: state.invitations!.map((invitation) {
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: CustomGroupInvitationCard(
                  groupName: invitation.groupName ?? 'Unknown',
                  memberCount: invitation.memberCount ?? 0,
                  memberAvatarImagePath:
                      invitation.avatarImage ?? ImageConstant.imgFrame403,
                  onAcceptTap: () => onTapAcceptInvitation(context),
                  onActionTap: () => onTapDeclineInvitation(context),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Navigates to the notifications screen
  void onTapNotificationIcon(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appNotifications);
  }

  /// Navigates to create group screen
  void onTapNewGroup(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => CreateGroupScreen(),
    );

    // Refresh groups after creating a new one
    ref.read(groupsManagementNotifier.notifier).refresh();
  }

  /// Handles group QR code action
  void onTapGroupQR(BuildContext context, String groupName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => GroupQRInviteScreen(),
    );
  }

  /// Handles group editing for creators
  void onTapEditGroup(BuildContext context, GroupModel group) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => GroupEditBottomSheet(group: group),
    );

    if (result == true) {
      ref.read(groupsManagementNotifier.notifier).refresh();
    }
  }

  /// Handles group deletion
  void onTapDeleteGroup(BuildContext context, String groupName) async {
    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Delete Group?',
      message:
          'Are you sure you want to delete "$groupName"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      ref.read(groupsManagementNotifier.notifier).deleteGroup(groupName);
    }
  }

  /// Handles accepting group invitation
  void onTapAcceptInvitation(BuildContext context) {
    ref.read(groupsManagementNotifier.notifier).acceptInvitation();
  }

  /// Handles declining group invitation
  void onTapDeclineInvitation(BuildContext context) async {
    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Decline Invitation?',
      message: 'Are you sure you want to decline this group invitation?',
      confirmText: 'Decline',
      cancelText: 'Cancel',
      icon: Icons.cancel_outlined,
    );

    if (confirmed == true) {
      ref.read(groupsManagementNotifier.notifier).declineInvitation();
    }
  }
}
