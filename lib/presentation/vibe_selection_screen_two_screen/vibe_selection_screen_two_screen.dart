import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/vibe_selection_screen_two_notifier.dart';

class VibeSelectionScreenTwo extends ConsumerStatefulWidget {
  VibeSelectionScreenTwo({Key? key}) : super(key: key);

  @override
  VibeSelectionScreenTwoState createState() => VibeSelectionScreenTwoState();
}

class VibeSelectionScreenTwoState
    extends ConsumerState<VibeSelectionScreenTwo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vibeSelectionScreenTwoNotifier.notifier).initializeVibes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 24.h),
      decoration: BoxDecoration(
        color: appTheme.colorFF1E1E,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          SizedBox(height: 32.h),
          _buildVibesGrid(context),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              "Select a Vibe",
              style: TextStyleHelper.instance.title20BoldPlusJakartaSans,
            ),
            SizedBox(width: 8.h),
            Text(
              "🎵",
              style: TextStyleHelper.instance.title20,
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            onTapDone(context);
          },
          child: Text(
            "Done",
            style: TextStyleHelper.instance.title16SemiBoldPlusJakartaSans,
          ),
        ),
      ],
    );
  }

  /// Section Widget
  Widget _buildVibesGrid(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(vibeSelectionScreenTwoNotifier);

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16.h,
            mainAxisSpacing: 16.h,
            childAspectRatio: 1.0,
          ),
          itemCount: state.vibes.length,
          itemBuilder: (context, index) {
            final vibe = state.vibes[index];
            final isSelected = state.selectedVibeIndex == index;

            return GestureDetector(
              onTap: () {
                ref
                    .read(vibeSelectionScreenTwoNotifier.notifier)
                    .selectVibe(index);
              },
              child: Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: vibe.backgroundColor,
                  borderRadius: BorderRadius.circular(12.h),
                  border: isSelected
                      ? Border.all(color: appTheme.blue_A700, width: 2.h)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (vibe.isEmoji)
                      Text(
                        vibe.image,
                        style: TextStyleHelper.instance.headline32,
                      )
                    else
                      CustomImageView(
                        imagePath: vibe.image,
                        height: 40.h,
                        width: 40.h,
                        fit: BoxFit.cover,
                      ),
                    if (vibe.label.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        vibe.label,
                        style:
                            TextStyleHelper.instance.body12BoldPlusJakartaSans,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Handles the done button tap
  void onTapDone(BuildContext context) {
    final selectedVibe = ref.read(vibeSelectionScreenTwoNotifier).selectedVibe;
    if (selectedVibe != null) {
      // Close the bottom sheet and return the selected vibe
      Navigator.pop(context, selectedVibe);
    } else {
      Navigator.pop(context);
    }
  }
}
