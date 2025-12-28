import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import '../groups_management_screen/models/groups_management_model.dart';
import 'notifier/group_edit_notifier.dart';

class GroupEditBottomSheet extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupEditBottomSheet({Key? key, required this.group}) : super(key: key);

  @override
  GroupEditBottomSheetState createState() => GroupEditBottomSheetState();
}

class GroupEditBottomSheetState extends ConsumerState<GroupEditBottomSheet> {
  TextEditingController groupNameController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    groupNameController.text = widget.group.name ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupEditNotifier.notifier).initialize(widget.group);
    });
  }

  @override
  void dispose() {
    groupNameController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.h),
          topRight: Radius.circular(24.h),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(context),
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    _buildGroupNameSection(context),
                    SizedBox(height: 24.h),
                    _buildCurrentMembersSection(context),
                    SizedBox(height: 24.h),
                    _buildAddMembersSection(context),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      width: 48.h,
      height: 4.h,
      decoration: BoxDecoration(
        color: appTheme.gray_50.withAlpha(77),
        borderRadius: BorderRadius.circular(2.h),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.h, 16.h, 16.h, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Edit Group',
            style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: CustomImageView(
              imagePath: ImageConstant.imgIcon14x14,
              height: 24.h,
              width: 24.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupNameSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Name',
          style: TextStyleHelper.instance.body16MediumPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 8.h),
        CustomEditText(
          controller: groupNameController,
          hintText: 'Enter group name',
        ),
        SizedBox(height: 4.h),
        Text(
          '${groupNameController.text.length}/50 characters',
          style: TextStyleHelper.instance.body12MediumPlusJakartaSans
              .copyWith(color: appTheme.gray_50.withAlpha(153)),
        ),
      ],
    );
  }

  Widget _buildCurrentMembersSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupEditNotifier);
        final currentUserId =
            SupabaseService.instance.client?.auth.currentUser?.id;

        if (state.isLoadingMembers) {
          return Center(
            child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members (${state.currentMembers.length})',
              style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            SizedBox(height: 12.h),
            ...state.currentMembers.map((member) {
              final isCreator = member['id'] == widget.group.creatorId;
              final isCurrentUser = member['id'] == currentUserId;

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: appTheme.gray_50.withAlpha(13),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.h,
                      height: 40.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            member['avatar']?.isNotEmpty == true
                                ? member['avatar']
                                : 'https://via.placeholder.com/150',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.h),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member['name'] ?? 'Unknown',
                                style: TextStyleHelper
                                    .instance.body14MediumPlusJakartaSans
                                    .copyWith(color: appTheme.gray_50),
                              ),
                              if (isCreator)
                                Container(
                                  margin: EdgeInsets.only(left: 8.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.h,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: appTheme.deep_purple_A100,
                                    borderRadius: BorderRadius.circular(4.h),
                                  ),
                                  child: Text(
                                    'Creator',
                                    style: TextStyleHelper
                                        .instance.body10BoldPlusJakartaSans
                                        .copyWith(color: appTheme.gray_50),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            '@${member['username'] ?? ''}',
                            style: TextStyleHelper
                                .instance.body12MediumPlusJakartaSans
                                .copyWith(
                                    color: appTheme.gray_50.withAlpha(153)),
                          ),
                        ],
                      ),
                    ),
                    if (!isCreator && !isCurrentUser)
                      GestureDetector(
                        onTap: () => _showRemoveMemberDialog(
                            context, member['id'], member['name']),
                        child: Container(
                          padding: EdgeInsets.all(6.h),
                          decoration: BoxDecoration(
                            color: appTheme.red_500.withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: appTheme.red_500,
                            size: 18.h,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildAddMembersSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupEditNotifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Members',
              style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            SizedBox(height: 12.h),
            CustomSearchView(
              controller: searchController,
              placeholder: 'Search by name...',
              onChanged: (value) {
                ref.read(groupEditNotifier.notifier).searchFriends(value);
              },
            ),
            SizedBox(height: 12.h),
            if (state.isLoadingFriends)
              Center(
                child:
                    CircularProgressIndicator(color: appTheme.deep_purple_A100),
              )
            else if (state.availableFriends.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16.h),
                  child: Text(
                    searchController.text.isEmpty
                        ? 'All friends are already members'
                        : 'No friends found',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.gray_50.withAlpha(153)),
                  ),
                ),
              )
            else
              ...state.availableFriends.map((friend) {
                final isSelected = state.selectedFriendsToAdd
                    .any((f) => f['id'] == friend['id']);

                return GestureDetector(
                  onTap: () => ref
                      .read(groupEditNotifier.notifier)
                      .toggleFriendSelection(friend),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? appTheme.deep_purple_A100.withAlpha(26)
                          : appTheme.gray_50.withAlpha(13),
                      borderRadius: BorderRadius.circular(12.h),
                      border: Border.all(
                        color: isSelected
                            ? appTheme.deep_purple_A100
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.h,
                          height: 40.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                friend['avatar_url']?.isNotEmpty == true
                                    ? friend['avatar_url']
                                    : 'https://via.placeholder.com/150',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.h),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend['display_name'] ?? 'Unknown',
                                style: TextStyleHelper
                                    .instance.body14MediumPlusJakartaSans
                                    .copyWith(color: appTheme.gray_50),
                              ),
                              Text(
                                '@${friend['username'] ?? ''}',
                                style: TextStyleHelper
                                    .instance.body12MediumPlusJakartaSans
                                    .copyWith(
                                        color: appTheme.gray_50.withAlpha(153)),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: appTheme.deep_purple_A100,
                            size: 24.h,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupEditNotifier);

        return Container(
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            border: Border(
              top: BorderSide(
                color: appTheme.gray_50.withAlpha(26),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: CustomButton(
                  text: state.isSaving ? 'Saving...' : 'Save Changes',
                  onPressed:
                      state.isSaving ? null : () => _handleSaveChanges(context),
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveMemberDialog(
      BuildContext context, String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.gray_900_02,
        title: Text(
          'Remove Member',
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        content: Text(
          'Are you sure you want to remove $memberName from this group?',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(groupEditNotifier.notifier).removeMember(memberId);
            },
            child: Text(
              'Remove',
              style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                  .copyWith(color: appTheme.red_500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveChanges(BuildContext context) async {
    final success = await ref
        .read(groupEditNotifier.notifier)
        .saveChanges(groupNameController.text);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group updated successfully'),
          backgroundColor: appTheme.deep_purple_A100,
        ),
      );
    }
  }
}
