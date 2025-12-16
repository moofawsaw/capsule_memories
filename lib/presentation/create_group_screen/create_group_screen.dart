import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/custom_user_info_row.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_button.dart';
import 'notifier/create_group_notifier.dart';
import 'widgets/friend_list_item.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  CreateGroupScreen({Key? key}) : super(key: key);

  @override
  CreateGroupScreenState createState() => CreateGroupScreenState();
}

class CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: Color(0xFF5B000000),
            body: Form(
                key: _formKey,
                child: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                        child: Container(
                            width: double.maxFinite,
                            height: 848.h,
                            child:
                                Stack(alignment: Alignment.center, children: [
                              Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                      width: double.maxFinite,
                                      height: 654.h,
                                      decoration: BoxDecoration(
                                          color: appTheme.gray_900_02,
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(26.h))))),
                              Container(
                                  width: double.maxFinite,
                                  height: double.maxFinite,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 22.h, vertical: 26.h),
                                  child: Column(children: [
                                    SizedBox(height: 190.h),
                                    Container(
                                        width: 116.h,
                                        height: 12.h,
                                        decoration: BoxDecoration(
                                            color: appTheme.color3BD81E,
                                            borderRadius:
                                                BorderRadius.circular(6.h))),
                                    CustomHeaderSection(
                                        title: 'Create Group',
                                        description:
                                            'Manage your friends. See where they think the scene is.',
                                        margin: EdgeInsets.only(
                                            top: 32.h,
                                            left: 30.h,
                                            right: 30.h)),
                                    _buildGroupNameSection(context),
                                    _buildMembersSection(context),
                                    _buildSelectedMembersList(context),
                                    _buildFriendsSection(context),
                                    _buildFriendsList(context),
                                    _buildActionButtons(context),
                                  ])),
                            ])))))));
  }

  /// Section Widget
  Widget _buildGroupNameSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(createGroupNotifier);

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: EdgeInsets.only(top: 26.h),
            child: Text('Group Name',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300))),
        CustomEditText(
            controller: state.groupNameController,
            hintText: 'e.g., Family, Work Friends, Team',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Group name is required';
              }
              return null;
            }),
      ]);
    });
  }

  /// Section Widget
  Widget _buildMembersSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(createGroupNotifier);

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: Text('Members',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300))),
        CustomSearchView(
            controller: state.searchController,
            placeholder: 'Search by name...',
            margin: EdgeInsets.only(top: 12.h),
            onChanged: (value) {
              ref.read(createGroupNotifier.notifier).searchFriends(value ?? '');
            }),
      ]);
    });
  }

  /// Section Widget
  Widget _buildSelectedMembersList(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(createGroupNotifier);

      if (state.createGroupModel?.selectedMembers?.isEmpty ?? true) {
        return SizedBox();
      }

      return Column(
          children: state.createGroupModel?.selectedMembers?.map((member) {
                return CustomUserInfoRow(
                    profileImagePath: member.profileImage,
                    userName: member.name,
                    actionIconPath: ImageConstant.imgIconGray5020x20,
                    margin: EdgeInsets.only(top: 16.h),
                    onActionTap: () {
                      ref
                          .read(createGroupNotifier.notifier)
                          .removeMember(member);
                    });
              }).toList() ??
              []);
    });
  }

  /// Section Widget
  Widget _buildFriendsSection(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 20.h),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Your Friends',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300)),
          Row(children: [
            Text('scan a friend',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300)),
            CustomIconButton(
                iconPath: ImageConstant.imgButtonsGray50,
                backgroundColor: appTheme.gray_900_03,
                margin: EdgeInsets.only(left: 8.h),
                onTap: () {
                  onTapScanFriend(context);
                }),
          ]),
        ]));
  }

  /// Section Widget
  Widget _buildFriendsList(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(createGroupNotifier);
      final filteredFriends = state.createGroupModel?.filteredFriends ?? [];

      if (filteredFriends.isEmpty) {
        return SizedBox();
      }

      return Column(
          children: filteredFriends.map((friend) {
        final isSelected = state.createGroupModel?.selectedMembers
                ?.any((member) => member.id == friend.id) ??
            false;

        return FriendListItem(
            friend: friend,
            isSelected: isSelected,
            margin: EdgeInsets.only(top: 16.h),
            onTap: () {
              if (isSelected) {
                ref.read(createGroupNotifier.notifier).removeMember(friend);
              } else {
                ref.read(createGroupNotifier.notifier).addMember(friend);
              }
            });
      }).toList());
    });
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(createGroupNotifier);

      ref.listen(createGroupNotifier, (previous, current) {
        if (current.isSuccess ?? false) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Group created successfully!'),
              backgroundColor: appTheme.colorFF52D1));
          NavigatorService.pushNamed(AppRoutes.hangoutCallScreen);
        }
      });

      return Container(
          margin: EdgeInsets.only(top: 22.h),
          child: Row(spacing: 12.h, children: [
            Expanded(
                child: CustomButton(
                    text: 'Cancel',
                    buttonStyle: CustomButtonStyle.fillDark,
                    buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                    onPressed: () {
                      onTapCancel(context);
                    })),
            Expanded(
                child: CustomButton(
                    text: 'Create',
                    buttonStyle: CustomButtonStyle.fillPrimary,
                    buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                    isDisabled: state.isLoading,
                    onPressed: () {
                      onTapCreate(context);
                    })),
          ]));
    });
  }

  /// Navigates back to the previous screen
  void onTapCancel(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.hangoutCallScreen);
  }

  /// Creates the group after validation
  void onTapCreate(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(createGroupNotifier.notifier).createGroup();
    }
  }

  /// Opens QR scanner for adding friends
  void onTapScanFriend(BuildContext context) {
    // TODO: Implement QR scanner functionality
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('QR Scanner feature coming soon!'),
        backgroundColor: appTheme.blue_gray_300));
  }
}
