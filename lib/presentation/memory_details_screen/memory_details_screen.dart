import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
import '../invite_people_screen/invite_people_screen.dart';
import './models/memory_details_model.dart';
import './widgets/member_item_widget.dart';
import 'notifier/memory_details_notifier.dart';

class MemoryDetailsScreen extends ConsumerStatefulWidget {
  MemoryDetailsScreen({Key? key}) : super(key: key);

  @override
  MemoryDetailsScreenState createState() => MemoryDetailsScreenState();
}

class MemoryDetailsScreenState extends ConsumerState<MemoryDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: 24.h),
                  _buildMemoryInfo(context),
                  SizedBox(height: 24.h),
                  _buildMembersList(context),
                  SizedBox(height: 24.h),
                  _buildActionButtons(context),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Title',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300, height: 1.31),
              ),
            ),
            SizedBox(height: 12.h),
            CustomEditText(
              controller: state.titleController,
              hintText: 'Family Xmas 2025',
              suffixIcon: ImageConstant.imgIconGray5018x20,
              fillColor: appTheme.gray_900,
              borderRadius: 8.h,
              textStyle: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildMemoryInfo(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        final notifier = ref.read(memoryDetailsNotifier.notifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgFrameBlueGray300,
                  height: 18.h,
                  width: 18.h,
                ),
                SizedBox(width: 6.h),
                Text(
                  'Invite Link',
                  style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.31),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              margin: EdgeInsets.only(right: 12.h),
              child: Row(
                spacing: 22.h,
                children: [
                  Expanded(
                    child: CustomEditText(
                      controller: state.inviteLinkController,
                      hintText: ImageConstant
                          .imgNetworkR812309r72309r572093t722323t23t23t08,
                      fillColor: appTheme.gray_900,
                      borderRadius: 8.h,
                      textStyle: TextStyleHelper
                          .instance.title16RegularPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                      readOnly: true,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      notifier.copyInviteLink();
                    },
                    child: CustomImageView(
                      imagePath: ImageConstant.imgIcon14,
                      height: 24.h,
                      width: 24.h,
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

  /// Section Widget
  Widget _buildMembersList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgIconBlueGray30018x18,
                  height: 18.h,
                  width: 18.h,
                ),
                SizedBox(width: 6.h),
                Text(
                  'Members',
                  style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.31),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Column(
              spacing: 6.h,
              children: [
                MemberItemWidget(
                  member:
                      state.memoryDetailsModel?.members?[0] ?? MemberModel(),
                ),
                MemberItemWidget(
                  member:
                      state.memoryDetailsModel?.members?[1] ?? MemberModel(),
                  onTap: () {
                    onTapMemberAction(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        final notifier = ref.read(memoryDetailsNotifier.notifier);

        return Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Save',
                onPressed: () {
                  notifier.saveMemory();
                },
                isDisabled: state.isSaving,
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: CustomButton(
                text: 'Share',
                onPressed: () {
                  notifier.shareMemory();
                },
                isDisabled: state.isSharing,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Navigates to search and add people screen
  void onTapSearchAddPeople(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => InvitePeopleScreen(),
    );
  }

  /// Handles member action tap
  void onTapMemberAction(BuildContext context) {
    // Handle member action
  }
}
