// lib/presentation/create_group_screen/create_group_screen.dart
// FULL COPY/PASTE FILE
// Updates: selection UI now matches Edit Group (full border + check icon)

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import './widgets/friend_list_item.dart';
import 'notifier/create_group_notifier.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  CreateGroupScreen({Key? key}) : super(key: key);

  @override
  CreateGroupScreenState createState() => CreateGroupScreenState();
}

class CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
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

              // Title header
              SizedBox(height: 10.h),
              _buildSheetTitleHeader(context),
              SizedBox(height: 8.h),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        SizedBox(height: 24.h),
                        _buildFriendsList(context),
                        SizedBox(height: 24.h),
                        _buildActionButtons(context),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTitleHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.h),
      child: Row(
        children: [
          SizedBox(width: 44.h, height: 44.h),
          Expanded(
            child: Center(
              child: Text(
                'Create Group',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ),
          ),
          InkWell(
            onTap: NavigatorService.goBack,
            borderRadius: BorderRadius.circular(22.h),
            child: SizedBox(
              width: 44.h,
              height: 44.h,
              child: Center(
                child: Icon(
                  Icons.close,
                  size: 22.h,
                  color: appTheme.blue_gray_300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(createGroupNotifier);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              'Group Name',
              style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.blue_gray_300),
            ),
          ),
          CustomEditText(
            controller: state.groupNameController,
            hintText: 'e.g., Family, Work Friends, Team',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Group name is required';
              }
              return null;
            },
          ),
        ],
      );
    });
  }

  Widget _buildFriendsList(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(createGroupNotifier);

      if (state.isLoading ?? false) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: CircularProgressIndicator(color: appTheme.colorFF52D1),
          ),
        );
      }

      final filteredFriends = state.createGroupModel?.filteredFriends ?? [];

      if (filteredFriends.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Text(
            'No friends found. Add friends to create a group.',
            style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                .copyWith(color: appTheme.blue_gray_300),
            textAlign: TextAlign.center,
          ),
        );
      }

      return Column(
        children: filteredFriends.map((friend) {
          final isSelected = state.createGroupModel?.selectedMembers
              ?.any((member) => member.id == friend.id) ??
              false;

          return FriendListItem(
            friend: friend,
            isSelected: isSelected,
            margin: EdgeInsets.only(top: 8.h), // closer to Edit Group spacing
            onTap: () {
              if (isSelected) {
                ref.read(createGroupNotifier.notifier).removeMember(friend);
              } else {
                ref.read(createGroupNotifier.notifier).addMember(friend);
              }
            },
          );
        }).toList(),
      );
    });
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final state = ref.watch(createGroupNotifier);

      ref.listen(createGroupNotifier, (previous, current) {
        if (current.isSuccess ?? false) {
          NavigatorService.goBack();
        }
      });

      return Container(
        margin: EdgeInsets.only(top: 22.h),
        child: Row(
          spacing: 12.h,
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancel',
                buttonStyle: CustomButtonStyle.fillDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMediumGray,
                onPressed: () => onTapCancel(context),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Create',
                buttonStyle: CustomButtonStyle.fillPrimary,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                isDisabled: state.isLoading,
                onPressed: () => onTapCreate(context),
              ),
            ),
          ],
        ),
      );
    });
  }

  void onTapCancel(BuildContext context) {
    NavigatorService.goBack();
  }

  void onTapCreate(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(createGroupNotifier.notifier).createGroup();
    }
  }
}