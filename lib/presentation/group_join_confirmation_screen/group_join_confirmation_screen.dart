import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_header_row.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_notification_card.dart';
import '../../widgets/custom_user_card.dart';
import '../../widgets/custom_user_profile_item.dart';
import 'notifier/group_join_confirmation_notifier.dart';

class GroupJoinConfirmationScreen extends ConsumerStatefulWidget {
  GroupJoinConfirmationScreen({Key? key}) : super(key: key);

  @override
  GroupJoinConfirmationScreenState createState() =>
      GroupJoinConfirmationScreenState();
}

class GroupJoinConfirmationScreenState
    extends ConsumerState<GroupJoinConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
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
              width: 40.h,
              height: 4.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF3A3A,
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),
            SizedBox(height: 20.h),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupJoinConfirmationNotifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationHeader(context),
            SizedBox(height: 16.h),
            _buildGroupDetails(context),
            SizedBox(height: 16.h),
            _buildActionButtons(context),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildConfirmationHeader(BuildContext context) {
    return CustomHeaderRow(
        title: "You're in!",
        textAlignment: TextAlign.left,
        margin: EdgeInsets.symmetric(horizontal: 12.h, vertical: 18.h),
        onIconTap: () {
          onTapCloseButton(context);
        });
  }

  /// Section Widget
  Widget _buildGroupDetails(BuildContext context) {
    return CustomNotificationCard(
        iconPath: ImageConstant.imgFrameDeepOrangeA700,
        title: 'Fmaily Xmas 2025',
        description: 'You have successfully joined Family Xmas 2025',
        isRead: true,
        onToggleRead: () {},
        margin: EdgeInsets.symmetric(horizontal: 46.h),
        onTap: () {});
  }

  /// Section Widget
  Widget _buildMembersSection(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.h),
        child: Row(children: [
          CustomImageView(
              imagePath: ImageConstant.imgIconBlueGray30018x18,
              height: 18.h,
              width: 18.h),
          SizedBox(width: 6.h),
          Text('Members',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300)),
        ]));
  }

  /// Section Widget
  Widget _buildMembersList(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(groupJoinConfirmationNotifier);

      return Column(spacing: 6.h, children: [
        CustomUserCard(
            userName: 'Ki Jones',
            profileImagePath: ImageConstant.imgEllipse826x26),
        CustomUserProfileItem(
            profileImagePath: ImageConstant.imgFrame2,
            userName: 'Dillon Brooks',
            onTap: () {
              onTapUserProfile(context);
            }),
        CustomUserProfileItem(
            profileImagePath: ImageConstant.imgFrame48x48,
            userName: 'Leslie Thomas',
            onTap: () {
              onTapUserProfile(context);
            }),
        CustomUserProfileItem(
            profileImagePath: ImageConstant.imgFrame1,
            userName: 'Kalvin Smith',
            onTap: () {
              onTapUserProfile(context);
            }),
      ]);
    });
  }

  /// Section Widget
  Widget _buildInfoText(BuildContext context) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Container(
            margin: EdgeInsets.only(left: 12.h),
            child: Text(
                'You can now start posting to the memory timeline. This memory has 12 hours remaining',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300, height: 1.21))));
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(groupJoinConfirmationNotifier);

      ref.listen(groupJoinConfirmationNotifier, (previous, current) {
        if (current.shouldNavigateToCreateMemory ?? false) {
          NavigatorService.pushNamed(AppRoutes.appPost);
        }
        if (current.shouldClose ?? false) {
          NavigatorService.pushNamed(AppRoutes.appPost);
        }
      });

      return Row(spacing: 12.h, children: [
        Expanded(
            child: CustomButton(
                text: 'Close',
                buttonStyle: CustomButtonStyle.fillDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                onPressed: () {
                  onTapCloseButton(context);
                })),
        Expanded(
            child: CustomButton(
                text: 'Create Story',
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                onPressed: () {
                  onTapCreateStory(context);
                })),
      ]);
    });
  }

  /// Navigates to the user profile screen
  void onTapUserProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  /// Handles close button tap
  void onTapCloseButton(BuildContext context) {
    ref.read(groupJoinConfirmationNotifier.notifier).onClosePressed();
  }

  /// Handles create story button tap
  void onTapCreateStory(BuildContext context) {
    ref.read(groupJoinConfirmationNotifier.notifier).onCreateStoryPressed();
  }
}
