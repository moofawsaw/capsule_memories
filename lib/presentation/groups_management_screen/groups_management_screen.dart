import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_group_card.dart';
import '../../widgets/custom_group_invitation_card.dart';
import '../../widgets/custom_image_view.dart';
import '../create_group_screen/create_group_screen.dart';
import '../group_qr_invite_screen/group_qr_invite_screen.dart';
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
        appBar: CustomAppBar(
          logoImagePath: ImageConstant.imgLogo,
          showIconButton: true,
          iconButtonImagePath: ImageConstant.imgFrame19,
          iconButtonBackgroundColor: appTheme.color3BD81E,
          actionIcons: [
            ImageConstant.imgIconGray50,
            ImageConstant.imgIconGray5032x32,
          ],
          showProfileImage: true,
          profileImagePath: ImageConstant.imgEllipse8,
          isProfileCircular: true,
        ),
        body: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildGroupsSection(context),
                    _buildGroupsList(context),
                    _buildInvitesSection(context),
                    _buildGroupInvitation(context),
                  ],
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
              'Groups (3)',
              style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans
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
  }

  /// Section Widget - Groups list
  Widget _buildGroupsList(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.h, 20.h, 12.h, 0),
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(groupsManagementNotifier);

          return Column(
            spacing: 6.h,
            children: [
              CustomGroupCard(
                groupData: CustomGroupData(
                  title: 'Family',
                  memberCountText: '2 members',
                  memberImages: [
                    ImageConstant.imgEllipse81,
                    ImageConstant.imgEllipse842x42,
                  ],
                ),
                onActionTap: () => onTapGroupQR(context, 'Family'),
                onDeleteTap: () => onTapDeleteGroup(context, 'Family'),
              ),
              CustomGroupCard(
                groupData: CustomGroupData(
                  title: 'Work',
                  memberCountText: '1 member',
                  memberImages: [
                    ImageConstant.imgEllipse81,
                  ],
                ),
                onActionTap: () => onTapGroupQR(context, 'Work'),
                onDeleteTap: () => onTapDeleteGroup(context, 'Work'),
              ),
              CustomGroupCard(
                groupData: CustomGroupData(
                  title: 'Friends',
                  memberCountText: '3 members',
                  memberImages: [
                    ImageConstant.imgEllipse81,
                    ImageConstant.imgEllipse842x42,
                    ImageConstant.imgFrame1,
                  ],
                ),
                onActionTap: () => onTapGroupQR(context, 'Friends'),
                onDeleteTap: () => onTapDeleteGroup(context, 'Friends'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Section Widget - Invites section
  Widget _buildInvitesSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 18.h),
      child: Text(
        'Invites (1)',
        style: TextStyleHelper.instance.title16BoldPlusJakartaSans
            .copyWith(color: appTheme.gray_50, height: 1.31),
      ),
    );
  }

  /// Section Widget - Group invitation card
  Widget _buildGroupInvitation(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.h, 10.h, 12.h, 0),
      child: CustomGroupInvitationCard(
        groupName: 'Gang',
        memberCount: 3,
        memberAvatarImagePath: ImageConstant.imgFrame403,
        onAcceptTap: () => onTapAcceptInvitation(context),
        onActionTap: () => onTapDeclineInvitation(context),
      ),
    );
  }

  /// Navigates to the notifications screen
  void onTapNotificationIcon(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }

  /// Navigates to create group screen
  void onTapNewGroup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => CreateGroupScreen(),
    );
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

  /// Handles group deletion
  void onTapDeleteGroup(BuildContext context, String groupName) {
    ref.read(groupsManagementNotifier.notifier).deleteGroup(groupName);
  }

  /// Handles accepting group invitation
  void onTapAcceptInvitation(BuildContext context) {
    ref.read(groupsManagementNotifier.notifier).acceptInvitation();
  }

  /// Handles declining group invitation
  void onTapDeclineInvitation(BuildContext context) {
    ref.read(groupsManagementNotifier.notifier).declineInvitation();
  }
}
