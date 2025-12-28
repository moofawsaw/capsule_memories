import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_header_row.dart';
import 'notifier/feature_request_notifier.dart';

class FeatureRequestScreen extends ConsumerStatefulWidget {
  FeatureRequestScreen({Key? key}) : super(key: key);

  @override
  FeatureRequestScreenState createState() => FeatureRequestScreenState();
}

class FeatureRequestScreenState extends ConsumerState<FeatureRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.blackCustom.withAlpha(89),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 356.h,
                height: 756.h,
                decoration: BoxDecoration(
                  color: appTheme.gray_900_02,
                  borderRadius: BorderRadius.circular(30.h),
                ),
              ),
              Container(
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 40.h,
                  vertical: 66.h,
                ),
                child: Column(
                  children: [
                    _buildHeaderSection(context),
                    SizedBox(height: 24.h),
                    _buildSubtitleSection(context),
                    SizedBox(height: 10.h),
                    _buildInputSection(context),
                    Spacer(),
                    _buildSubmitButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget - Header with title and close button
  Widget _buildHeaderSection(BuildContext context) {
    return CustomHeaderRow(
      title: 'Feature Request',
      onIconTap: () => onTapCloseButton(context),
      textAlignment: TextAlign.center,
      margin: EdgeInsets.only(top: 10.h, right: 12.h, left: 16.h),
    );
  }

  /// Section Widget - Subtitle text
  Widget _buildSubtitleSection(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Text(
        'Have an idea to improve the app?',
        style: TextStyleHelper.instance.title16RegularPlusJakartaSans
            .copyWith(color: appTheme.blue_gray_300, height: 1.31),
      ),
    );
  }

  /// Section Widget - Input text area
  Widget _buildInputSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(featureRequestNotifier);

        return CustomEditText(
          controller: state.featureDescriptionController,
          hintText:
              'Tell us your feature improvement and we\'ll talk it over with our dev team! We read every request and value the ideas of our user.',
          maxLines: 12,
          fillColor: appTheme.gray_900,
          borderRadius: 8.h,
          contentPadding: EdgeInsets.only(
            top: 16.h,
            right: 16.h,
            bottom: 12.h,
            left: 16.h,
          ),
          validator: (value) => ref
              .read(featureRequestNotifier.notifier)
              .validateFeatureDescription(value),
        );
      },
    );
  }

  /// Section Widget - Submit button
  Widget _buildSubmitButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(featureRequestNotifier);

        ref.listen(
          featureRequestNotifier,
          (previous, current) {
            if (current.isSubmitted ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Feature request submitted successfully!'),
                  backgroundColor: appTheme.colorFF52D1,
                ),
              );
              NavigatorService.goBack();
            }

            if (current.hasError ?? false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please provide your feature request details'),
                  backgroundColor: appTheme.redCustom,
                ),
              );
            }
          },
        );

        return CustomButton(
          text: 'Submit Request',
          width: double.infinity,
          onPressed: () => onTapSubmitRequest(context),
          buttonStyle: CustomButtonStyle.fillPrimary,
          buttonTextStyle: CustomButtonTextStyle.bodyMedium,
          isDisabled: state.isLoading ?? false,
        );
      },
    );
  }

  /// Handles close button tap
  void onTapCloseButton(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles submit request button tap
  void onTapSubmitRequest(BuildContext context) {
    ref.read(featureRequestNotifier.notifier).submitFeatureRequest();
  }
}
