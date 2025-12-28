import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_feature_card.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_icon_button_row.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_info_row.dart';
import '../../widgets/custom_settings_row.dart';
import 'notifier/create_memory_notifier.dart';

class CreateMemoryScreen extends ConsumerStatefulWidget {
  CreateMemoryScreen({Key? key}) : super(key: key);

  @override
  CreateMemoryScreenState createState() => CreateMemoryScreenState();
}

class CreateMemoryScreenState extends ConsumerState<CreateMemoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final currentStep = state.currentStep ?? 1;

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
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        switchInCurve: Curves.easeInOut,
                        switchOutCurve: Curves.easeInOut,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: currentStep == 1
                            ? _buildStep1Content(context)
                            : _buildStep2Content(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Step 1: Memory Creation Form
  Widget _buildStep1Content(BuildContext context) {
    return Column(
      key: ValueKey('step1'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomHeaderSection(
          title: 'Create Memory',
          description:
              'Invite-only. Every perspective. One timeline. Replay forever',
          margin: EdgeInsets.only(left: 10.h, right: 10.h),
        ),
        _buildNameSection(context),
        _buildPrivacySettings(context),
        _buildFeatureCard(context),
        _buildStep1ActionButtons(context),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// Step 2: Invite People
  Widget _buildStep2Content(BuildContext context) {
    return Column(
      key: ValueKey('step2'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomHeaderSection(
          title: 'Invite people (optional)',
          description:
              'Invite-only. Every perspective. One timeline. Replay forever',
          margin: EdgeInsets.only(left: 10.h, right: 10.h),
        ),
        _buildInviteIconButtons(context),
        SizedBox(height: 16.h),
        _buildInviteOptionsSection(context),
        SizedBox(height: 16.h),
        _buildSearchSection(context),
        SizedBox(height: 16.h),
        _buildSearchResults(context),
        SizedBox(height: 20.h),
        _buildHelperBadge(context),
        SizedBox(height: 16.h),
        _buildStep2ActionButtons(context),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// Section Widget
  Widget _buildNameSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name your memory',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
              SizedBox(height: 10.h),
              CustomEditText(
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

  /// Section Widget
  Widget _buildPrivacySettings(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final isPublic = state.createMemoryModel?.isPublic ?? false;

        return Container(
          margin: EdgeInsets.only(top: 20.h),
          child: CustomSettingsRow(
            useIconData: !isPublic,
            iconData: !isPublic ? Icons.lock : null,
            iconPath: isPublic ? ImageConstant.imgIconGreen500 : null,
            iconColor: !isPublic ? appTheme.deep_purple_A100 : null,
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

  /// Section Widget
  Widget _buildFeatureCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      child: CustomFeatureCard(
        iconPath: ImageConstant.imgFrameDeepPurpleA200,
        title: '12-hour posting window',
        description:
            'Memories are open for 12 hours but don\'t sweat it if you missed someone, footage can be added later.',
        backgroundColor: appTheme.colorF716A8,
        iconBackgroundColor: appTheme.color41C124,
        titleColor: appTheme.deep_purple_A200,
        margin: EdgeInsets.zero,
      ),
    );
  }

  /// Step 1 Action Buttons
  Widget _buildStep1ActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 20.h),
          child: Row(
            spacing: 12.h,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () {
                    ref.read(createMemoryNotifier.notifier).onCancelPressed();
                  },
                  buttonStyle: CustomButtonStyle.fillDark,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Next',
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      ref.read(createMemoryNotifier.notifier).moveToStep2();
                    }
                  },
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
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

  /// Invite Icon Buttons
  Widget _buildInviteIconButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          margin: EdgeInsets.only(top: 20.h),
          child: CustomIconButtonRow(
            firstIconPath: ImageConstant.imgButtons,
            secondIconPath: ImageConstant.imgButtonsGray50,
            onFirstIconTap: () {
              ref.read(createMemoryNotifier.notifier).handleQRCodeTap();
            },
            onSecondIconTap: () {
              ref.read(createMemoryNotifier.notifier).handleCameraTap();
            },
          ),
        );
      },
    );
  }

  /// Invite Header Section
  Widget _buildInviteHeaderSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 26.h, left: 10.h, right: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'Invite people (optional)',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
            ),
          ),
          CustomIconButtonRow(
            firstIconPath: ImageConstant.imgButtons,
            secondIconPath: ImageConstant.imgButtonsGray50,
            onFirstIconTap: () {
              ref.read(createMemoryNotifier.notifier).handleQRCodeTap();
            },
            onSecondIconTap: () {
              ref.read(createMemoryNotifier.notifier).handleCameraTap();
            },
          ),
        ],
      ),
    );
  }

  /// Invite Options Section
  Widget _buildInviteOptionsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);
        final availableGroups = state.createMemoryModel?.availableGroups ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDropdown<String>(
              items: _buildDropdownItemsFromGroups(availableGroups),
              onChanged: (value) {
                ref
                    .read(createMemoryNotifier.notifier)
                    .updateSelectedGroup(value);
              },
              value: state.createMemoryModel?.selectedGroup,
              placeholder: availableGroups.isEmpty
                  ? 'No groups available'
                  : 'Select from group...',
              leftIcon: ImageConstant.imgIconBlueGray30022x26,
              rightIcon: ImageConstant.imgIconBlueGray30022x18,
              margin: EdgeInsets.zero,
            ),
            if (state.createMemoryModel?.selectedGroup != null &&
                (state.createMemoryModel?.groupMembers.isNotEmpty ?? false))
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
        final state = ref.watch(createMemoryNotifier);
        final groupMembers = state.createMemoryModel?.groupMembers ?? [];

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
        final state = ref.watch(createMemoryNotifier);

        return Container(
          decoration: BoxDecoration(
            color: appTheme.gray_900_01,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: appTheme.blue_gray_300.withAlpha(77)),
          ),
          child: TextField(
            controller: state.searchController,
            onChanged: (value) {
              ref.read(createMemoryNotifier.notifier).updateSearchQuery(value);
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
                child: CustomImageView(
                  imagePath: ImageConstant.imgSearch,
                  height: 20.h,
                  width: 20.h,
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
        final state = ref.watch(createMemoryNotifier);
        final searchQuery = state.createMemoryModel?.searchQuery ?? '';
        final searchResults = state.createMemoryModel?.searchResults ?? [];

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
                  .read(createMemoryNotifier.notifier)
                  .toggleUserInvite(user['id']);
            },
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(createMemoryNotifier);
                final isInvited = state.createMemoryModel?.invitedUserIds
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

  /// Helper Badge Section
  Widget _buildHelperBadge(BuildContext context) {
    return CustomInfoRow(
      iconPath: ImageConstant.imgFrameBlueGray300,
      text: 'You can also share a link after creating the memory',
      textWidth: 0.82,
      margin: EdgeInsets.zero,
    );
  }

  /// Step 2 Action Buttons
  Widget _buildStep2ActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(createMemoryNotifier);

        // Listen for navigation and errors
        ref.listen(
          createMemoryNotifier,
          (previous, current) {
            if (current.shouldNavigateBack ?? false) {
              NavigatorService.goBack();
            }
            if (current.errorMessage != null && previous?.errorMessage != current.errorMessage) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(current.errorMessage!),
                  backgroundColor: appTheme.colorFFD81E,
                ),
              );
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
                    ref.read(createMemoryNotifier.notifier).backToStep1();
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
                    ref.read(createMemoryNotifier.notifier).createMemory();
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

  /// Dropdown items builder from real groups
  List<DropdownMenuItem<String>> _buildDropdownItemsFromGroups(
      List<Map<String, dynamic>> groups) {
    if (groups.isEmpty) {
      return [];
    }

    return groups.map((group) {
      return DropdownMenuItem<String>(
        value: group['id'] as String,
        child: Text(group['name'] as String),
      );
    }).toList();
  }
}
