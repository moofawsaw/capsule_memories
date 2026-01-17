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
  bool _showConfirmation = false;

  @override
  void initState() {
    super.initState();

    // Listen once (not inside build) so we don't accidentally register multiple listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(featureRequestNotifier, (previous, current) {
        final wasSubmitted = (previous?.isSubmitted ?? false);
        final isSubmitted = (current.isSubmitted ?? false);

        if (!wasSubmitted && isSubmitted) {
          if (mounted) setState(() => _showConfirmation = true);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Feature request submitted successfully!'),
              backgroundColor: appTheme.colorFF52D1,
            ),
          );

          current.featureDescriptionController?.clear();
        }


        final hadError = (previous?.hasError ?? false);
        final hasError = (current.hasError ?? false);

        if (!hadError && hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please provide your feature request details'),
              backgroundColor: appTheme.redCustom,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(featureRequestNotifier);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.blackCustom.withAlpha(89),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ✅ Remove radius around the container
              Container(
                width: 356.h,
                height: 756.h,
                decoration: BoxDecoration(
                  color: appTheme.gray_900_02,
                  borderRadius: BorderRadius.zero,
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

                    // ✅ Replace input with animated confirmation on submit
                    _buildAnimatedBodySection(context),

                    const Spacer(),
                    _buildSubmitButton(context, state: state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header with title + close button
  Widget _buildHeaderSection(BuildContext context) {
    return CustomHeaderRow(
      title: 'Feature Request',
      onIconTap: () => onTapCloseButton(context),
      margin: EdgeInsets.only(top: 10.h, right: 12.h, left: 16.h),
    );
  }

  /// Subtitle text
  Widget _buildSubtitleSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        'Have an idea to improve the app?',
        style: TextStyleHelper.instance.title16RegularPlusJakartaSans
            .copyWith(color: appTheme.blue_gray_300, height: 1.31),
      ),
    );
  }

  Widget _buildAnimatedBodySection(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        final slide = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation),
          child: fade,
        );
        return slide;
      },
      child: _showConfirmation
          ? _buildConfirmationSection(context, key: const ValueKey('confirm'))
          : _buildInputSection(context, key: const ValueKey('input')),
    );
  }

  /// Input text area
  Widget _buildInputSection(BuildContext context, {Key? key}) {
    final state = ref.watch(featureRequestNotifier);

    return CustomEditText(
      key: key,
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
  }

  /// Confirmation UI shown after submit
  Widget _buildConfirmationSection(BuildContext context, {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 18.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(
          color: appTheme.gray_50.withAlpha(24),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38.h,
            height: 38.h,
            decoration: BoxDecoration(
              color: appTheme.colorFF52D1.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: appTheme.colorFF52D1,
              size: 22.h,
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submitted',
                  style: TextStyleHelper.instance.title16SemiBoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Thanks — we read every request and will review it with the dev team.',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Submit button
  Widget _buildSubmitButton(BuildContext context, {required dynamic state}) {
    final isLoading = (state.isLoading ?? false);

    return CustomButton(
      text: _showConfirmation ? 'Done' : 'Submit Request',
      width: double.infinity,
      onPressed: isLoading
          ? null
          : () {
        if (_showConfirmation) {
          onTapCloseButton(context);
          return;
        }
        onTapSubmitRequest(context);
      },
      buttonStyle: CustomButtonStyle.fillPrimary,
      buttonTextStyle: CustomButtonTextStyle.bodyMedium,
      isDisabled: isLoading,
    );
  }

  /// Close button tap
  void onTapCloseButton(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Submit request button tap
  void onTapSubmitRequest(BuildContext context) {
    ref.read(featureRequestNotifier.notifier).submitFeatureRequest();
  }
}
