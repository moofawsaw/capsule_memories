import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_music_list.dart';
import 'notifier/vibe_selection_notifier.dart';

class VibeSelectionScreen extends ConsumerStatefulWidget {
  VibeSelectionScreen({Key? key}) : super(key: key);

  @override
  VibeSelectionScreenState createState() => VibeSelectionScreenState();
}

class VibeSelectionScreenState extends ConsumerState<VibeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vibeSelectionNotifier.notifier).initialize();
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

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
                  _buildHeaderSection(context),
                  SizedBox(height: 30.h),
                  _buildVibeTabSection(context),
                  SizedBox(height: 50.h),
                  SizedBox(
                    height: 300.h,
                    child: _buildMusicListSection(context),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header with title and done button
  Widget _buildHeaderSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.h),
      child: Row(
        children: [
          Text(
            'Select a Vibe',
            style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          SizedBox(width: 14.h),
          CustomImageView(
            imagePath: ImageConstant.imgIconGray5026x26,
            width: 26.h,
            height: 26.h,
          ),
          Spacer(),
          GestureDetector(
            onTap: () => onTapDone(context),
            child: Text(
              'Done',
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.blue_A700),
            ),
          ),
        ],
      ),
    );
  }

  /// Vibe selection tabs
  Widget _buildVibeTabSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22.h),
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(vibeSelectionNotifier);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVibeTab(
                context: context,
                imagePath: ImageConstant.imgGroup,
                label: 'Fun',
                backgroundColor: appTheme.deep_purple_A100,
                isSelected: state.selectedVibeIndex == 0,
                onTap: () => onTapVibeOption(context, 0),
              ),
              _buildVibeTab(
                context: context,
                imagePath: ImageConstant.imgGroupOrange600,
                label: 'Crazy',
                backgroundColor: appTheme.color41C124,
                isSelected: state.selectedVibeIndex == 1,
                onTap: () => onTapVibeOption(context, 1),
              ),
              _buildVibeTab(
                context: context,
                imagePath: ImageConstant.imgGroupOrange60034x36,
                label: 'Sexy',
                backgroundColor: appTheme.color41C124,
                isSelected: state.selectedVibeIndex == 2,
                onTap: () => onTapVibeOption(context, 2),
              ),
              _buildVibeTab(
                context: context,
                imagePath: ImageConstant.imgGroup34x36,
                label: 'Cute',
                backgroundColor: appTheme.color41C124,
                isSelected: state.selectedVibeIndex == 3,
                onTap: () => onTapVibeOption(context, 3),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Individual vibe tab
  Widget _buildVibeTab({
    required BuildContext context,
    required String imagePath,
    required String label,
    required Color backgroundColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? backgroundColor : backgroundColor.withAlpha(77),
          borderRadius: BorderRadius.circular(8.h),
          border: isSelected
              ? Border.all(color: appTheme.colorFF52D1, width: 2.h)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomImageView(
              imagePath: imagePath,
              width: 36.h,
              height: 36.h,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                  .copyWith(
                      color: isSelected ? Color(0xFFFFFFFF) : appTheme.gray_50),
            ),
          ],
        ),
      ),
    );
  }

  /// Music list section
  Widget _buildMusicListSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.h),
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(vibeSelectionNotifier);

          return CustomMusicList(
            items: state.vibeSelectionModel?.musicItems ?? [],
            onItemTap: (index, item) => onTapMusicItem(context, index),
            onPlayTap: (index, item) => onTapPlayButton(context, index),
            itemSpacing: 46.h,
          );
        },
      ),
    );
  }

  /// Navigate back or complete selection
  void onTapDone(BuildContext context) {
    final notifier = ref.read(vibeSelectionNotifier.notifier);
    notifier.completeVibeSelection();
    NavigatorService.goBack();
  }

  /// Handle vibe option selection
  void onTapVibeOption(BuildContext context, int index) {
    ref.read(vibeSelectionNotifier.notifier).selectVibe(index);
  }

  /// Handle music item tap
  void onTapMusicItem(BuildContext context, int index) {
    ref.read(vibeSelectionNotifier.notifier).selectMusic(index);
  }

  /// Handle play button tap
  void onTapPlayButton(BuildContext context, int index) {
    ref.read(vibeSelectionNotifier.notifier).togglePlayMusic(index);
  }
}
