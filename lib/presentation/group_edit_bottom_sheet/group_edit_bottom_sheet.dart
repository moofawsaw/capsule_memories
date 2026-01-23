import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../services/groups_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/custom_user_status_row.dart';
import '../groups_management_screen/models/groups_management_model.dart';
import 'notifier/group_edit_notifier.dart';

class GroupEditBottomSheet extends ConsumerStatefulWidget {
  final GroupModel group;
  final bool isReadOnlyMode;

  const GroupEditBottomSheet({
    Key? key,
    required this.group,
    this.isReadOnlyMode = false,
  }) : super(key: key);

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

    final currentUserId = SupabaseService.instance.client?.auth.currentUser?.id;
    if (currentUserId != null) {
      _myProfileFuture = _fetchMyProfileFromDb(currentUserId);
    }

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
    final currentUserId = SupabaseService.instance.client?.auth.currentUser?.id;
    final isCreator = currentUserId == widget.group.creatorId;

    // Show read-only mode for non-creators or when explicitly set
    if (widget.isReadOnlyMode || !isCreator) {
      return _buildReadOnlyView(context);
    }

    // Existing creator edit view
    return Container(
      width: double.infinity,
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
                physics: const BouncingScrollPhysics(),
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

  // ✅ Cache current user's DB profile fetch (used to inject creator as a member if missing)
  Future<Map<String, dynamic>?>? _myProfileFuture;

  Future<Map<String, dynamic>?> _fetchMyProfileFromDb(String userId) async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return null;

      // Pull from YOUR DB profile table (adjust column names if different)
      final res = await client
          .from('profiles')
          .select('id, display_name, username, avatar_url')
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;

      final avatar = (res['avatar_url'] as String?)?.trim();
      final displayName = (res['display_name'] as String?)?.trim();
      final username = (res['username'] as String?)?.trim();

      return <String, dynamic>{
        'id': userId,
        'name': (displayName != null && displayName.isNotEmpty)
            ? displayName
            : (username != null && username.isNotEmpty ? username : 'You'),
        'avatar': (avatar != null && avatar.isNotEmpty) ? avatar : null,
      };
    } catch (_) {
      return null;
    }
  }

  // ----------------------------
  // READ-ONLY VIEW (UPDATED)
  // ----------------------------

  Widget _buildReadOnlyView(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        // Key fix: ONLY maxHeight (no minHeight) so the sheet shrink-wraps
        // when content is short (removes the big whitespace).
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.h),
              topRight: Radius.circular(24.h),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(context),
              _buildReadOnlyHeader(context),

              // Flexible + loose fit: allows content to take only the space it needs
              // while still enabling scroll if it grows taller than maxHeight.
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 18.h),
                      _buildGroupTitleSection(context),
                      SizedBox(height: 18.h),
                      _buildCreationDateSection(context),
                      SizedBox(height: 18.h),
                      _buildJoinedOnSection(context),
                      SizedBox(height: 22.h),
                      _buildReadOnlyMembersSection(context),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),

              _buildLeaveGroupButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.h, 14.h, 16.h, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Group Details',
            style: TextStyleHelper.instance.title20ExtraBoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36.h,
              height: 36.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: appTheme.gray_50.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20.h,
                color: appTheme.gray_50.withAlpha(220),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTitleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Name',
          style: TextStyleHelper.instance.body14MediumPlusJakartaSans
              .copyWith(color: appTheme.gray_50.withAlpha(153)),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.group.name ?? 'Unnamed Group',
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
      ],
    );
  }

  Widget _buildCreationDateSection(BuildContext context) {
    final createdAt = widget.group.createdAt;
    final formattedDate = createdAt != null
        ? DateFormat('MMMM d, yyyy').format(createdAt)
        : 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Created On',
          style: TextStyleHelper.instance.body14MediumPlusJakartaSans
              .copyWith(color: appTheme.gray_50.withAlpha(153)),
        ),
        SizedBox(height: 8.h),
        Text(
          formattedDate,
          style: TextStyleHelper.instance.body16MediumPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
      ],
    );
  }

  /// Joined On: when the CURRENT USER joined this group.
  ///
  /// This looks for a join timestamp on the current user's member object coming
  /// from groupEditNotifier.currentMembers.
  ///
  /// Supported keys (first match wins):
  /// - joined_at / joinedAt
  /// - created_at / createdAt  (common if membership row uses created_at)
  Widget _buildJoinedOnSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupEditNotifier);
        final currentUserId =
            SupabaseService.instance.client?.auth.currentUser?.id;

        DateTime? joinedAt;

        if (currentUserId != null) {
          final me = state.currentMembers.firstWhere(
                (m) => m['id'] == currentUserId,
            orElse: () => <String, dynamic>{},
          );

          joinedAt = _parseAnyDateTime(
            me['joined_at'] ??
                me['joinedAt'] ??
                me['created_at'] ??
                me['createdAt'],
          );
        }

        final joinedText =
        joinedAt != null ? DateFormat('MMMM d, yyyy').format(joinedAt) : 'Unknown';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Joined On',
              style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                  .copyWith(color: appTheme.gray_50.withAlpha(153)),
            ),
            SizedBox(height: 8.h),
            Text(
              joinedText,
              style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ],
        );
      },
    );
  }

  DateTime? _parseAnyDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed;
    }
    return null;
  }

  Widget _buildReadOnlyMembersSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupEditNotifier);
        final currentUserId =
            SupabaseService.instance.client?.auth.currentUser?.id;

        if (state.isLoadingMembers) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: CircularProgressIndicator(color: appTheme.deep_purple_A100),
            ),
          );
        }

        final isCreator = currentUserId != null && currentUserId == widget.group.creatorId;

        final baseMembers = List<Map<String, dynamic>>.from(state.currentMembers);

        final hasMe = currentUserId != null &&
            baseMembers.any((m) => m['id'] == currentUserId);

        if (isCreator && currentUserId != null && !hasMe) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _myProfileFuture ?? _fetchMyProfileFromDb(currentUserId),
            builder: (context, snapshot) {
              final injected = List<Map<String, dynamic>>.from(baseMembers);

              final meProfile = snapshot.data;
              injected.add(<String, dynamic>{
                'id': currentUserId,
                'name': meProfile?['name'] ?? 'You',
                'avatar': meProfile?['avatar'],
              });

              return _buildMembersListUi(
                context: context,
                members: injected,
                currentUserId: currentUserId,
                showRemoveButtons: false,
              );
            },
          );
        }

        return _buildMembersListUi(
          context: context,
          members: baseMembers,
          currentUserId: currentUserId,
          showRemoveButtons: false,
        );
      },
    );
  }

  Widget _buildLeaveGroupButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(groupEditNotifier);

        return Container(
          width: double.infinity,
          color: appTheme.gray_900_02,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 1,
                color: appTheme.gray_50.withAlpha(26),
              ),
              Padding(
                padding: EdgeInsets.all(16.h),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: state.isSaving ? 'Leaving...' : 'Leave Group',
                    onPressed:
                    state.isSaving ? null : () => _handleLeaveGroup(context),
                    buttonStyle: CustomButtonStyle.fillRed,
                    buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------
  // EXISTING EDIT MODE UI
  // ----------------------------

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

        final isCreator = currentUserId != null && currentUserId == widget.group.creatorId;

        final baseMembers = List<Map<String, dynamic>>.from(state.currentMembers);

        final hasMe = currentUserId != null &&
            baseMembers.any((m) => m['id'] == currentUserId);

        // ✅ If creator is missing from members list (empty group), inject them from DB
        if (isCreator && currentUserId != null && !hasMe) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _myProfileFuture ?? _fetchMyProfileFromDb(currentUserId),
            builder: (context, snapshot) {
              final injected = List<Map<String, dynamic>>.from(baseMembers);

              final meProfile = snapshot.data;
              injected.add(<String, dynamic>{
                'id': currentUserId,
                'name': meProfile?['name'] ?? 'You',
                'avatar': meProfile?['avatar'],
              });

              return _buildMembersListUi(
                context: context,
                members: injected,
                currentUserId: currentUserId,
                showRemoveButtons: true,
              );
            },
          );
        }

        return _buildMembersListUi(
          context: context,
          members: baseMembers,
          currentUserId: currentUserId,
          showRemoveButtons: true,
        );
      },
    );
  }

  Widget _buildMembersListUi({
    required BuildContext context,
    required List<Map<String, dynamic>> members,
    required String? currentUserId,
    required bool showRemoveButtons,
  }) {
    // Sort members: Creator first, then current user (if not creator), then others
    final sortedMembers = List<Map<String, dynamic>>.from(members);
    sortedMembers.sort((a, b) {
      final aIsCreator = a['id'] == widget.group.creatorId;
      final bIsCreator = b['id'] == widget.group.creatorId;
      final aIsCurrentUser = a['id'] == currentUserId;
      final bIsCurrentUser = b['id'] == currentUserId;

      if (aIsCreator && !bIsCreator) return -1;
      if (!aIsCreator && bIsCreator) return 1;

      if (!aIsCreator && !bIsCreator) {
        if (aIsCurrentUser && !bIsCurrentUser) return -1;
        if (!aIsCurrentUser && bIsCurrentUser) return 1;
      }

      return 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Members (${sortedMembers.length})',
          style: TextStyleHelper.instance.body16MediumPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        SizedBox(height: 12.h),
        ...sortedMembers.map((member) {
          final isCreator = member['id'] == widget.group.creatorId;
          final isCurrentUser = member['id'] == currentUserId;

          String? statusText;
          if (isCreator && isCurrentUser) {
            statusText = 'Creator • You';
          } else if (isCreator) {
            statusText = 'Creator';
          } else if (isCurrentUser) {
            statusText = 'You';
          }

          final row = CustomUserStatusRow(
            profileImagePath: member['avatar']?.isNotEmpty == true
                ? member['avatar']
                : ImageConstant.imgEllipse826x26,
            userName: member['name'] ?? 'Unknown',
            statusText: statusText,
            statusBackgroundColor: (isCreator || isCurrentUser)
                ? appTheme.deep_purple_A100.withAlpha(51)
                : null,
            statusTextColor: (isCreator || isCurrentUser)
                ? appTheme.deep_purple_A100
                : null,
          );

          if (!showRemoveButtons) {
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              child: row,
            );
          }

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Expanded(child: row),
                if (!isCreator && !isCurrentUser) ...[
                  SizedBox(width: 8.h),
                  GestureDetector(
                    onTap: () => _showRemoveMemberDialog(
                      context,
                      member['id'],
                      member['name'],
                    ),
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
              ],
            ),
          );
        }).toList(),
      ],
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
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: CustomButton(
                  text: state.isSaving ? 'Saving...' : 'Save Changes',
                  onPressed:
                  state.isSaving ? null : () => _handleSaveChanges(context),
                  buttonStyle: CustomButtonStyle.fillSuccess,
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

  Future<void> _handleLeaveGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appTheme.gray_900_02,
        title: Text(
          'Leave Group',
          style: TextStyleHelper.instance.title18BoldPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        content: Text(
          'Are you sure you want to leave "${widget.group.name}"? You will need to be re-invited to join again.',
          style: TextStyleHelper.instance.body14RegularPlusJakartaSans
              .copyWith(color: appTheme.gray_50),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Leave',
              style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                  .copyWith(color: appTheme.red_500),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(groupEditNotifier.notifier).setLoading(true);

      final success = await GroupsService.leaveGroup(widget.group.id ?? '');

      if (mounted) {
        ref.read(groupEditNotifier.notifier).setLoading(false);

        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have left the group'),
              backgroundColor: appTheme.deep_purple_A100,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to leave group. Please try again.'),
              backgroundColor: appTheme.red_500,
            ),
          );
        }
      }
    }
  }
}
