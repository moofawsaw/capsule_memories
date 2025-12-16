import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_info_row.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/custom_button.dart';
import 'notifier/invite_people_notifier.dart';

class InvitePeopleScreen extends ConsumerStatefulWidget {
  InvitePeopleScreen({Key? key}) : super(key: key);

  @override
  InvitePeopleScreenState createState() => InvitePeopleScreenState();
}

class InvitePeopleScreenState extends ConsumerState<InvitePeopleScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF5b000000),
        body: SizedBox(
          width: double.maxFinite,
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
                      height: 534.h,
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
                    padding: EdgeInsets.all(22.h),
                    child: Column(
                      children: [
                        SizedBox(height: 312.h),
                        Container(
                          width: 116.h,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Color(0xFFd81e293b),
                            borderRadius: BorderRadius.circular(6.h),
                          ),
                        ),
                        CustomHeaderSection(
                          title: 'Invite People',
                          description:
                              'Invite-only. Every perspective. One timeline. Replay forever',
                          margin: EdgeInsets.only(
                              top: 32.h, left: 58.h, right: 58.h),
                        ),
                        _buildInviteSection(context),
                        _buildFormSection(context),
                        _buildInfoSection(context),
                        _buildActionButtons(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildInviteSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 26.h, left: 10.h, right: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'Invite people (optional)',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
            ),
          ),
          CustomIconButtonRow(
            firstIconPath: ImageConstant.imgButtons,
            secondIconPath: ImageConstant.imgButtonsGray50,
            onFirstIconTap: () {
              onTapQRCode(context);
            },
            onSecondIconTap: () {
              onTapCamera(context);
            },
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildFormSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(invitePeopleNotifier);

        return Column(
          children: [
            CustomDropdown<String>(
              items: _buildDropdownItems(),
              onChanged: (value) {
                ref
                    .read(invitePeopleNotifier.notifier)
                    .updateSelectedGroup(value);
              },
              value: state.invitePeopleModel?.selectedGroup,
              placeholder: 'Select from group...',
              leftIcon: ImageConstant.imgIconBlueGray30022x26,
              rightIcon: ImageConstant.imgIconBlueGray30022x18,
              margin: EdgeInsets.only(top: 20.h),
            ),
            CustomSearchView(
              controller: state.searchController,
              placeholder: 'Search by name...',
              margin: EdgeInsets.only(top: 20.h),
              onChanged: (value) {
                ref
                    .read(invitePeopleNotifier.notifier)
                    .updateSearchQuery(value);
              },
            ),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildInfoSection(BuildContext context) {
    return CustomInfoRow(
      iconPath: ImageConstant.imgFrameBlueGray300,
      text: 'You can also share a link after creating the memory',
      textWidth: 0.82,
      margin: EdgeInsets.only(top: 20.h, right: 26.h, left: 12.h),
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(invitePeopleNotifier);

        ref.listen(
          invitePeopleNotifier,
          (previous, current) {
            if (current.isNavigating ?? false) {
              if (current.navigationRoute != null) {
                NavigatorService.pushNamed(current.navigationRoute!);
              }
            }
          },
        );

        return Container(
          margin: EdgeInsets.only(top: 20.h),
          child: Row(
            spacing: 12.h,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Back',
                  // Modified: Replaced ButtonStyle with CustomButtonStyle.outlineDark
                  buttonStyle: CustomButtonStyle.outlineDark,
                  // Modified: Replaced TextStyle with CustomButtonTextStyle.bodyMediumGray
                  buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                  onPressed: () {
                    onTapBack(context);
                  },
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Create',
                  // Modified: Replaced ButtonStyle with CustomButtonStyle.fillPrimary
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  // Modified: Replaced TextStyle with CustomButtonTextStyle.bodyMedium
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  isDisabled: state.isLoading,
                  onPressed: () {
                    onTapCreate(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dropdown items builder
  List<DropdownMenuItem<String>> _buildDropdownItems() {
    return [
      DropdownMenuItem(
        value: 'family',
        child: Text('Family'),
      ),
      DropdownMenuItem(
        value: 'friends',
        child: Text('Friends'),
      ),
      DropdownMenuItem(
        value: 'work',
        child: Text('Work'),
      ),
      DropdownMenuItem(
        value: 'school',
        child: Text('School'),
      ),
    ];
  }

  /// Navigation handlers
  void onTapQRCode(BuildContext context) {
    ref.read(invitePeopleNotifier.notifier).handleQRCodeTap();
  }

  void onTapCamera(BuildContext context) {
    ref.read(invitePeopleNotifier.notifier).handleCameraTap();
  }

  void onTapBack(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.createMemoryScreen);
  }

  void onTapCreate(BuildContext context) {
    ref.read(invitePeopleNotifier.notifier).createMemory();
  }
}
