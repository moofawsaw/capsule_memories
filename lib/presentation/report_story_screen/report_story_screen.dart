import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_header_row.dart';
import '../../widgets/custom_radio_group.dart';
import '../../widgets/custom_user_list_item.dart';
import './notifier/report_story_notifier.dart';

class ReportStoryScreen extends ConsumerStatefulWidget {
  const ReportStoryScreen({
    Key? key,
    required this.storyId,
    required this.reportedUserName,
    required this.reportedUserId,
    this.reportedUserAvatar,
    this.storyTitle,
    this.storyPostedAtLabel,
  }) : super(key: key);

  final String storyId;
  final String reportedUserName;
  final String reportedUserId;
  final String? reportedUserAvatar;

  // Optional: pass these from story viewer if you have them
  final String? storyTitle;
  final String? storyPostedAtLabel;

  @override
  ReportStoryScreenState createState() => ReportStoryScreenState();
}

class ReportStoryScreenState extends ConsumerState<ReportStoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportStoryNotifier.notifier).setContext(
        storyId: widget.storyId,
        reportedUserName: widget.reportedUserName,
        reportedUserId: widget.reportedUserId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Regular bottom sheet content (no Scaffold, no SafeArea)
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.gray_900_02,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
        ),
        padding: EdgeInsets.only(
          left: 20.h,
          right: 20.h,
          top: 12.h,
          // ✅ manual bottom safe area handling (gesture bar)
          bottom: 16.h + MediaQuery.of(context).padding.bottom,
        ),
        child: SingleChildScrollView(
          // ✅ keyboard-safe
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(context),
              SizedBox(height: 12.h),

              _buildUserInfoSection(context),
              SizedBox(height: 12.h),

              _buildReportOptionsSection(context),
              SizedBox(height: 10.h),

              _buildAdditionalDetailsSection(context),
              SizedBox(height: 12.h),

              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return CustomHeaderRow(
      title: 'Report Story',
      textAlignment: TextAlign.center,
      margin: EdgeInsets.zero,
      onIconTap: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(reportStoryNotifier);
        final model = state.reportStoryModel;

        final displayName = model?.reportedUser ?? widget.reportedUserName;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reporting story posted by:',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
            ),
            SizedBox(height: 8.h),

            // If CustomUserListItem is too large and has no sizing controls,
            // replace it with your own Row. For now, keep it.
            CustomUserListItem(
              imagePath: widget.reportedUserAvatar ?? ImageConstant.imgEllipse842x42,
              name: displayName,
              avatarSize: 28, // 👈 smaller avatar for modal
              margin: EdgeInsets.zero,
            ),

            if ((widget.storyTitle != null && widget.storyTitle!.isNotEmpty) ||
                (widget.storyPostedAtLabel != null && widget.storyPostedAtLabel!.isNotEmpty))
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.storyTitle != null && widget.storyTitle!.isNotEmpty)
                      Text(
                        widget.storyTitle!,
                        style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                            .copyWith(color: appTheme.whiteCustom.withAlpha(220)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.storyPostedAtLabel != null && widget.storyPostedAtLabel!.isNotEmpty)
                      Text(
                        widget.storyPostedAtLabel!,
                        style: TextStyleHelper.instance.body12RegularPlusJakartaSans
                            .copyWith(color: appTheme.blue_gray_300),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReportOptionsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(reportStoryNotifier);
        final notifier = ref.read(reportStoryNotifier.notifier);

        ref.listen(reportStoryNotifier, (previous, current) {
          final msg = current.errorMessage;
          if (msg != null && msg.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: appTheme.redCustom,
              ),
            );
          }

          if ((current.isSubmitted ?? false) == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Report submitted successfully'),
                backgroundColor: appTheme.colorFF52D1,
              ),
            );
            Navigator.of(context).pop();
          }
        });


        // NOTE: no const list, because your CustomRadioOption is not const
        return CustomRadioGroup<String>(
          options: [
            CustomRadioOption(value: 'inappropriate', label: 'Inappropriate Content'),
            CustomRadioOption(value: 'harassment', label: 'Harassment or Bullying'),
            CustomRadioOption(value: 'spam', label: 'Spam'),
            CustomRadioOption(value: 'violence', label: 'Violence / Dangerous Content'),
            CustomRadioOption(value: 'hate_speech', label: 'Hate Speech'),
            CustomRadioOption(value: 'other', label: 'Other'),
          ],
          selectedValue: state.reportStoryModel?.selectedReason,
          onChanged: (value) => notifier.onReasonChanged(value),
        );
      },
    );
  }

  Widget _buildAdditionalDetailsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(reportStoryNotifier);

        return Form(
          key: _formKey,
          child: CustomEditText(
            controller: state.additionalDetailsController,
            hintText: 'Additional details (optional)',
            maxLines: 4,
            fillColor: appTheme.gray_900,
            borderRadius: 8.h,
            validator: _validateAdditionalDetails,
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(reportStoryNotifier);
        final notifier = ref.read(reportStoryNotifier.notifier);

        return CustomButton(
          text: 'Submit Report',
          width: double.infinity,
          onPressed: () => onTapReportStoryButton(notifier),
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
          isDisabled: state.isLoading ?? false,
        );
      },
    );
  }

  String? _validateAdditionalDetails(String? value) {
    if (value != null && value.length > 500) {
      return 'Additional details should not exceed 500 characters';
    }
    return null;
  }

  void onTapReportStoryButton(ReportStoryNotifier notifier) {
    if (_formKey.currentState?.validate() ?? false) {
      notifier.submitReport();
    }
  }
}
