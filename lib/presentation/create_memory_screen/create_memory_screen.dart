import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_settings_row.dart';
import '../../widgets/custom_feature_card.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_button.dart';
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF5B000000),
        body: Form(
          key: _formKey,
          child: Container(
            width: double.maxFinite,
            child: Column(
              children: [
                _buildMainContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildMainContent(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: 848.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 600.h,
                  decoration: BoxDecoration(
                    color: appTheme.gray_900_02,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(26.h),
                      topRight: Radius.circular(26.h),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 22.h, vertical: 26.h),
                  child: Column(
                    children: [
                      SizedBox(height: 242.h),
                      Container(
                        width: 116.h,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: appTheme.color3BD81E,
                          borderRadius: BorderRadius.circular(6.h),
                        ),
                      ),
                      CustomHeaderSection(
                        title: 'Create Memory',
                        description:
                            'Invite-only. Every perspective. One timeline. Replay forever',
                        margin:
                            EdgeInsets.only(top: 32.h, left: 32.h, right: 32.h),
                      ),
                      _buildNameSection(context),
                      _buildPrivacySettings(context),
                      _buildFeatureCard(context),
                      _buildActionButtons(context),
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

        return Container(
          margin: EdgeInsets.only(top: 20.h),
          child: CustomSettingsRow(
            iconPath: ImageConstant.imgIconGreen500,
            title: 'Public',
            description: 'Anyone can view this memory',
            switchValue: state.createMemoryModel?.isPublic ?? false,
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

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);

        // Listen for navigation
        ref.listen(
          createMemoryNotifier,
          (previous, current) {
            if (current.shouldNavigateToInvite ?? false) {
              NavigatorService.pushNamed(AppRoutes.invitePeopleScreen);
            } else if (current.shouldNavigateBack ?? false) {
              NavigatorService.goBack();
            }
          },
        );

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
                  onPressed: state.isLoading ?? false
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            ref
                                .read(createMemoryNotifier.notifier)
                                .onNextPressed();
                          }
                        },
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  isDisabled: state.isLoading ?? false,
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
}
