import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_feature_card.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_settings_row.dart';
import 'notifier/create_memory_notifier.dart';

class CreateMemoryScreen extends ConsumerStatefulWidget {
  CreateMemoryScreen({Key? key}) : super(key: key);

  @override
  CreateMemoryScreenState createState() => CreateMemoryScreenState();
}

class CreateMemoryScreenState extends ConsumerState<CreateMemoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final currentStep = state.currentStep ?? 1;

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
                  child: Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: currentStep == 1
                          ? _buildStep1Content(context)
                          : _buildStep2Content(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Step 1: Memory Creation Form
  Widget _buildStep1Content(BuildContext context) {
    return Column(
      key: ValueKey('step1'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomHeaderSection(
          title: 'Create Memory',
          description:
              'Invite-only. Every perspective. One timeline. Replay forever',
          margin: EdgeInsets.only(left: 10.h, right: 10.h),
        ),
        _buildNameSection(context),
        _buildPrivacySettings(context),
        _buildFeatureCard(context),
        _buildStep1ActionButtons(context),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// Step 2: Invite People
  Widget _buildStep2Content(BuildContext context) {
    return Column(
      key: ValueKey('step2'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomHeaderSection(
          title: 'Invite people (optional)',
          description: 'Add friends and family to share this memory together',
          margin: EdgeInsets.only(left: 10.h, right: 10.h),
        ),
        _buildInviteIconButtons(context),
        SizedBox(height: 16.h),
        _buildInviteOptionsSection(context),
        SizedBox(height: 20.h),
        _buildStep2ActionButtons(context),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// Section Widget
  Widget _buildNameSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name your memory',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 10.h),
              CustomEditText(
                controller: state.memoryNameController,
                hintText: 'e.g Family Xmas 2026',
                validator: (value) {
                  final notifier = ref.read(createMemoryNotifier.notifier);
                  return notifier.validateMemoryName(value);
                },
                fillColor: appTheme.gray_900,
                borderRadius: 8.h,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildPrivacySettings(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final isPublic = state.createMemoryModel?.isPublic ?? false;

        return Container(
          margin: EdgeInsets.only(top: 20.h),
          child: CustomSettingsRow(
            useIconData: !isPublic,
            iconData: !isPublic ? Icons.lock : null,
            iconPath: isPublic ? ImageConstant.imgIconGreen500 : null,
            iconColor: !isPublic ? appTheme.deep_purple_A100 : null,
            title: isPublic ? 'Public' : 'Private',
            description: isPublic
                ? 'Anyone can view this memory'
                : 'Only members can view',
            switchValue: isPublic,
            onSwitchChanged: (value) {
              ref
                  .read(createMemoryNotifier.notifier)
                  .togglePrivacySetting(value);
            },
            margin: EdgeInsets.zero,
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildFeatureCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      child: CustomFeatureCard(
        iconPath: ImageConstant.imgFrameDeepPurpleA200,
        title: '12-hour posting window',
        description:
            'Memories are open for 12 hours but don\'t sweat it if you missed someone, footage can be added later.',
        backgroundColor: appTheme.colorF716A8,
        iconBackgroundColor: appTheme.color41C124,
        titleColor: appTheme.deep_purple_A200,
        margin: EdgeInsets.zero,
      ),
    );
  }

  /// Step 1 Action Buttons
  Widget _buildStep1ActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 20.h),
          child: Row(
            spacing: 12.h,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () {
                    ref.read(createMemoryNotifier.notifier).onCancelPressed();
                  },
                  buttonStyle: CustomButtonStyle.fillDark,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Next',
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      ref.read(createMemoryNotifier.notifier).moveToStep2();
                    }
                  },
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Invite Icon Buttons
  Widget _buildInviteIconButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          margin: EdgeInsets.only(top: 20.h),
          child: CustomIconButtonRow(
            firstIconPath: ImageConstant.imgButtons,
            secondIconPath: ImageConstant.imgButtonsGray50,
            onFirstIconTap: () {
              ref.read(createMemoryNotifier.notifier).handleQRCodeTap();
            },
            onSecondIconTap: () {
              ref.read(createMemoryNotifier.notifier).handleCameraTap();
            },
          ),
        );
      },
    );
  }

  /// Invite Header Section
  Widget _buildInviteHeaderSection(BuildContext context) {
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
              ref.read(createMemoryNotifier.notifier).handleQRCodeTap();
            },
            onSecondIconTap: () {
              ref.read(createMemoryNotifier.notifier).handleCameraTap();
            },
          ),
        ],
      ),
    );
  }

  /// Invite Options Section
  Widget _buildInviteOptionsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);

        return Column(
          children: [
            CustomDropdown<String>(
              items: _buildDropdownItems(),
              onChanged: (value) {
                ref
                    .read(createMemoryNotifier.notifier)
                    .updateSelectedGroup(value);
              },
              value: state.createMemoryModel?.selectedGroup,
              placeholder: 'Select from group...',
              leftIcon: ImageConstant.imgIconBlueGray30022x26,
              rightIcon: ImageConstant.imgIconBlueGray30022x18,
              margin: EdgeInsets.only(top: 20.h),
            ),
          ],
        );
      },
    );
  }

  /// Step 2 Action Buttons
  Widget _buildStep2ActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);

        // Listen for navigation
        ref.listen(
          createMemoryNotifier,
          (previous, current) {
            if (current.shouldNavigateBack ?? false) {
              NavigatorService.goBack();
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
                  buttonStyle: CustomButtonStyle.fillDark,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  onPressed: () {
                    ref.read(createMemoryNotifier.notifier).backToStep1();
                  },
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Create',
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  isDisabled: state.isLoading,
                  onPressed: () {
                    ref.read(createMemoryNotifier.notifier).createMemory();
                  },
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
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
}
