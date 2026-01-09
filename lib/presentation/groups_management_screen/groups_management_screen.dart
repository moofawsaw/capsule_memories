// lib/presentation/groups_management_screen/groups_management_screen.dart
import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_confirmation_dialog.dart';
import '../../widgets/custom_group_card.dart';
import '../../widgets/custom_group_invitation_card.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_image_view.dart';
import '../create_group_screen/create_group_screen.dart';
import '../friends_management_screen/widgets/qr_scanner_overlay.dart';
import '../group_edit_bottom_sheet/group_edit_bottom_sheet.dart';
import '../group_qr_invite_screen/group_qr_invite_screen.dart';
import './models/groups_management_model.dart';
import 'notifier/groups_management_notifier.dart';

class GroupsManagementScreen extends ConsumerStatefulWidget {
  const GroupsManagementScreen({Key? key}) : super(key: key);

  @override
  GroupsManagementScreenState createState() => GroupsManagementScreenState();
}

class GroupsManagementScreenState extends ConsumerState<GroupsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsManagementNotifier.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          child: Column(
            children: [
              SizedBox(height: 24.h),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Column(
                    children: [
                      _buildGroupsHeaderSection(context),
                      SizedBox(height: 16.h),

                      // Scrollable content (no RefreshIndicator)
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              SizedBox(height: 12.h),

                              // Invites (if any)
                              _buildInvitesSection(context),
                              _buildGroupInvitationList(context),

                              // Groups
                              SizedBox(height: 16.h),
                              _buildGroupsList(context),

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

  /// Header row (matches Friends layout style)
  Widget _buildGroupsHeaderSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupsManagementNotifier);
        final groupCount = state.groups?.length ?? 0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26.h,
              height: 26.h,
              margin: EdgeInsets.only(top: 2.h),
              child: CustomImageView(
                imagePath: ImageConstant.imgIcon7,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 6.h),
            Container(
              margin: EdgeInsets.only(top: 2.h),
              child: Text(
                'Groups ($groupCount)',
                style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans,
              ),
            ),
            Spacer(),

            // Right side actions (QR scan + new group)
            CustomIconButtonRow(
              firstIconPath: ImageConstant.imgButtons,
              secondIcon: Icons.camera_alt,
              secondIconSize: 24.h,
              onFirstIconTap: () => onTapNewGroup(context),
              onSecondIconTap: () => onTapCameraButton(context),
            ),
          ],
        );
      },
    );
  }

  /// Invites title
  Widget _buildInvitesSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupsManagementNotifier);
        final inviteCount = state.invitations?.length ?? 0;

        if (inviteCount == 0) return const SizedBox.shrink();

        return Container(
          width: double.maxFinite,
          margin: EdgeInsets.only(top: 10.h),
          alignment: Alignment.centerLeft,
          child: Text(
            'Invites ($inviteCount)',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50, height: 1.31),
          ),
        );
      },
    );
  }

  /// Invites list
  Widget _buildGroupInvitationList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupsManagementNotifier);
        final invites = state.invitations ?? <GroupInvitationModel>[];

        if (invites.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.maxFinite,
          margin: EdgeInsets.only(top: 10.h),
          child: Column(
            children: invites.map((invitation) {
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

  /// Groups list (non-scrollable Column inside main scroll)
  Widget _buildGroupsList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupsManagementNotifier);
        final groups = state.groups ?? <GroupModel>[];
        final currentUserId = SupabaseService.instance.client?.auth.currentUser?.id;

        if (state.isLoading == true) {
          return Padding(
            padding: EdgeInsets.only(top: 30.h),
            child: Center(
              child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
            ),
          );
        }

        if (groups.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: Center(
              child: Text(
                'No groups yet. Create your first group!',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: groups.map((group) {
            final isCreator = (group.creatorId != null &&
                currentUserId != null &&
                group.creatorId == currentUserId);

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
                onActionTap: () => onTapGroupQR(context, group),
                onDeleteTap: () => onTapDeleteGroup(context, group),
                onEditTap: isCreator ? () => onTapEditGroup(context, group) : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Create group bottom sheet
  void onTapNewGroup(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => CreateGroupScreen(),
    );

    ref.read(groupsManagementNotifier.notifier).refresh();
  }

  /// Open group QR invite sheet
  void onTapGroupQR(BuildContext context, GroupModel group) {
    final groupId = group.id;
    if (groupId == null || groupId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => GroupQRInviteScreen(),
      routeSettings: RouteSettings(arguments: groupId),
    );
  }

  /// Edit group bottom sheet
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

  /// Delete group confirmation + delete
  void onTapDeleteGroup(BuildContext context, GroupModel group) async {
    final groupName = group.name ?? 'this group';

    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Delete Group?',
      message: 'Are you sure you want to delete "$groupName"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      // If your notifier expects name, keep name. If it expects id, swap to id.
      ref.read(groupsManagementNotifier.notifier).deleteGroup(groupName);
    }
  }

  /// Accept invitation
  void onTapAcceptInvitation(BuildContext context) {
    ref.read(groupsManagementNotifier.notifier).acceptInvitation();
  }

  /// Decline invitation
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

  /// QR scanner overlay
  void onTapCameraButton(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => QRScannerOverlay(
          scanType: 'group',
          onSuccess: () {
            ref.read(groupsManagementNotifier.notifier).refresh();
          },
        ),
      ),
    );
  }
}
