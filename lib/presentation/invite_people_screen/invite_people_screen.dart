import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_info_row.dart';
import '../memory_invitation_screen/memory_invitation_screen.dart';
import 'notifier/invite_people_notifier.dart';

class InvitePeopleScreen extends ConsumerStatefulWidget {
  InvitePeopleScreen({Key? key}) : super(key: key);

  @override
  InvitePeopleScreenState createState() => InvitePeopleScreenState();
}

class InvitePeopleScreenState extends ConsumerState<InvitePeopleScreen> {
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
        final state = ref.watch(invitePeopleNotifier);

        return Column(
          children: [
            _buildHeaderSection(context),
            SizedBox(height: 16.h),
            _buildInviteOptionsSection(context),
            SizedBox(height: 16.h),
            _buildSearchSection(context),
            SizedBox(height: 16.h),
            _buildSearchResults(context),
            SizedBox(height: 20.h),
            _buildInfoSection(context),
            SizedBox(height: 16.h),
            _buildActionButtons(context),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 26.h, left: 10.h, right: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h, right: 8.h),
              child: Text(
                'Invite people (optional)',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          CustomIconButtonRow(
            firstIcon: Icons.qr_code_scanner,
            secondIcon: Icons.photo_camera,
            firstIconColor: appTheme.gray_50,
            secondIconColor: appTheme.gray_50,
            onFirstIconTap: () {
              onTapQRCode(context);
            },
            onSecondIconTap: () {
              onTapCamera(context);
            },
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildInviteOptionsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(invitePeopleNotifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDropdown<String>(
              items: _buildDropdownItems(),
              onChanged: (value) {
                ref
                    .read(invitePeopleNotifier.notifier)
                    .updateSelectedGroup(value);
              },
              value: state.invitePeopleModel?.selectedGroup,
              placeholder: 'Select from group...',
              leftIcon: Icons.group_outlined,
              rightIcon: Icons.expand_more,
              margin: EdgeInsets.zero,
            ),
            if (state.invitePeopleModel?.selectedGroup != null &&
                (state.invitePeopleModel?.groupMembers.isNotEmpty ?? false))
              _buildGroupMembersList(context),
          ],
        );
      },
    );
  }

  /// Section Widget - Group Members List
  Widget _buildGroupMembersList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(invitePeopleNotifier);
        final groupMembers = state.invitePeopleModel?.groupMembers ?? [];

        return Container(
          margin: EdgeInsets.only(top: 12.h),
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: appTheme.blue_gray_300.withAlpha(77)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Members (${groupMembers.length})',
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(
                  color: appTheme.blue_gray_300,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                constraints: BoxConstraints(maxHeight: 150.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  itemCount: groupMembers.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final member = groupMembers[index];
                    return _buildGroupMemberItem(context, member);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Individual group member item
  Widget _buildGroupMemberItem(
      BuildContext context, Map<String, dynamic> member) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 6.h),
      child: Row(
        children: [
          ClipOval(
            child: CustomImageView(
              imagePath: member['avatar'] ?? '',
              height: 32.h,
              width: 32.h,
              fit: BoxFit.cover,
              isCircular: true,
            ),
          ),
          SizedBox(width: 10.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] ?? 'Unknown User',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(
                    color: appTheme.gray_50,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${member['username'] ?? 'username'}',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(
                    color: appTheme.blue_gray_300,
                    fontSize: 10.fSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget - Search Input Field
  Widget _buildSearchSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(invitePeopleNotifier);

        return Container(
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: appTheme.blue_gray_300.withAlpha(77)),
          ),
          child: TextField(
            controller: state.searchController,
            onChanged: (value) {
              ref.read(invitePeopleNotifier.notifier).updateSearchQuery(value);
            },
            style:
                TextStyleHelper.instance.body14MediumPlusJakartaSans.copyWith(
              color: appTheme.gray_50,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name...',
              hintStyle:
                  TextStyleHelper.instance.body14MediumPlusJakartaSans.copyWith(
                color: appTheme.blue_gray_300,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.h),
                child: Icon(
                  Icons.search,
                  size: 20.h,
                  color: appTheme.blue_gray_300,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.h,
                vertical: 14.h,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Section Widget - Search Results Display
  Widget _buildSearchResults(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(invitePeopleNotifier);
        final searchQuery = state.invitePeopleModel?.searchQuery ?? '';
        final searchResults = state.invitePeopleModel?.searchResults ?? [];

        // Only show results if there's a search query
        if (searchQuery.isEmpty) {
          return SizedBox.shrink();
        }

        // Show "No results" if search query exists but no matches
        if (searchResults.isEmpty) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              'No users found',
              style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                  .copyWith(
                color: appTheme.blue_gray_300,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        // Display search results
        return Container(
          constraints: BoxConstraints(maxHeight: 200.h),
          child: ListView.separated(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            itemCount: searchResults.length,
            separatorBuilder: (context, index) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final user = searchResults[index];
              return _buildUserResultItem(context, user);
            },
          ),
        );
      },
    );
  }

  /// Individual user result item
  Widget _buildUserResultItem(BuildContext context, Map<String, dynamic> user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 10.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(10.h),
        border: Border.all(color: appTheme.blue_gray_300.withAlpha(51)),
      ),
      child: Row(
        children: [
          // User avatar
          ClipOval(
            child: CustomImageView(
              imagePath: user['avatar'] ?? '',
              height: 40.h,
              width: 40.h,
              fit: BoxFit.cover,
              isCircular: true,
            ),
          ),
          SizedBox(width: 12.h),
          // User name and username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown User',
                  style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                      .copyWith(
                    color: appTheme.gray_50,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '@${user['username'] ?? 'username'}',
                  style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                      .copyWith(
                    color: appTheme.blue_gray_300,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Invite button
          GestureDetector(
            onTap: () {
              ref
                  .read(invitePeopleNotifier.notifier)
                  .toggleUserInvite(user['id']);
            },
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(invitePeopleNotifier);
                final isInvited = state.invitePeopleModel?.invitedUserIds
                        .contains(user['id']) ??
                    false;

                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isInvited
                        ? appTheme.deep_purple_A100
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.h),
                    border: Border.all(
                      color: isInvited
                          ? appTheme.deep_purple_A100
                          : appTheme.blue_gray_300,
                    ),
                  ),
                  child: Text(
                    isInvited ? 'Invited' : 'Invite',
                    style: TextStyleHelper.instance.body12BoldPlusJakartaSans
                        .copyWith(
                      color:
                          isInvited ? appTheme.gray_50 : appTheme.blue_gray_300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildInfoSection(BuildContext context) {
    return CustomInfoRow(
      icon: Icons.info_outline,
      text: 'You can also share a link after creating the memory',
      textWidth: 0.82,
      margin: EdgeInsets.only(top: 20.h, right: 26.h, left: 12.h),
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(invitePeopleNotifier);

        ref.listen(
          invitePeopleNotifier,
          (previous, current) {
            if (current.isNavigating ?? false) {
              if (current.navigationRoute != null) {
                NavigatorService.pushNamed(current.navigationRoute!);
              }
            }
          },
        );

        return Container(
          margin: EdgeInsets.only(top: 20.h),
          child: Row(
            spacing: 12.h,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Back',
                  buttonStyle: CustomButtonStyle.fillDark,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  onPressed: () {
                    onTapBack(context);
                  },
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Create',
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  isDisabled: state.isLoading,
                  onPressed: () {
                    onTapCreate(context);
                  },
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

  /// Dropdown items builder
  List<DropdownMenuItem<String>> _buildDropdownItems() {
    return [
      DropdownMenuItem(
        value: 'family',
        child: Text('Family'),
      ),
      DropdownMenuItem(
        value: 'friends',
        child: Text('Friends'),
      ),
      DropdownMenuItem(
        value: 'work',
        child: Text('Work'),
      ),
      DropdownMenuItem(
        value: 'school',
        child: Text('School'),
      ),
    ];
  }

  /// Navigation handlers
  void onTapQRCode(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MemoryInvitationScreen(),
    );
  }

  void onTapCamera(BuildContext context) {
    ref.read(invitePeopleNotifier.notifier).handleCameraTap();
  }

  void onTapBack(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.appBsMemoryCreate);
  }

  void onTapCreate(BuildContext context) {
    ref.read(invitePeopleNotifier.notifier).createMemory();
  }
}
