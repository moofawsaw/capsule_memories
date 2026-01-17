// lib/presentation/feature_request_screen/feature_request_screen.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import 'notifier/feature_request_notifier.dart';

class FeatureRequestScreen extends ConsumerStatefulWidget {
  FeatureRequestScreen({Key? key}) : super(key: key);

  @override
  FeatureRequestScreenState createState() => FeatureRequestScreenState();
}

class FeatureRequestScreenState extends ConsumerState<FeatureRequestScreen> {
  static const List<String> _categories = <String>[
    'UX',
    'Bug',
    'Performance',
    'Feature',
    'Other',
  ];

  String? _selectedCategory;

  // ✅ Cache local submit timestamp for receipt UI
  DateTime? _submittedAtLocal;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<FeatureRequestState>(featureRequestNotifier, (previous, current) {
        final prevStatus = previous?.status ?? FeatureRequestStatus.idle;
        final currStatus = current.status;

        if (prevStatus == currStatus) return;

        if (currStatus == FeatureRequestStatus.success) {
          // ✅ Haptic on success
          HapticFeedback.lightImpact();

          // ✅ Capture timestamp when we first hit success (only once)
          _submittedAtLocal ??= DateTime.now();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request submitted'),
              backgroundColor: appTheme.colorFF52D1,
            ),
          );
        }

        if (currStatus == FeatureRequestStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(current.message ?? 'Something went wrong'),
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
    final showReceipt = state.isCompleted;

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.h, 18.h, 20.h, 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(context),
              SizedBox(height: 14.h),
              _buildSubtitleSection(context),

              if (!showReceipt) ...[
                SizedBox(height: 14.h),
                _buildCategoryChipsSection(context, state),
                SizedBox(height: 12.h),
              ] else ...[
                SizedBox(height: 16.h),
              ],

              Expanded(child: _buildAnimatedBodySection(context, state)),

              SizedBox(height: 14.h),
              _buildSubmitButton(context, state: state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appTheme.gray_50.withAlpha(18),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 44.h),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 20.h,
                    color: appTheme.deep_purple_A100,
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Submit Request',
                    style: TextStyleHelper.instance.title18SemiBoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 44.h,
            height: 44.h,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.h),
                onTap: () => onTapCloseButton(context),
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    color: appTheme.gray_50,
                    size: 22.h,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleSection(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Got an idea to improve ',
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300, height: 1.31),
          ),
          TextSpan(
            text: 'Capsule',
            style: TextStyleHelper.instance.title16SemiBoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50, height: 1.31),
          ),
          TextSpan(
            text: '?',
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300, height: 1.31),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChipsSection(BuildContext context, FeatureRequestState state) {
    final isLocked = state.isCompleted || state.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyleHelper.instance.body14MediumPlusJakartaSans
              .copyWith(color: appTheme.gray_50.withAlpha(220)),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 10.h,
          runSpacing: 10.h,
          children: _categories.map((label) {
            final selected = _selectedCategory == label;

            final bg = selected
                ? appTheme.deep_purple_A100.withAlpha(26)
                : appTheme.gray_900;

            final textColor = selected ? appTheme.gray_50 : appTheme.blue_gray_300;

            return _ChipPill(
              label: label,
              isSelected: selected,
              isDisabled: isLocked,
              backgroundColor: bg,
              textColor: textColor,
              onTap: () {
                if (isLocked) return;
                setState(() {
                  _selectedCategory = selected ? null : label;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnimatedBodySection(BuildContext context, FeatureRequestState state) {
    final showReceipt = state.isCompleted;

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
      child: showReceipt
          ? Align(
        key: const ValueKey('receipt_wrap'),
        alignment: Alignment.topCenter,
        child: _buildReceiptSection(context, state: state),
      )
          : _buildInputSection(context, key: const ValueKey('input')),
    );
  }

  Widget _buildInputSection(BuildContext context, {Key? key}) {
    final state = ref.watch(featureRequestNotifier);

    return CustomEditText(
      key: key,
      controller: state.featureDescriptionController,
      hintText:
      'Describe what you want changed and why. If you can, include where it happens in the app.',
      maxLines: 12,
      fillColor: appTheme.gray_900,
      borderRadius: 12.h,
      contentPadding: EdgeInsets.fromLTRB(16.h, 16.h, 16.h, 14.h),
      validator: (value) => ref
          .read(featureRequestNotifier.notifier)
          .validateFeatureDescription(value),
    );
  }

  /// ✅ Receipt UI:
  /// - Adds timestamp line
  /// - Shows email + "email will be sent to {email}"
  /// - Category shown as badge
  /// - Better hierarchy using font weights
  Widget _buildReceiptSection(
      BuildContext context, {
        required FeatureRequestState state,
      }) {
    final isSuccess = state.status == FeatureRequestStatus.success;

    final accent = isSuccess ? appTheme.colorFF52D1 : appTheme.redCustom;
    final icon = isSuccess ? Icons.check_rounded : Icons.error_outline_rounded;

    final title = isSuccess ? 'Submitted' : 'Not Submitted';

    final categoryLabel = (_selectedCategory ?? 'Other').trim();

    final submittedAt = _submittedAtLocal;
    final timestampText =
    submittedAt == null ? null : DateFormat('MMM d, yyyy • h:mm a').format(submittedAt);

    // ✅ Prefer the logged-in user email from Supabase session (no extra DB calls)
    final userEmail =
        SupabaseService.instance.client?.auth.currentUser?.email ??
            '';

    if (!isSuccess) {
      final body = state.message ??
          'We couldn’t submit your request right now. Please try again later.';

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 18.h),
        decoration: BoxDecoration(
          color: appTheme.gray_900,
          borderRadius: BorderRadius.circular(14.h),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 2.h),
              width: 38.h,
              height: 38.h,
              decoration: BoxDecoration(
                color: accent.withAlpha(28),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 22.h),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyleHelper.instance.title16SemiBoldPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    body,
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

    // ✅ Success body with better structure
    final confirmationLine = userEmail.isNotEmpty
        ? 'A confirmation email will be sent to $userEmail.'
        : 'A confirmation email will be sent to your account email.';

    final responseTimeLine = 'Responses usually come within 24 hours.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900,
        borderRadius: BorderRadius.circular(14.h),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 38.h,
            height: 38.h,
            decoration: BoxDecoration(
              color: accent.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22.h),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Title + Category badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyleHelper.instance.title16SemiBoldPlusJakartaSans
                            .copyWith(color: appTheme.gray_50),
                      ),
                    ),
                    _CategoryBadge(
                      label: categoryLabel,
                    ),
                  ],
                ),

                if (timestampText != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    timestampText,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300.withAlpha(180), height: 1.2),
                  ),
                ],

                SizedBox(height: 10.h),

                // Summary block
                Text(
                  confirmationLine,
                  style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                      .copyWith(color: appTheme.gray_50.withAlpha(235), height: 1.25),
                ),
                SizedBox(height: 6.h),
                Text(
                  responseTimeLine,
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

  Widget _buildSubmitButton(BuildContext context, {required FeatureRequestState state}) {
    final isLoading = state.isLoading;
    final isCompleted = state.isCompleted;

    return CustomButton(
      text: isCompleted ? 'Done' : (isLoading ? 'Submitting...' : 'Submit Request'),
      width: double.infinity,
      onPressed: isLoading
          ? null
          : () {
        if (isCompleted) {
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

  void onTapCloseButton(BuildContext context) {
    NavigatorService.goBack();
  }

  void onTapSubmitRequest(BuildContext context) {
    // ✅ Reset timestamp so each fresh submission shows the right time
    _submittedAtLocal = null;

    ref.read(featureRequestNotifier.notifier).submitFeatureRequest(
      category: _selectedCategory,
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 10.h),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                  .copyWith(color: textColor, height: 1.0),
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Category badge used on receipt card
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({Key? key, required this.label}) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    // subtle badge
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
      decoration: BoxDecoration(
        color: appTheme.deep_purple_A100.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyleHelper.instance.body14MediumPlusJakartaSans
            .copyWith(color: appTheme.gray_50, height: 1.0),
      ),
    );
  }
}
