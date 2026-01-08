import '../../core/app_export.dart';
import '../../core/utils/memory_nav_args.dart';
import '../../core/utils/navigator_service.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../theme/text_style_helper.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_header_row.dart';
import '../../widgets/custom_image_view.dart';
import './notifier/group_join_confirmation_notifier.dart';
import 'notifier/group_join_confirmation_notifier.dart';

class GroupJoinConfirmationScreen extends ConsumerStatefulWidget {
  const GroupJoinConfirmationScreen({Key? key}) : super(key: key);

  @override
  GroupJoinConfirmationScreenState createState() =>
      GroupJoinConfirmationScreenState();
}

class GroupJoinConfirmationScreenState
    extends ConsumerState<GroupJoinConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMemoryDetails();
    });
  }

  Future<void> _loadMemoryDetails() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null || args['memory_id'] == null) {
      print('❌ GROUP JOIN: No memory_id provided in arguments');
      _showError('Memory invitation not found');
      return;
    }

    final memoryId = args['memory_id'] as String;
    print('✅ GROUP JOIN: Loading memory details for: $memoryId');

    await ref
        .read(groupJoinConfirmationNotifier.notifier)
        .loadMemoryDetails(memoryId);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      // Navigate back to memories after error
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          NavigatorService.pushNamed(AppRoutes.appMemories);
        }
      });
    }
  }

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

        // Show loading state
        if (state.isLoading ?? false) {
          return Container(
            padding: EdgeInsets.all(40.h),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: appTheme.deep_purple_A100),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading memory details...',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),
          );
        }

        // Show error state
        if (state.errorMessage != null) {
          return Container(
            padding: EdgeInsets.all(40.h),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48.h),
                  SizedBox(height: 16.h),
                  Text(
                    state.errorMessage!,
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  CustomButton(
                    text: 'Go to Memories',
                    buttonStyle: CustomButtonStyle.fillPrimary,
                    buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                    onPressed: () {
                      NavigatorService.pushNamed(AppRoutes.appMemories);
                    },
                  ),
                ],
              ),
            ),
          );
        }

        // Show memory details and actions
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationHeader(context),
            SizedBox(height: 16.h),
            _buildMemoryDetails(context, state),
            SizedBox(height: 24.h),
            _buildActionButtons(context, state),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// Section Widget - Header
  Widget _buildConfirmationHeader(BuildContext context) {
    return CustomHeaderRow(
      title: "Memory Invitation",
      textAlignment: TextAlign.left,
      margin: EdgeInsets.symmetric(horizontal: 12.h, vertical: 18.h),
      onIconTap: () {
        onTapDecline(context);
      },
    );
  }

  /// Section Widget - Memory Details Card
  Widget _buildMemoryDetails(
      BuildContext context, GroupJoinConfirmationState state) {
    final memoryTitle = state.memoryTitle ?? 'Unknown Memory';
    final memoryCategory = state.memoryCategory ?? 'Event';
    final creatorName = state.creatorName ?? 'Unknown User';
    final expiresAt = state.expiresAt;
    final memberCount = state.memberCount ?? 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(
          color: appTheme.blue_gray_300.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory Icon
          Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: appTheme.deep_purple_A100.withAlpha(51),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Icon(
              Icons.event,
              color: appTheme.deep_purple_A100,
              size: 32.h,
            ),
          ),
          SizedBox(height: 16.h),

          // Memory Title
          Text(
            memoryTitle,
            style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          SizedBox(height: 8.h),

          // Creator Info
          Row(
            children: [
              CustomImageView(
                imagePath: state.creatorAvatar ?? '',
                height: 24.h,
                width: 24.h,
                radius: BorderRadius.circular(12.h),
                fit: BoxFit.cover,
              ),
              SizedBox(width: 8.h),
              Text(
                'Created by $creatorName',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Category Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
            decoration: BoxDecoration(
              color: appTheme.blue_gray_300.withAlpha(51),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Text(
              memoryCategory,
              style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
          SizedBox(height: 16.h),

          // Member Count
          Row(
            children: [
              Icon(Icons.people, color: appTheme.blue_gray_300, size: 18.h),
              SizedBox(width: 8.h),
              Text(
                '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ),

          // Expiration Time
          if (expiresAt != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.access_time,
                    color: appTheme.blue_gray_300, size: 18.h),
                SizedBox(width: 8.h),
                Text(
                  'Expires ${_formatTimestamp(expiresAt)}',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Section Widget - Action Buttons
  Widget _buildActionButtons(
      BuildContext context, GroupJoinConfirmationState state) {
    return Consumer(
      builder: (context, ref, _) {
        ref.listen(groupJoinConfirmationNotifier, (previous, current) {
          // Navigate to timeline on accept
          if (current.shouldNavigateToTimeline ?? false) {
            final memoryId = current.memoryId;
            if (memoryId != null) {
              print('✅ Navigating to timeline for memory: $memoryId');

              // Create MemoryNavArgs for timeline navigation
              final navArgs = MemoryNavArgs(
                memoryId: memoryId,
                snapshot: null,
              );

              NavigatorService.pushNamed(
                AppRoutes.appTimeline,
                arguments: navArgs,
              );
            }
          }

          // Navigate to memories on decline
          if (current.shouldNavigateToMemories ?? false) {
            print('✅ Navigating to memories after decline');
            NavigatorService.pushNamed(AppRoutes.appMemories);
          }
        });

        return Row(
          spacing: 12.h,
          children: [
            Expanded(
              child: CustomButton(
                text: 'Decline',
                buttonStyle: CustomButtonStyle.outlineDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                onPressed: () => onTapDecline(context),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Accept',
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                onPressed: (state.isAccepting ?? false)
                    ? null
                    : () => onTapAccept(context),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'expired';
    } else if (difference.inHours < 1) {
      return 'in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours} hours';
    } else {
      return 'in ${difference.inDays} days';
    }
  }

  /// Handle Accept button tap
  Future<void> onTapAccept(BuildContext context) async {
    print('🔵 Accept button pressed');
    await ref.read(groupJoinConfirmationNotifier.notifier).acceptInvitation();
  }

  /// Handle Decline button tap
  void onTapDecline(BuildContext context) {
    print('🔴 Decline button pressed');
    ref.read(groupJoinConfirmationNotifier.notifier).declineInvitation();
  }
}
