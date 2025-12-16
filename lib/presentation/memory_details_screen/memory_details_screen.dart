import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_settings_row.dart';
import '../../widgets/custom_button.dart';
import 'models/memory_details_model.dart';
import 'notifier/memory_details_notifier.dart';
import 'widgets/member_item_widget.dart';

class MemoryDetailsScreen extends ConsumerStatefulWidget {
  MemoryDetailsScreen({Key? key}) : super(key: key);

  @override
  MemoryDetailsScreenState createState() => MemoryDetailsScreenState();
}

class MemoryDetailsScreenState extends ConsumerState<MemoryDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.maxFinite,
                    height: 848.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.maxFinite,
                            height: 738.h,
                            decoration: BoxDecoration(
                              color: appTheme.gray_900_02,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(26.h),
                                topRight: Radius.circular(26.h),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.maxFinite,
                          height: double.maxFinite,
                          padding: EdgeInsets.symmetric(
                            horizontal: 22.h,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: appTheme.color5B0000,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 123.h),
                              Container(
                                width: 116.h,
                                height: 12.h,
                                decoration: BoxDecoration(
                                  color: appTheme.color3BD81E,
                                  borderRadius: BorderRadius.circular(6.h),
                                ),
                              ),
                              SizedBox(height: 32.h),
                              Text(
                                'Memory Details',
                                style: TextStyleHelper
                                    .instance.headline24ExtraBoldPlusJakartaSans
                                    .copyWith(height: 1.29),
                              ),
                              SizedBox(height: 24.h),
                              _buildTitleSection(context),
                              SizedBox(height: 20.h),
                              _buildVisibilitySection(context),
                              SizedBox(height: 20.h),
                              _buildInviteLinkSection(context),
                              SizedBox(height: 20.h),
                              _buildAddPeopleSection(context),
                              SizedBox(height: 20.h),
                              _buildMembersSection(context),
                            ],
                          ),
                        ),
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

  /// Section Widget
  Widget _buildTitleSection(BuildContext context) {
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
  Widget _buildVisibilitySection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        final notifier = ref.read(memoryDetailsNotifier.notifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Visibility',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300, height: 1.31),
              ),
            ),
            SizedBox(height: 10.h),
            CustomSettingsRow(
              iconPath: ImageConstant.imgIconGreen500,
              title: 'Public',
              description: 'Anyone can view this memory',
              switchValue: state.isPublic ?? true,
              onSwitchChanged: (value) {
                notifier.updateVisibility(value);
              },
              margin: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildInviteLinkSection(BuildContext context) {
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
  Widget _buildAddPeopleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomImageView(
              imagePath: ImageConstant.imgIconBlueGray30022x26,
              height: 18.h,
              width: 18.h,
            ),
            SizedBox(width: 6.h),
            Text(
              'Add People',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300, height: 1.31),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        CustomButton(
          text: 'Search & Add People',
          width: double.infinity,
          leftIcon: ImageConstant.imgIconGray5018x18,
          onPressed: () {
            onTapSearchAddPeople(context);
          },
          buttonStyle: CustomButtonStyle.outlineDark,
          buttonTextStyle: CustomButtonTextStyle.bodySmallPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: 30.h,
            vertical: 12.h,
          ),
        ),
      ],
    );
  }

  /// Section Widget
  Widget _buildMembersSection(BuildContext context) {
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

  /// Navigates to search and add people screen
  void onTapSearchAddPeople(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.hangoutCallScreen);
  }

  /// Handles member action tap
  void onTapMemberAction(BuildContext context) {
    // Handle member action
  }
}
