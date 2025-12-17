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
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          // Drag handle indicator
          Container(
            width: 48.h,
            height: 5.h,
            decoration: BoxDecoration(
              color: appTheme.colorFF3A3A,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          SizedBox(height: 20.h),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryMembersNotifier);

        return Column(
          children: [
            _buildHeaderSection(context),
            SizedBox(height: 16.h),
            SizedBox(height: 16.h),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildHeaderSection(BuildContext context) {
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
