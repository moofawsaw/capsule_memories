import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_header_section.dart';
import '../../services/groups_service.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_settings_row.dart';
import 'notifier/create_memory_notifier.dart';

class CreateMemoryScreen extends ConsumerStatefulWidget {
  final String? preSelectedCategoryId;

  CreateMemoryScreen({Key? key, this.preSelectedCategoryId}) : super(key: key);

  @override
  CreateMemoryScreenState createState() => CreateMemoryScreenState();
}

class _SelectedGroupMemberAvatars extends StatelessWidget {
  final String groupId;

  /// Expected shape from GroupsService.fetchGroupMembers:
  /// [{ 'id': userId, 'avatar': url, ... }]
  final List<Map<String, dynamic>> members;

  const _SelectedGroupMemberAvatars({
    required this.groupId,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer already-loaded member list (fast, no async)
    final avatarsFromState = <String>[];
    for (final m in members) {
      final a = (m['avatar'] as String?)?.trim();
      if (a != null && a.isNotEmpty) avatarsFromState.add(a);
      if (avatarsFromState.length >= 3) break;
    }

    // If we have avatars already, render immediately
    if (avatarsFromState.isNotEmpty) {
      final totalCount = members.length;
      return _AvatarStack(
        avatars: avatarsFromState,
        totalCount: totalCount,
      );
    }

    // Fallback: fetch just avatars (in case groupMembers not loaded yet)
    return FutureBuilder<List<String>>(
      future: GroupsService.fetchGroupMemberAvatars(groupId, limit: 3),
      builder: (context, snapshot) {
        final avatars = snapshot.data ?? const <String>[];
        if (avatars.isEmpty) {
          return SizedBox(height: 22.h, width: 54.h);
        }

        // Unknown total count in this fallback; don’t show +N bubble.
        return _AvatarStack(
          avatars: avatars,
          totalCount: null,
        );
      },
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> avatars;
  final int? totalCount;

  const _AvatarStack({
    required this.avatars,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final int shown = avatars.length;
    final int extra =
        (totalCount != null && totalCount! > shown) ? (totalCount! - shown) : 0;

    final double size = 22.h;
    final double overlap = 14.h;

    final double baseWidth = size + (shown - 1) * overlap;
    final double extraWidth = extra > 0 ? (overlap + size) : 0;
    final double totalWidth = baseWidth + extraWidth;

    return SizedBox(
      height: size,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < shown; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                height: size,
                width: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appTheme.gray_900_02,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageView(
                    imagePath: avatars[i],
                    height: size,
                    width: size,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown * overlap,
              child: Container(
                height: size,
                width: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appTheme.gray_900,
                  border: Border.all(
                    color: appTheme.gray_900_02,
                    width: 2,
                  ),
                ),
                child: Text(
                  '+$extra',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(
                    color: appTheme.blue_gray_300,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Uses the already-loaded groupMembers list (fast, no async)
/// Expected member shape: { 'avatar': 'https://...', ... }
class _AvatarStackFromMembers extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final int? totalCount;

  const _AvatarStackFromMembers({
    required this.members,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    // Pull up to 3 avatars from loaded members
    final avatars = <String>[];
    for (final m in members) {
      final a = (m['avatar'] as String?)?.trim();
      if (a != null && a.isNotEmpty) avatars.add(a);
      if (avatars.length >= 3) break;
    }

    // If members not loaded yet, keep layout stable
    if (avatars.isEmpty) {
      return SizedBox(height: 22.h, width: 54.h);
    }

    final int shown = avatars.length;
    final int extra =
        (totalCount != null && totalCount! > shown) ? (totalCount! - shown) : 0;

    final double size = 22.h;
    final double overlap = 14.h;

    final double baseWidth = size + (shown - 1) * overlap;
    final double extraWidth = extra > 0 ? (overlap + size) : 0;
    final double totalWidth = baseWidth + extraWidth;

    return SizedBox(
      height: size,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < shown; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                height: size,
                width: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: appTheme.gray_900_02,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageView(
                    imagePath: avatars[i],
                    height: size,
                    width: size,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown * overlap,
              child: Container(
                height: size,
                width: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appTheme.gray_900,
                  border: Border.all(
                    color: appTheme.gray_900_02,
                    width: 2,
                  ),
                ),
                child: Text(
                  '+$extra',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(
                    color: appTheme.blue_gray_300,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupMemberAvatars extends StatelessWidget {
  final String groupId;
  final int memberCount;

  const _GroupMemberAvatars({
    required this.groupId,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: GroupsService.fetchGroupMemberAvatars(groupId, limit: 3),
      builder: (context, snapshot) {
        final avatars = snapshot.data ?? const <String>[];

        if (avatars.isEmpty) {
          // keep spacing consistent even if no avatars yet
          return SizedBox(height: 22.h, width: 54.h);
        }

        final int shown = avatars.length;
        final int extra = (memberCount > shown) ? (memberCount - shown) : 0;

        // Overlap amount
        final double size = 22.h;
        final double overlap = 14.h;

        // total width = first avatar + (n-1)*overlap + optional +N bubble width
        final double baseWidth = size + (shown - 1) * overlap;
        final double extraWidth = extra > 0 ? (overlap + size) : 0;
        final double totalWidth = baseWidth + extraWidth;

        return SizedBox(
          height: size,
          width: totalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < shown; i++)
                Positioned(
                  left: i * overlap,
                  child: Container(
                    height: size,
                    width: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: appTheme.gray_900_02,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomImageView(
                        imagePath: avatars[i],
                        height: size,
                        width: size,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              if (extra > 0)
                Positioned(
                  left: shown * overlap,
                  child: Container(
                    height: size,
                    width: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appTheme.gray_900,
                      border: Border.all(
                        color: appTheme.gray_900_02,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '+$extra',
                      style: TextStyleHelper
                          .instance.body12MediumPlusJakartaSans
                          .copyWith(
                        color: appTheme.blue_gray_300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class CreateMemoryScreenState extends ConsumerState<CreateMemoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ✅ Scroll controller for content area
  final ScrollController _scrollController = ScrollController();

  // ✅ FocusNode for title field
  final FocusNode _titleFocusNode = FocusNode();

  // ✅ Used to keep title visible when keyboard opens
  final GlobalKey _nameSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _nameSectionKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: 0.08,
            );
          }
        });
      }
    });

    // Apply optional pre-selected category after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pre = widget.preSelectedCategoryId;
      if (!mounted) return;
      if (pre != null && pre.trim().isNotEmpty) {
        await ref
            .read(createMemoryNotifier.notifier)
            .initializeWithCategory(pre);
      }
    });
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        ref.watch(createMemoryNotifier);

        final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bool keyboardOpen = bottomInset > 0;

        return Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // ✅ Full height only when keyboard is open
              maxHeight: keyboardOpen
                  ? MediaQuery.of(context).size.height
                  : MediaQuery.of(context).size.height * 0.88,
            ),
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

                  // Drag handle
                  Container(
                    width: 48.h,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: appTheme.colorFF3A3A,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  /// ✅ CONTENT
                  /// No bottom reserve padding here. Ever.
                  /// Since the pinned bar is OUTSIDE this scroll view,
                  /// content cannot go behind it.
                  Flexible(
                    fit: FlexFit.loose,
                    child: CustomScrollView(
                      controller: _scrollController,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: 20.h,
                            right: 20.h,
                            bottom: 0, // ✅ removes the gap permanently
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomHeaderSection(
                                    title: 'Create Memory',
                                    description:
                                        'Invite-only. Every perspective. One timeline. Replay forever',
                                    margin: EdgeInsets.only(
                                      left: 10.h,
                                      right: 10.h,
                                    ),
                                  ),
                                  _buildNameSection(context),
                                  _buildDurationSelector(context),
                                  _buildGroupInviteSection(
                                      context), // ✅ add this
                                  _buildCategorySection(context),
                                  _buildPrivacySettings(context),
                                  SizedBox(height: 20.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ✅ PINNED ACTION BAR (rides keyboard)
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: SafeArea(
                      top: false,
                      bottom:
                          false, // ✅ IMPORTANT: removes the extra bottom space under buttons
                      child: _buildPinnedActionBar(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildNameSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);

        return Container(
          key: _nameSectionKey,
          width: double.infinity,
          margin: EdgeInsets.only(top: 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name your memory',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 10.h),
              CustomEditText(
                focusNode: _titleFocusNode,
                controller: state.memoryNameController,
                hintText: 'e.g Family Xmas 2026',
                validator: (value) {
                  final notifier = ref.read(createMemoryNotifier.notifier);
                  return notifier.validateMemoryName(value);
                },
                fillColor: appTheme.gray_900,
                borderRadius: 8.h,
              ),
            ],
          ),
        );
      },
    );
  }

  /// NEW: Duration Selector Section
  Widget _buildDurationSelector(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final selectedDuration =
            state.createMemoryModel?.selectedDuration ?? '12_hours';

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Memory duration',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _buildDurationTab(
                      context,
                      ref,
                      '12 hours',
                      '12_hours',
                      selectedDuration == '12_hours',
                    ),
                  ),
                  SizedBox(width: 8.h),
                  Expanded(
                    child: _buildDurationTab(
                      context,
                      ref,
                      '1 day',
                      '24_hours',
                      selectedDuration == '24_hours',
                    ),
                  ),
                  SizedBox(width: 8.h),
                  Expanded(
                    child: _buildDurationTab(
                      context,
                      ref,
                      '3 days',
                      '3_days',
                      selectedDuration == '3_days',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Group Invite Section (right under Memory duration)
  Widget _buildGroupInviteSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final notifier = ref.read(createMemoryNotifier.notifier);

        final groups = state.createMemoryModel?.availableGroups ?? [];
        final selectedGroupId = state.createMemoryModel?.selectedGroup;
        final selectedGroupName = _getGroupNameById(groups, selectedGroupId);

        // Use already-fetched members (preferred) so it’s instant on the selected row
        final selectedGroupMembers = state.createMemoryModel?.groupMembers ??
            const <Map<String, dynamic>>[];

        // Best-effort memberCount (prefer DB field, otherwise fall back to loaded members length)
        int memberCount = 0;
        if (selectedGroupId != null && selectedGroupId.isNotEmpty) {
          final g = groups.firstWhere(
            (x) => (x['id'] as String?) == selectedGroupId,
            orElse: () => const {},
          );
          final rawCount = g['member_count'];
          memberCount = (rawCount is int)
              ? rawCount
              : int.tryParse('${rawCount ?? ''}') ??
                  (selectedGroupMembers.isNotEmpty
                      ? selectedGroupMembers.length
                      : 0);
        }

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite group',
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 10.h),

              // Selector row
              GestureDetector(
                onTap: () {
                  _showGroupSelectionBottomSheet(
                    context,
                    notifier,
                  );
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900,
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 26.h,
                        width: 26.h,
                        decoration: BoxDecoration(
                          color: appTheme.deep_purple_A100.withAlpha(51),
                          borderRadius: BorderRadius.circular(8.h),
                        ),
                        child: Icon(
                          Icons.group,
                          color: appTheme.deep_purple_A100,
                          size: 16.h,
                        ),
                      ),
                      SizedBox(width: 10.h),

                      // Group name
                      Expanded(
                        child: Text(
                          selectedGroupName ?? 'None',
                          style: TextStyleHelper
                              .instance.body16BoldPlusJakartaSans
                              .copyWith(
                            fontSize: 16.fSize,
                            fontWeight: FontWeight.w700,
                            color: selectedGroupName != null
                                ? appTheme.gray_50
                                : appTheme.blue_gray_300,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // ✅ Show selected group members (avatars) on the closed row
                      if (selectedGroupId != null &&
                          selectedGroupId.isNotEmpty) ...[
                        SizedBox(width: 10.h),
                        _AvatarStackFromMembers(
                          members: selectedGroupMembers,
                          totalCount: memberCount > 0 ? memberCount : null,
                        ),
                      ],

                      SizedBox(width: 6.h),
                      Icon(
                        Icons.arrow_drop_down,
                        color: appTheme.gray_50,
                        size: 26.h,
                      ),
                    ],
                  ),
                ),
              ),

              // Helper text
              if (selectedGroupId != null && selectedGroupId.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  'All members of this group will be added automatically.',
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.35),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String? _getGroupNameById(
      List<Map<String, dynamic>> groups, String? groupId) {
    if (groupId == null) return null;
    for (final g in groups) {
      if ((g['id'] as String?) == groupId) return g['name'] as String?;
    }
    return null;
  }

// ✅ FULL COPY/PASTE REPLACEMENT
// Replace your entire _showGroupSelectionBottomSheet(...) with this version.

  void _showGroupSelectionBottomSheet(
    BuildContext context,
    CreateMemoryNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false, // ✅ IMPORTANT: prevents extra SafeArea padding
      backgroundColor: appTheme.gray_900_02,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      builder: (modalContext) {
        final maxH = MediaQuery.of(modalContext).size.height * 0.8;

        // ✅ NO SafeArea wrapper here (it adds bottom padding by default)
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(createMemoryNotifier);
            final groups = state.createMemoryModel?.availableGroups ??
                const <Map<String, dynamic>>[];
            final selectedGroupId = state.createMemoryModel?.selectedGroup;

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: Padding(
                padding: EdgeInsets.only(left: 20.h, right: 20.h, top: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Group',
                          style: TextStyleHelper
                              .instance.body16MediumPlusJakartaSans
                              .copyWith(color: appTheme.gray_50),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(modalContext),
                          child: Icon(Icons.close,
                              color: appTheme.gray_50, size: 24.h),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // None option
                    GestureDetector(
                      onTap: () async {
                        await notifier.updateSelectedGroup(null);
                        Navigator.pop(modalContext);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18.h, vertical: 18.h),
                        decoration: BoxDecoration(
                          color: selectedGroupId == null
                              ? appTheme.deep_purple_A100.withAlpha(26)
                              : appTheme.gray_900,
                          borderRadius: BorderRadius.circular(14.h),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 32.h,
                              width: 32.h,
                              decoration: BoxDecoration(
                                color: appTheme.deep_purple_A100.withAlpha(51),
                                borderRadius: BorderRadius.circular(10.h),
                              ),
                              child: Icon(
                                Icons.remove_circle_outline,
                                color: appTheme.deep_purple_A100,
                                size: 21.h,
                              ),
                            ),
                            SizedBox(width: 14.h),
                            Expanded(
                              child: Text(
                                'None',
                                style: TextStyleHelper
                                    .instance.body16BoldPlusJakartaSans
                                    .copyWith(
                                  fontSize: 18.fSize,
                                  fontWeight: FontWeight.w700,
                                  color: appTheme.gray_50,
                                ),
                              ),
                            ),
                            if (selectedGroupId == null)
                              Icon(Icons.check_circle,
                                  color: appTheme.deep_purple_A100, size: 26.h),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // ✅ If user has no groups, offer a quick CTA under "None"
                    if (groups.isEmpty) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(modalContext);
                          NavigatorService.pushNamed(AppRoutes.appGroups)
                              .then((_) {
                            notifier.refreshAvailableGroups();
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.h,
                            vertical: 18.h,
                          ),
                          decoration: BoxDecoration(
                            color: appTheme.gray_900,
                            borderRadius: BorderRadius.circular(14.h),
                            border: Border.all(
                              color: appTheme.deep_purple_A100.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 32.h,
                                width: 32.h,
                                decoration: BoxDecoration(
                                  color:
                                      appTheme.deep_purple_A100.withAlpha(51),
                                  borderRadius: BorderRadius.circular(10.h),
                                ),
                                child: Icon(
                                  Icons.add_circle_outline,
                                  color: appTheme.deep_purple_A100,
                                  size: 21.h,
                                ),
                              ),
                              SizedBox(width: 14.h),
                              Expanded(
                                child: Text(
                                  'Create a group',
                                  style: TextStyleHelper
                                      .instance.body16BoldPlusJakartaSans
                                      .copyWith(
                                    fontSize: 18.fSize,
                                    fontWeight: FontWeight.w700,
                                    color: appTheme.gray_50,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: appTheme.blue_gray_300,
                                size: 26.h,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    Expanded(
                      child: groups.isEmpty
                          ? Center(
                              child: Text(
                                'No groups yet',
                                style: TextStyleHelper
                                    .instance.body14RegularPlusJakartaSans
                                    .copyWith(color: appTheme.blue_gray_300),
                              ),
                            )
                          : ListView.separated(
                              itemCount: groups.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 16.h),
                              itemBuilder: (context, index) {
                                final group = groups[index];
                                final groupId = group['id'] as String?;
                                final groupName =
                                    group['name'] as String? ?? '';
                                final isSelected = groupId == selectedGroupId;
                                final memberCount = group['member_count'];

                                return GestureDetector(
                                  onTap: () async {
                                    if (groupId == null || groupId.isEmpty)
                                      return;
                                    await notifier.updateSelectedGroup(groupId);
                                    Navigator.pop(modalContext);
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18.h, vertical: 18.h),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? appTheme.deep_purple_A100
                                              .withAlpha(26)
                                          : appTheme.gray_900,
                                      borderRadius: BorderRadius.circular(14.h),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 32.h,
                                          width: 32.h,
                                          decoration: BoxDecoration(
                                            color: appTheme.deep_purple_A100
                                                .withAlpha(51),
                                            borderRadius:
                                                BorderRadius.circular(10.h),
                                          ),
                                          child: Icon(Icons.group,
                                              color: appTheme.deep_purple_A100,
                                              size: 21.h),
                                        ),
                                        SizedBox(width: 14.h),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                groupName.isEmpty
                                                    ? 'Unnamed group'
                                                    : groupName,
                                                style: TextStyleHelper.instance
                                                    .body16BoldPlusJakartaSans
                                                    .copyWith(
                                                  fontSize: 18.fSize,
                                                  fontWeight: FontWeight.w700,
                                                  color: appTheme.gray_50,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 6.h),
                                              Row(
                                                children: [
                                                  if (groupId != null &&
                                                      groupId.isNotEmpty)
                                                    _GroupMemberAvatars(
                                                      groupId: groupId,
                                                      memberCount: (memberCount
                                                              is int)
                                                          ? memberCount
                                                          : int.tryParse(
                                                                  '${memberCount ?? ''}') ??
                                                              0,
                                                    ),
                                                  SizedBox(width: 10.h),
                                                  if (memberCount != null)
                                                    Text(
                                                      '$memberCount members',
                                                      style: TextStyleHelper
                                                          .instance
                                                          .body14RegularPlusJakartaSans
                                                          .copyWith(
                                                        color: appTheme
                                                            .blue_gray_300,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(Icons.check_circle,
                                              color: appTheme.deep_purple_A100,
                                              size: 26.h),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDurationTab(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(createMemoryNotifier.notifier).updateSelectedDuration(value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? appTheme.deep_purple_A100 : appTheme.gray_900,
          borderRadius: BorderRadius.circular(8.h),
        ),
        child: Center(
          child: Text(
            label,
            style:
                TextStyleHelper.instance.body14MediumPlusJakartaSans.copyWith(
              color: isSelected ? appTheme.whiteCustom : appTheme.blue_gray_300,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Category Selection Section
  Widget _buildCategorySection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final notifier = ref.read(createMemoryNotifier.notifier);

        final availableCategories =
            state.createMemoryModel?.availableCategories ?? [];
        final selectedCategoryId = state.createMemoryModel?.selectedCategory;

        final selectedCategoryName = _getCategoryNameById(
          availableCategories,
          selectedCategoryId,
        );

        final selectedCategory = _getCategoryById(
          availableCategories,
          selectedCategoryId,
        );

        final selectedIconUrl =
            (selectedCategory?['icon_url'] as String?)?.trim();
        final hasSelectedIconUrl =
            selectedIconUrl != null && selectedIconUrl.isNotEmpty;

        final bool hasSelection = selectedCategoryName != null;

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Category',
                    style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                  SizedBox(width: 4.h),
                  Text(
                    '*',
                    style: TextStyleHelper
                        .instance.title16RegularPlusJakartaSans
                        .copyWith(color: appTheme.colorFFD81E),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: () {
                  if (availableCategories.isEmpty) return;
                  _showCategorySelectionBottomSheetCreateMemory(
                    context,
                    notifier,
                    availableCategories,
                    selectedCategoryId,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900,
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Row(
                    children: [
                      if (hasSelection) ...[
                        if (hasSelectedIconUrl)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.h),
                            child: CustomImageView(
                              imagePath: selectedIconUrl,
                              height: 26.h,
                              width: 26.h,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            height: 26.h,
                            width: 26.h,
                            decoration: BoxDecoration(
                              color: appTheme.deep_purple_A100.withAlpha(51),
                              borderRadius: BorderRadius.circular(8.h),
                            ),
                            child: Icon(
                              Icons.category,
                              color: appTheme.deep_purple_A100,
                              size: 16.h,
                            ),
                          ),
                        SizedBox(width: 10.h),
                      ],
                      Expanded(
                        child: Text(
                          availableCategories.isEmpty
                              ? 'Loading categories...'
                              : (selectedCategoryName ?? 'Select Category'),
                          style: TextStyleHelper
                              .instance.body16BoldPlusJakartaSans
                              .copyWith(
                            fontSize: 16.fSize,
                            fontWeight: FontWeight.w700,
                            color: selectedCategoryName != null
                                ? appTheme.gray_50
                                : appTheme.blue_gray_300,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: appTheme.gray_50,
                        size: 26.h,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _getCategoryNameById(
    List<Map<String, dynamic>> categories,
    String? categoryId,
  ) {
    if (categoryId == null) return null;
    for (final c in categories) {
      final id = c['id'] as String?;
      if (id == categoryId) return c['name'] as String?;
    }
    return null;
  }

  Map<String, dynamic>? _getCategoryById(
    List<Map<String, dynamic>> categories,
    String? categoryId,
  ) {
    if (categoryId == null) return null;
    for (final c in categories) {
      final id = c['id'] as String?;
      if (id == categoryId) return c;
    }
    return null;
  }

// ✅ FULL COPY/PASTE REPLACEMENT
// Replace your entire _showCategorySelectionBottomSheetCreateMemory(...) with this version.

  void _showCategorySelectionBottomSheetCreateMemory(
    BuildContext context,
    CreateMemoryNotifier notifier,
    List<Map<String, dynamic>> categories,
    String? selectedCategoryId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false, // ✅ IMPORTANT: prevents extra SafeArea padding
      backgroundColor: appTheme.gray_900_02,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      builder: (modalContext) {
        final maxH = MediaQuery.of(modalContext).size.height * 0.8;

        // ✅ NO SafeArea wrapper here (it adds bottom padding by default)
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20.h,
              right: 20.h,
              top: 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Category',
                      style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(modalContext),
                      child: Icon(
                        Icons.close,
                        color: appTheme.gray_50,
                        size: 24.h,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final categoryId = category['id'] as String;
                      final categoryName = category['name'] as String;
                      final isSelected = categoryId == selectedCategoryId;

                      final iconUrl = (category['icon_url'] as String?)?.trim();
                      final tagline = (category['tagline'] as String?)?.trim();

                      final hasIconUrl = iconUrl != null && iconUrl.isNotEmpty;
                      final hasTagline = tagline != null && tagline.isNotEmpty;

                      return GestureDetector(
                        onTap: () {
                          notifier.updateSelectedCategory(categoryId);
                          Navigator.pop(modalContext);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.h,
                            vertical: 18.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? appTheme.deep_purple_A100.withAlpha(26)
                                : appTheme.gray_900,
                            borderRadius: BorderRadius.circular(14.h),
                          ),
                          child: Row(
                            children: [
                              if (hasIconUrl)
                                ClipRRect(
                                  child: CustomImageView(
                                    imagePath: iconUrl,
                                    height: 32.h,
                                    width: 32.h,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else
                                Container(
                                  height: 32.h,
                                  width: 32.h,
                                  decoration: BoxDecoration(
                                    color:
                                        appTheme.deep_purple_A100.withAlpha(51),
                                  ),
                                  child: Icon(
                                    Icons.category,
                                    color: appTheme.deep_purple_A100,
                                    size: 21.h,
                                  ),
                                ),
                              SizedBox(width: 14.h),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categoryName,
                                      style: TextStyleHelper
                                          .instance.body16BoldPlusJakartaSans
                                          .copyWith(
                                        fontSize: 18.fSize,
                                        fontWeight: FontWeight.w700,
                                        color: appTheme.gray_50,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (hasTagline) ...[
                                      SizedBox(height: 3.h),
                                      Text(
                                        tagline,
                                        style: TextStyleHelper.instance
                                            .body14RegularPlusJakartaSans
                                            .copyWith(
                                          color: appTheme.blue_gray_300,
                                          height: 1.35,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: appTheme.deep_purple_A100,
                                  size: 26.h,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacySettings(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final isPublic = state.createMemoryModel?.isPublic ?? false;

        return Container(
          margin: EdgeInsets.only(top: 20.h),
          child: CustomSettingsRow(
            useIconData: true,
            iconData: isPublic ? Icons.public : Icons.lock,
            iconColor:
                isPublic ? appTheme.green_500 : appTheme.deep_purple_A100,
            title: isPublic ? 'Public' : 'Private',
            description: isPublic
                ? 'Anyone can view this memory'
                : 'Only members can view',
            switchValue: isPublic,
            onSwitchChanged: (value) {
              ref
                  .read(createMemoryNotifier.notifier)
                  .togglePrivacySetting(value);
            },
            margin: EdgeInsets.zero,
          ),
        );
      },
    );
  }

  /// ✅ Pinned action bar
  Widget _buildPinnedActionBar(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);

        ref.listen(
          createMemoryNotifier,
          (previous, current) {
            if (current.shouldNavigateToConfirmation == true &&
                (previous?.shouldNavigateToConfirmation != true)) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
              Future.delayed(const Duration(milliseconds: 200), () {
                final model = current.createMemoryModel;

// pull selected category map from availableCategories
                final selectedCategoryId = model?.selectedCategory;
                final categories = model?.availableCategories ??
                    const <Map<String, dynamic>>[];

                Map<String, dynamic>? selectedCategory;
                if (selectedCategoryId != null) {
                  for (final c in categories) {
                    if ((c['id'] as String?) == selectedCategoryId) {
                      selectedCategory = c;
                      break;
                    }
                  }
                }

// prefer icon_url from the category map
                final iconUrl =
                    (selectedCategory?['icon_url'] as String?)?.trim();
                final cleanedIconUrl = (iconUrl == null ||
                        iconUrl.isEmpty ||
                        iconUrl == 'null' ||
                        iconUrl == 'undefined')
                    ? null
                    : iconUrl;

                NavigatorService.pushNamed(
                  AppRoutes.memoryConfirmationScreen,
                  arguments: {
                    'memory_id': current.createdMemoryId,
                    'memory_name': current.memoryNameController?.text.trim(),
                    'category_id': selectedCategoryId,
                    // optional but useful
                    'category_icon': cleanedIconUrl,
                    // ✅ this fixes recorder header
                    'visibility':
                        model?.isPublic == true ? 'public' : 'private',
                    // optional
                  },
                );
              });
            }

            if (current.errorMessage != null &&
                previous?.errorMessage != current.errorMessage) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(current.errorMessage!),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        );

        return Container(
          padding: EdgeInsets.only(
            left: 20.h,
            right: 20.h,
            top: 12.h,
            bottom: 12.h,
          ),
          decoration: BoxDecoration(
            color: appTheme.gray_900_02,
            border: Border(
              top: BorderSide(
                color: appTheme.blue_gray_300.withAlpha(25),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    } else {
                      NavigatorService.goBack();
                    }
                  },
                  buttonStyle: CustomButtonStyle.outlineDark,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: CustomButton(
                  text: state.isLoading ? 'Creating...' : 'Create Memory',
                  onPressed: state.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            ref
                                .read(createMemoryNotifier.notifier)
                                .createMemory();
                          }
                        },
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  isDisabled: state.isLoading,
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
