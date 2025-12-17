import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/utils/vibe_categories.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/vibe_selection_screen_two_notifier.dart';

class VibeSelectionScreenTwoScreen extends ConsumerStatefulWidget {
  VibeSelectionScreenTwoScreen({Key? key}) : super(key: key);

  @override
  VibeSelectionScreenTwoScreenState createState() =>
      VibeSelectionScreenTwoScreenState();
}

class VibeSelectionScreenTwoScreenState
    extends ConsumerState<VibeSelectionScreenTwoScreen> {
  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  CustomHeaderSection(
                    title: 'Select a Vibe',
                    description:
                        'Choose music and stickers that match your mood',
                    margin: EdgeInsets.only(left: 10.h, right: 10.h),
                  ),
                  SizedBox(height: 30.h),
                  _buildVibeGrid(context),
                  SizedBox(height: 30.h),
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

  /// Build vibe grid with 4 categories
  Widget _buildVibeGrid(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(vibeSelectionScreenTwoNotifier);
        final selectedVibe = state.selectedCategory;

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.h,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.2,
          ),
          itemCount: VibeCategories.all.length,
          itemBuilder: (context, index) {
            final vibe = VibeCategories.all[index];
            final isSelected = selectedVibe == vibe.name;

            return _buildVibeCard(
              context,
              vibe: vibe,
              isSelected: isSelected,
              onTap: () {
                ref
                    .read(vibeSelectionScreenTwoNotifier.notifier)
                    .selectCategory(vibe.name);
              },
            );
          },
        );
      },
    );
  }

  /// Build individual vibe card
  Widget _buildVibeCard(
    BuildContext context, {
    required VibeCategory vibe,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? appTheme.deep_purple_A100
              : appTheme.gray_900.withAlpha(128),
          borderRadius: BorderRadius.circular(12.h),
          border: isSelected
              ? Border.all(color: appTheme.colorFF52D1, width: 2.h)
              : Border.all(
                  color: appTheme.blue_gray_300.withAlpha(77), width: 1.h),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Vibe icon image
            CustomImageView(
              imagePath: vibe.imagePath,
              width: 48.h,
              height: 48.h,
            ),
            SizedBox(height: 12.h),
            // Vibe name
            Text(
              vibe.name,
              style:
                  TextStyleHelper.instance.body16BoldPlusJakartaSans.copyWith(
                color: isSelected ? appTheme.gray_50 : appTheme.blue_gray_300,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            // Description
            Text(
              vibe.description,
              style:
                  TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
                color: isSelected
                    ? appTheme.gray_50.withAlpha(204)
                    : appTheme.blue_gray_300.withAlpha(153),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(vibeSelectionScreenTwoNotifier);

        return Container(
          width: double.infinity,
          child: Row(
            spacing: 12.h,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Back',
                  onPressed: () {
                    NavigatorService.goBack();
                  },
                  buttonStyle: CustomButtonStyle.fillDark,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Continue',
                  onPressed: state.selectedCategory != null
                      ? () {
                          ref
                              .read(vibeSelectionScreenTwoNotifier.notifier)
                              .onContinuePressed();
                        }
                      : null,
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  isDisabled: state.selectedCategory == null,
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
