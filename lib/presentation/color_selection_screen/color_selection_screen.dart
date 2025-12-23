import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/color_selection_notifier.dart';

class ColorSelectionScreen extends ConsumerStatefulWidget {
  ColorSelectionScreen({Key? key}) : super(key: key);

  @override
  ColorSelectionScreenState createState() => ColorSelectionScreenState();
}

class ColorSelectionScreenState extends ConsumerState<ColorSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.color5B0000,
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(vertical: 18.h),
            child: Column(
              children: [
                _buildColorSelection(context),
                SizedBox(height: 10.h),
                _buildTypePrompt(context),
                SizedBox(height: 10.h),
                _buildThemeSelection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      layoutType: CustomAppBarLayoutType.spaceBetween,
      leadingIcon: ImageConstant.imgFrame19,
      title: 'Done',
      onLeadingTap: () {
        onTapBack(context);
      },
      titleTextStyle: TextStyleHelper.instance.title18BoldPlusJakartaSans
          .copyWith(color: appTheme.blue_A700),
      customHeight: 57.h,
      showBottomBorder: false,
    );
  }

  /// Section Widget
  Widget _buildColorSelection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h, left: 32.h, right: 32.h),
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(colorSelectionNotifier);
              final colors = state.colorSelectionModel?.colors ?? [];

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 12.h,
                  children: colors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final colorModel = entry.value;
                    final isSelected = state.selectedColorIndex == index;

                    return GestureDetector(
                      onTap: () {
                        onTapColorOption(index);
                      },
                      child: Container(
                        height: 42.h,
                        width: 42.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: appTheme.blue_A700, width: 2.h)
                              : null,
                        ),
                        child: CustomImageView(
                          imagePath: colorModel.imagePath,
                          height: 42.h,
                          width: 42.h,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildTypePrompt(BuildContext context) {
    return Text(
      'Type something...',
      style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
          .copyWith(color: appTheme.blue_gray_300),
    );
  }

  /// Section Widget
  Widget _buildThemeSelection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 18.h),
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(colorSelectionNotifier);
          final themes = state.colorSelectionModel?.themes ?? [];

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 12.h,
              children: themes.asMap().entries.map((entry) {
                final index = entry.key;
                final themeModel = entry.value;
                final isSelected = state.selectedThemeIndex == index;

                return GestureDetector(
                  onTap: () {
                    onTapThemeOption(index);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.h,
                      vertical: themeModel.title == 'typewriter'
                          ? 18.h
                          : (themeModel.title == 'neon' ? 16.h : 14.h),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          themeModel.title == 'typewriter' ? 22.h : 32.h),
                      color:
                          isSelected ? Color(0xFF0061FF) : appTheme.gray_900_01,
                      border: isSelected
                          ? Border.all(color: appTheme.blue_A700, width: 1.h)
                          : null,
                    ),
                    child: Text(
                      themeModel.title ?? '',
                      style: TextStyleHelper.instance.headline24
                          .copyWith(color: appTheme.gray_50),
                      textAlign: themeModel.title == 'typewriter'
                          ? TextAlign.center
                          : TextAlign.left,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  /// Handles back navigation
  void onTapBack(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles color selection
  void onTapColorOption(int index) {
    ref.read(colorSelectionNotifier.notifier).selectColor(index);
  }

  /// Handles theme selection
  void onTapThemeOption(int index) {
    ref.read(colorSelectionNotifier.notifier).selectTheme(index);
  }
}
