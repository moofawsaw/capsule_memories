import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_user_card.dart';
import '../../widgets/custom_user_status_row.dart';
import 'notifier/memory_members_notifier.dart';

class MemoryMembersScreen extends ConsumerStatefulWidget {
  MemoryMembersScreen({Key? key}) : super(key: key);

  @override
  MemoryMembersScreenState createState() => MemoryMembersScreenState();
}

class MemoryMembersScreenState extends ConsumerState<MemoryMembersScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: Color(0xFF5B000000),
            body: Container(
                width: double.maxFinite,
                height: SizeUtils.height,
                child: Column(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          child: Container(
                              width: double.maxFinite,
                              height: 848.h,
                              child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Container(
                                        width: double.maxFinite,
                                        height: 318.h,
                                        margin: EdgeInsets.only(top: 531.h),
                                        decoration: BoxDecoration(
                                            color: appTheme.gray_900_02,
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(26.h),
                                                topRight:
                                                    Radius.circular(26.h)))),
                                    Container(
                                        width: double.maxFinite,
                                        height: double.maxFinite,
                                        padding: EdgeInsets.fromLTRB(
                                            32.h, 26.h, 32.h, 26.h),
                                        decoration: BoxDecoration(
                                            color: appTheme.color5B0000),
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Spacer(),
                                              Container(
                                                  width: 116.h,
                                                  height: 12.h,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          appTheme.color3BD81E,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.h))),
                                              SizedBox(height: 32.h),
                                              _buildMemoryMembersSection(
                                                  context),
                                            ])),
                                  ])))),
                ]))));
  }

  /// Section Widget
  Widget _buildMemoryMembersSection(BuildContext context) {
    return Container(
        width: double.maxFinite,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Memory Members',
              style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
                  .copyWith(height: 1.29)),
          SizedBox(height: 24.h),
          _buildMembersList(context),
        ]));
  }

  /// Section Widget
  Widget _buildMembersList(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(memoryMembersNotifier);

      return Column(spacing: 10.h, children: [
        CustomUserCard(
            userName: 'Joe Dirt',
            profileImagePath: ImageConstant.imgEllipse826x26),
        CustomUserStatusRow(
            profileImagePath: ImageConstant.imgFrame3,
            userName: 'Cassey Campbell',
            onTap: () => _onTapMember(context, 'Cassey Campbell')),
        CustomUserStatusRow(
            profileImagePath: ImageConstant.imgEllipse81,
            userName: 'Jane Doe',
            statusText: 'Pending Invite',
            statusBackgroundColor: appTheme.gray_900_03,
            statusTextColor: appTheme.orange_700,
            onTap: () => _onTapMember(context, 'Jane Doe')),
      ]);
    });
  }

  /// Handle member tap
  void _onTapMember(BuildContext context, String memberName) {
    ref.read(memoryMembersNotifier.notifier).selectMember(memberName);
  }
}
