import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import 'notifier/memory_invitation_notifier.dart';

class MemoryInvitationScreen extends ConsumerStatefulWidget {
  MemoryInvitationScreen({Key? key}) : super(key: key);

  @override
  MemoryInvitationScreenState createState() => MemoryInvitationScreenState();
}

class MemoryInvitationScreenState
    extends ConsumerState<MemoryInvitationScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appTheme.deep_purple_A100.withAlpha(77),
              appTheme.gray_900_02,
            ],
          ),
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
        final state = ref.watch(memoryInvitationNotifier);
        final model = state.memoryInvitationModel;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            _buildMemoryIcon(),
            SizedBox(height: 24.h),
            _buildMemoryTitle(model?.memoryTitle ?? "Fmaily Xmas 2025"),
            SizedBox(height: 12.h),
            _buildInvitationMessage(model?.invitationMessage ??
                "You've been invited to join this memory"),
            SizedBox(height: 32.h),
            _buildCreatorProfile(
              model?.creatorName ?? "Jane Doe",
              model?.creatorImage ??
                  "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg",
            ),
            SizedBox(height: 32.h),
            _buildStatsRow(
              model?.membersCount ?? 2,
              model?.storiesCount ?? 0,
              model?.status ?? "Open",
            ),
            SizedBox(height: 40.h),
            _buildJoinButton(context),
            SizedBox(height: 16.h),
            _buildHelperText(),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// Memory icon at the top
  Widget _buildMemoryIcon() {
    return Container(
      width: 80.h,
      height: 80.h,
      decoration: BoxDecoration(
        color: appTheme.deep_purple_A100.withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.photo_library_rounded,
        size: 40.h,
        color: appTheme.deep_purple_A100,
      ),
    );
  }

  /// Memory title
  Widget _buildMemoryTitle(String title) {
    return Text(
      title,
      style:
          TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans.copyWith(
        color: appTheme.white_A700,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Invitation message
  Widget _buildInvitationMessage(String message) {
    return Text(
      message,
      style: TextStyleHelper.instance.title16RegularPlusJakartaSans.copyWith(
        color: appTheme.blue_gray_300,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Creator profile section
  Widget _buildCreatorProfile(String name, String imageUrl) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32.h,
          backgroundImage: NetworkImage(imageUrl),
          backgroundColor: appTheme.blue_gray_300,
        ),
        SizedBox(height: 12.h),
        Text(
          name,
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans.copyWith(
            color: appTheme.white_A700,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Creator',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
            color: appTheme.blue_gray_300,
          ),
        ),
      ],
    );
  }

  /// Stats row (Members, Stories, Status)
  Widget _buildStatsRow(int members, int stories, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(members.toString(), 'Members'),
        Container(
          width: 1.h,
          height: 40.h,
          color: appTheme.blue_gray_300.withAlpha(77),
        ),
        _buildStatItem(stories.toString(), 'Stories'),
        Container(
          width: 1.h,
          height: 40.h,
          color: appTheme.blue_gray_300.withAlpha(77),
        ),
        _buildStatItem(status, 'Status'),
      ],
    );
  }

  /// Individual stat item
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyleHelper.instance.headline24ExtraBoldPlusJakartaSans
              .copyWith(
            color: appTheme.white_A700,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
            color: appTheme.blue_gray_300,
          ),
        ),
      ],
    );
  }

  /// Join Memory button
  Widget _buildJoinButton(BuildContext context) {
    return CustomButton(
      text: 'Join Memory',
      onPressed: () => onTapJoinMemory(context),
      buttonStyle: CustomButtonStyle.fillPrimary,
      buttonTextStyle: CustomButtonTextStyle.bodyMedium,
    );
  }

  /// Helper text at the bottom
  Widget _buildHelperText() {
    return Text(
      "You'll be able to add your own stories",
      style: TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
        color: appTheme.blue_gray_300,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Navigates to user profile when the user card is tapped
  void onTapUserProfile(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appProfile);
  }

  /// Handles joining the memory invitation
  void onTapJoinMemory(BuildContext context) {
    final notifier = ref.read(memoryInvitationNotifier.notifier);
    notifier.joinMemory();

    // Listen for success state and navigate
    ref.listen(memoryInvitationNotifier, (previous, current) {
      if (current.isJoined ?? false) {
        NavigatorService.pushNamed(AppRoutes.appMemories);
      }
    });
  }
}