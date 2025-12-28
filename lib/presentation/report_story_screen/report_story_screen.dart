import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_header_row.dart';
import '../../widgets/custom_radio_group.dart';
import '../../widgets/custom_user_list_item.dart';
import './notifier/report_story_notifier.dart';

class ReportStoryScreen extends ConsumerStatefulWidget {
  ReportStoryScreen({Key? key}) : super(key: key);

  @override
  ReportStoryScreenState createState() => ReportStoryScreenState();
}

class ReportStoryScreenState extends ConsumerState<ReportStoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.h),
              topRight: Radius.circular(30.h),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(40.h),
            child: Column(
              children: [
                _buildHeaderSection(context),
                SizedBox(height: 38.h),
                _buildUserInfoSection(context),
                SizedBox(height: 28.h),
                _buildReportOptionsSection(context),
                SizedBox(height: 28.h),
                _buildAdditionalDetailsSection(context),
                SizedBox(height: 16.h),
                _buildSubmitButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildMainContent(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      padding: EdgeInsets.all(40.h),
      decoration: BoxDecoration(
        color: appTheme.color5B0000,
      ),
      child: Column(
        children: [
          _buildHeaderSection(context),
          SizedBox(height: 38.h),
          _buildUserInfoSection(context),
          SizedBox(height: 28.h),
          _buildReportOptionsSection(context),
          SizedBox(height: 28.h),
          _buildAdditionalDetailsSection(context),
          SizedBox(height: 16.h),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildHeaderSection(BuildContext context) {
    return CustomHeaderRow(
      title: 'Report Story',
      margin: EdgeInsets.only(top: 22.h, left: 12.h, right: 12.h),
      onIconTap: () => onTapCloseButton(context),
    );
  }

  /// Section Widget
  Widget _buildUserInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report story posted by user:',
          style: TextStyleHelper.instance.title16RegularPlusJakartaSans
              .copyWith(color: appTheme.blue_gray_300, height: 1.31),
        ),
        SizedBox(height: 14.h),
        CustomUserListItem(
          imagePath: ImageConstant.imgEllipse8DeepOrange100,
          name: 'Sarah Smith',
          margin: EdgeInsets.zero,
        ),
      ],
    );
  }

  /// Section Widget
  Widget _buildReportOptionsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(reportStoryNotifier);
        final notifier = ref.read(reportStoryNotifier.notifier);

        ref.listen(
          reportStoryNotifier,
          (previous, current) {
            if (current.isSubmitted ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report submitted successfully'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
              NavigatorService.goBack();
            }
          },
        );

        return CustomRadioGroup<String>(
          options: [
            CustomRadioOption(
                value: 'inappropriate', label: 'Inappropriate Content'),
            CustomRadioOption(
                value: 'harassment', label: 'Harassment or Bullying'),
            CustomRadioOption(value: 'spam', label: 'Spam'),
            CustomRadioOption(
                value: 'violence', label: 'Violence / Dangerous Content'),
            CustomRadioOption(value: 'hate_speech', label: 'Hate Speech'),
            CustomRadioOption(value: 'other', label: 'Other'),
          ],
          selectedValue: state.reportStoryModel?.selectedReason,
          onChanged: (value) => notifier.onReasonChanged(value),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildAdditionalDetailsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(reportStoryNotifier);

        return Form(
          key: _formKey,
          child: CustomEditText(
            controller: state.additionalDetailsController,
            hintText: 'Additional details',
            maxLines: 4,
            fillColor: appTheme.gray_900,
            borderRadius: 8.h,
            validator: (value) => _validateAdditionalDetails(value),
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildSubmitButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(reportStoryNotifier);
        final notifier = ref.read(reportStoryNotifier.notifier);

        return CustomButton(
          text: 'Report Story',
          width: double.infinity,
          onPressed: () => onTapReportStoryButton(context, notifier),
          buttonStyle: CustomButtonStyle
              .fillDark, // Modified: Replaced unavailable fillRed style with fillDark
          buttonTextStyle: CustomButtonTextStyle
              .bodyMedium, // Modified: Replaced unavailable bodyMediumWhite style with bodyMedium
          isDisabled: state.isLoading ?? false,
        );
      },
    );
  }

  /// Validation method for additional details
  String? _validateAdditionalDetails(String? value) {
    if (value != null && value.length > 500) {
      return 'Additional details should not exceed 500 characters';
    }
    return null;
  }

  /// Navigates back to the previous screen
  void onTapCloseButton(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles report story submission
  void onTapReportStoryButton(
      BuildContext context, ReportStoryNotifier notifier) {
    if (_formKey.currentState?.validate() ?? false) {
      notifier.submitReport();
    }
  }
}
