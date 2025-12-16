import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_icon_button.dart';
import 'notifier/friends_management_notifier.dart';
import 'widgets/friends_section_widget.dart';
import 'widgets/sent_requests_section_widget.dart';
import 'widgets/incoming_requests_section_widget.dart';

class FriendsManagementScreen extends ConsumerStatefulWidget {
  const FriendsManagementScreen({Key? key}) : super(key: key);

  @override
  FriendsManagementScreenState createState() => FriendsManagementScreenState();
}

class FriendsManagementScreenState
    extends ConsumerState<FriendsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsManagementNotifier.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            backgroundColor: appTheme.gray_900_02,
            body: Container(
                width: double.infinity,
                child: Column(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          child: Column(spacing: 24.h, children: [
                    _buildHeaderSection(context),
                    _buildMainContentSection(context),
                  ]))),
                ]))));
  }

  /// Header section with logo, actions and profile
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
        padding:
            EdgeInsets.only(top: 26.h, left: 22.h, right: 22.h, bottom: 24.h),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: appTheme.blue_gray_900, width: 1.h))),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                  width: 130.h,
                  height: 26.h,
                  margin: EdgeInsets.only(bottom: 10.h),
                  child: CustomImageView(
                      imagePath: ImageConstant.imgLogo, fit: BoxFit.contain)),
              SizedBox(width: 18.h),
              CustomIconButton(
                  iconPath: ImageConstant.imgFrame19,
                  backgroundColor: appTheme.color3BD81E,
                  borderRadius: 22.h,
                  height: 46.h,
                  width: 46.h,
                  padding: EdgeInsets.all(6.h),
                  onTap: () => onTapAddButton(context)),
              SizedBox(width: 18.h),
              GestureDetector(
                  onTap: () => onTapNotificationIcon(context),
                  child: Container(
                      width: 32.h,
                      height: 32.h,
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: CustomImageView(
                          imagePath: ImageConstant.imgIconGray50,
                          fit: BoxFit.contain))),
              SizedBox(width: 6.h),
              GestureDetector(
                  onTap: () => onTapNotificationBell(context),
                  child: Container(
                      width: 32.h,
                      height: 32.h,
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: CustomImageView(
                          imagePath: ImageConstant.imgIconGray5032x32,
                          fit: BoxFit.contain))),
              SizedBox(width: 8.h),
              GestureDetector(
                  onTap: () => onTapProfileImage(context),
                  child: Container(
                      width: 50.h,
                      height: 50.h,
                      margin: EdgeInsets.only(top: 22.h),
                      child: CustomImageView(
                          imagePath: ImageConstant.imgEllipse8,
                          fit: BoxFit.cover))),
            ]));
  }

  /// Main content section with friends management
  Widget _buildMainContentSection(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: 16.h, right: 20.h, bottom: 14.h),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildFriendsHeaderSection(context),
          SizedBox(height: 16.h),
          _buildSearchSection(context),
          SizedBox(height: 20.h),
          FriendsSectionWidget(),
          SizedBox(height: 20.h),
          SentRequestsSectionWidget(),
          SizedBox(height: 20.h),
          IncomingRequestsSectionWidget(),
        ]));
  }

  /// Friends header with count and action buttons
  Widget _buildFriendsHeaderSection(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(right: 6.h),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 26.h,
              height: 26.h,
              margin: EdgeInsets.only(top: 2.h),
              child: CustomImageView(
                  imagePath: ImageConstant.imgIconDeepPurpleA100,
                  fit: BoxFit.contain)),
          SizedBox(width: 6.h),
          Container(
              margin: EdgeInsets.only(top: 2.h),
              child: Text('Friends (2)',
                  style: TextStyleHelper
                      .instance.title20ExtraBoldPlusJakartaSans)),
          Expanded(
              child: Container(
                  alignment: Alignment.centerRight,
                  child: CustomIconButtonRow(
                      firstIconPath: ImageConstant.imgButtons,
                      secondIconPath: ImageConstant.imgButtonsGray50,
                      onFirstIconTap: () => onTapQRScanButton(context),
                      onSecondIconTap: () => onTapCameraButton(context)))),
        ]));
  }

  /// Search section
  Widget _buildSearchSection(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(friendsManagementNotifier);

      return Container(
          margin: EdgeInsets.only(left: 4.h),
          child: CustomSearchView(
              controller: state.searchController,
              placeholder: 'Search for friends...',
              onChanged: (value) {
                ref
                    .read(friendsManagementNotifier.notifier)
                    .onSearchChanged(value);
              }));
    });
  }

  /// Navigate to add content
  void onTapAddButton(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.createMemoryScreen);
  }

  /// Navigate to notifications
  void onTapNotificationIcon(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }

  /// Navigate to notifications
  void onTapNotificationBell(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.notificationsScreen);
  }

  /// Navigate to profile
  void onTapProfileImage(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.userProfileScreen);
  }

  /// Handle QR scan action
  void onTapQRScanButton(BuildContext context) {
    ref.read(friendsManagementNotifier.notifier).onQRScanTap();
  }

  /// Handle camera action
  void onTapCameraButton(BuildContext context) {
    ref.read(friendsManagementNotifier.notifier).onCameraTap();
  }
}
