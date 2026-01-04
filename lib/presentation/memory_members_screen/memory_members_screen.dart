import '../../core/app_export.dart';
import '../../widgets/custom_user_status_row.dart';
import 'notifier/memory_members_notifier.dart';

class MemoryMembersScreen extends ConsumerStatefulWidget {
  final String? memoryId;
  final String? memoryTitle;

  const MemoryMembersScreen({
    Key? key,
    this.memoryId,
    this.memoryTitle,
  }) : super(key: key);

  @override
  MemoryMembersScreenState createState() => MemoryMembersScreenState();
}

class MemoryMembersScreenState extends ConsumerState<MemoryMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize with memory ID passed to the screen
      if (widget.memoryId != null) {
        ref.read(memoryMembersNotifier.notifier).initialize(
              widget.memoryId!,
              memoryTitle: widget.memoryTitle,
            );
      }
    });
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
        final state = ref.watch(memoryMembersNotifier);
        final model = state.memoryMembersModel;

        return Column(
          children: [
            _buildHeaderSection(context),
            SizedBox(height: 16.h),

            // Loading state
            if (model?.isLoading == true)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: CircularProgressIndicator(
                  color: appTheme.deep_purple_A100,
                ),
              ),

            // Error state
            if (model?.errorMessage != null && model?.isLoading == false)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  model!.errorMessage!,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.red_500),
                ),
              ),

            // Members list
            if (model?.isLoading == false && model?.errorMessage == null)
              _buildMembersList(context),

            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildHeaderSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryMembersNotifier);
        final model = state.memoryMembersModel;
        final memberCount = model?.members?.length ?? 0;
        final groupName = model?.groupName;

        return Container(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name section (if memory was created from a group)
              if (groupName != null && groupName.isNotEmpty)
                GestureDetector(
                  onTap: () => _navigateToGroups(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.h,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: appTheme.deep_purple_A100.withAlpha(26),
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 16.h,
                          color: appTheme.deep_purple_A100,
                        ),
                        SizedBox(width: 6.h),
                        Text(
                          groupName,
                          style: TextStyleHelper
                              .instance.body14RegularPlusJakartaSans
                              .copyWith(
                            color: appTheme.deep_purple_A100,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.h),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12.h,
                          color: appTheme.deep_purple_A100,
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: groupName != null ? 12.h : 0),

              Text(
                'Memory Members',
                style: TextStyleHelper
                    .instance.headline24ExtraBoldPlusJakartaSans
                    .copyWith(height: 1.29),
              ),
              if (memberCount > 0)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50.withAlpha(153)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Navigate to groups screen
  void _navigateToGroups(BuildContext context) {
    // Close the bottom sheet first
    Navigator.of(context).pop();

    // Navigate to groups management screen
    NavigatorService.pushNamed(AppRoutes.appGroups);
  }

  /// Section Widget
  Widget _buildMembersList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryMembersNotifier);
        final members = state.memoryMembersModel?.members ?? [];

        if (members.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Text(
              'No members found',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50.withAlpha(153)),
            ),
          );
        }

        return Column(
          spacing: 10.h,
          children: members.map((member) {
            final isCreator = member.isCreator ?? false;

            return CustomUserStatusRow(
              profileImagePath:
                  member.avatarUrl ?? ImageConstant.imgEllipse826x26,
              userName: member.displayName ?? member.username ?? 'Unknown',
              statusText: isCreator ? 'Creator' : null,
              statusBackgroundColor:
                  isCreator ? appTheme.deep_purple_A100.withAlpha(51) : null,
              statusTextColor: isCreator ? appTheme.deep_purple_A100 : null,
              onTap: () => _onTapMember(context, member.userId ?? ''),
            );
          }).toList(),
        );
      },
    );
  }

  /// Handle member tap
  void _onTapMember(BuildContext context, String memberId) {
    ref.read(memoryMembersNotifier.notifier).selectMember(memberId);

    // Close the bottom sheet first
    Navigator.of(context).pop();

    // Navigate to user profile with userId
    NavigatorService.pushNamed(
      AppRoutes.appProfileUser,
      arguments: {'userId': memberId},
    );
  }
}