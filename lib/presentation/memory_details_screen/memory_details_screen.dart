import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_edit_text.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import '../invite_people_screen/invite_people_screen.dart';
import './widgets/member_item_widget.dart';
import 'notifier/memory_details_notifier.dart';

class MemoryDetailsScreen extends ConsumerStatefulWidget {
  final String memoryId;

  const MemoryDetailsScreen({Key? key, required this.memoryId})
      : super(key: key);

  @override
  MemoryDetailsScreenState createState() => MemoryDetailsScreenState();
}

class MemoryDetailsScreenState extends ConsumerState<MemoryDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Load memory data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoryDetailsNotifier.notifier).loadMemoryData(widget.memoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
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
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(memoryDetailsNotifier);

                  if (state.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            appTheme.deep_purple_A100),
                      ),
                    );
                  }

                  if (state.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48.h, color: Colors.red),
                            SizedBox(height: 16.h),
                            Text(
                              state.errorMessage!,
                              style: TextStyleHelper
                                  .instance.body14RegularPlusJakartaSans
                                  .copyWith(color: appTheme.gray_50),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        SizedBox(height: 24.h),
                        _buildLocationSection(context),
                        SizedBox(height: 24.h),
                        // NEW: Category selection section
                        _buildCategorySection(context),
                        SizedBox(height: 24.h),
                        _buildMemoryInfo(context),
                        SizedBox(height: 24.h),
                        _buildMembersList(context),
                        SizedBox(height: 24.h),
                        if (state.isCreator) _buildActionButtons(context),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Memory Details',
                  style: TextStyleHelper.instance.title20BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: appTheme.gray_50, size: 24.h),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Title',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300, height: 1.31),
              ),
            ),
            SizedBox(height: 12.h),
            CustomEditText(
              controller: state.titleController,
              hintText: 'Memory Title',
              suffixIcon:
                  state.isCreator ? ImageConstant.imgIconGray5018x20 : null,
              fillColor: appTheme.gray_900,
              borderRadius: 8.h,
              textStyle: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
              readOnly: !state.isCreator,
            ),
            if (!state.isCreator) ...[
              SizedBox(height: 12.h),
              Text(
                'View-only mode - Only the creator can edit this memory',
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ],
        );
      },
    );
  }

  /// NEW: Location Section Widget
  Widget _buildLocationSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        final notifier = ref.read(memoryDetailsNotifier.notifier);
        final isCreator = state.isCreator;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: appTheme.blue_gray_300,
                      size: 18.h,
                    ),
                    SizedBox(width: 6.h),
                    Text(
                      'Location',
                      style: TextStyleHelper
                          .instance.title16RegularPlusJakartaSans
                          .copyWith(
                              color: appTheme.blue_gray_300, height: 1.31),
                    ),
                  ],
                ),
                if (isCreator && !state.isFetchingLocation)
                  GestureDetector(
                    onTap: () {
                      notifier.fetchCurrentLocation();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.h,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: appTheme.deep_purple_A100.withAlpha(26),
                        borderRadius: BorderRadius.circular(8.h),
                        border: Border.all(
                          color: appTheme.deep_purple_A100,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location,
                            color: appTheme.deep_purple_A100,
                            size: 16.h,
                          ),
                          SizedBox(width: 4.h),
                          Text(
                            'Get Current',
                            style: TextStyleHelper
                                .instance.body12BoldPlusJakartaSans
                                .copyWith(
                              color: appTheme.deep_purple_A100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (state.isFetchingLocation)
                  SizedBox(
                    width: 20.h,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        appTheme.deep_purple_A100,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            CustomEditText(
              controller: state.locationController,
              hintText: isCreator
                  ? 'Enter location or use Get Current'
                  : 'No location set',
              suffixIcon: isCreator ? ImageConstant.imgIconGray5018x20 : null,
              fillColor: appTheme.gray_900,
              borderRadius: 8.h,
              textStyle: TextStyleHelper.instance.title16RegularPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
              readOnly: !isCreator,
            ),
            if (!isCreator) ...[
              SizedBox(height: 8.h),
              Text(
                'Location can only be edited by the creator',
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ],
        );
      },
    );
  }

  /// NEW: Category Section Widget
  Widget _buildCategorySection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        final notifier = ref.read(memoryDetailsNotifier.notifier);
        final isCreator = state.isCreator;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: appTheme.blue_gray_300,
                  size: 18.h,
                ),
                SizedBox(width: 6.h),
                Text(
                  'Category',
                  style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.31),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Category Selection
            if (isCreator)
              GestureDetector(
                onTap: () {
                  _showCategorySelectionBottomSheet(context, notifier, state);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.h,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: appTheme.gray_900,
                    borderRadius: BorderRadius.circular(8.h),
                    border: Border.all(
                      color: appTheme.blue_gray_300.withAlpha(77),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          state.selectedCategoryName ?? 'Select Category',
                          style: TextStyleHelper
                              .instance.title16RegularPlusJakartaSans
                              .copyWith(
                            color: state.selectedCategoryName != null
                                ? appTheme.gray_50
                                : appTheme.blue_gray_300,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: appTheme.gray_50,
                        size: 24.h,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.h,
                  vertical: 14.h,
                ),
                decoration: BoxDecoration(
                  color: appTheme.gray_900,
                  borderRadius: BorderRadius.circular(8.h),
                  border: Border.all(
                    color: appTheme.blue_gray_300.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: Text(
                  state.selectedCategoryName ?? 'No category set',
                  style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ),

            if (!isCreator) ...[
              SizedBox(height: 8.h),
              Text(
                'Category can only be changed by the creator',
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300),
              ),
            ],
          ],
        );
      },
    );
  }

  /// NEW: Show category selection bottom sheet
  void _showCategorySelectionBottomSheet(
    BuildContext context,
    dynamic notifier,
    dynamic state,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.gray_900_02,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      builder: (modalContext) => Container(
        padding: EdgeInsets.all(20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
            SizedBox(height: 20.h),

            // Categories List
            if (state.isLoadingCategories)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        appTheme.deep_purple_A100),
                  ),
                ),
              )
            else if (state.categories.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: Text(
                    'No categories available',
                    style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                        .copyWith(color: appTheme.blue_gray_300),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: state.categories.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  final categoryId = category['id'] as String;
                  final categoryName = category['name'] as String;
                  final isSelected = categoryId == state.selectedCategoryId;

                  return GestureDetector(
                    onTap: () {
                      notifier.updateCategory(categoryId, categoryName);
                      Navigator.pop(modalContext);
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? appTheme.deep_purple_A100.withAlpha(26)
                            : appTheme.gray_900,
                        borderRadius: BorderRadius.circular(8.h),
                        border: Border.all(
                          color: isSelected
                              ? appTheme.deep_purple_A100
                              : appTheme.blue_gray_300.withAlpha(77),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Category Icon
                          if (category['icon_url'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.h),
                              child: CustomImageView(
                                imagePath: category['icon_url'] as String,
                                height: 40.h,
                                width: 40.h,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 40.h,
                              width: 40.h,
                              decoration: BoxDecoration(
                                color: appTheme.deep_purple_A100.withAlpha(51),
                                borderRadius: BorderRadius.circular(8.h),
                              ),
                              child: Icon(
                                Icons.category,
                                color: appTheme.deep_purple_A100,
                                size: 24.h,
                              ),
                            ),
                          SizedBox(width: 12.h),

                          // Category Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName,
                                  style: TextStyleHelper
                                      .instance.body16BoldPlusJakartaSans
                                      .copyWith(
                                    color: appTheme.gray_50,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (category['tagline'] != null) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    category['tagline'] as String,
                                    style: TextStyleHelper
                                        .instance.body12MediumPlusJakartaSans
                                        .copyWith(
                                      color: appTheme.blue_gray_300,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Selection Indicator
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
                },
              ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildMemoryInfo(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        final notifier = ref.read(memoryDetailsNotifier.notifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgFrameBlueGray300,
                  height: 18.h,
                  width: 18.h,
                ),
                SizedBox(width: 6.h),
                Text(
                  'Invite Link',
                  style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300, height: 1.31),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              margin: EdgeInsets.only(right: 12.h),
              child: Row(
                spacing: 12.h,
                children: [
                  Expanded(
                    child: CustomEditText(
                      controller: state.inviteLinkController,
                      hintText: ImageConstant
                          .imgNetworkR812309r72309r572093t722323t23t23t08,
                      fillColor: appTheme.gray_900,
                      borderRadius: 8.h,
                      textStyle: TextStyleHelper
                          .instance.title16RegularPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                      readOnly: true,
                    ),
                  ),
                  // Copy button
                  GestureDetector(
                    onTap: () {
                      notifier.copyInviteLink();
                    },
                    child: CustomImageView(
                      imagePath: ImageConstant.imgIcon14,
                      height: 24.h,
                      width: 24.h,
                    ),
                  ),
                  // QR Code button
                  GestureDetector(
                    onTap: () {
                      notifier.showQRCodeBottomSheet(context);
                    },
                    child: Icon(
                      Icons.qr_code,
                      color: appTheme.gray_50,
                      size: 24.h,
                    ),
                  ),
                  // Native Share button with loading state
                  GestureDetector(
                    onTap: state.isSharing
                        ? null
                        : () {
                            notifier.shareMemoryNative();
                          },
                    child: state.isSharing
                        ? SizedBox(
                            width: 24.h,
                            height: 24.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                appTheme.gray_50,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.share,
                            color: appTheme.gray_50,
                            size: 24.h,
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Section Widget - UPDATED to show actual members and search/invite
  Widget _buildMembersList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        final notifier = ref.read(memoryDetailsNotifier.notifier);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgIconBlueGray30018x18,
                      height: 18.h,
                      width: 18.h,
                    ),
                    SizedBox(width: 6.h),
                    Text(
                      'Members (${state.memoryDetailsModel?.members?.length ?? 0})',
                      style: TextStyleHelper
                          .instance.title16RegularPlusJakartaSans
                          .copyWith(
                              color: appTheme.blue_gray_300, height: 1.31),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Show actual members list
            if (state.memoryDetailsModel?.members?.isNotEmpty ?? false) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: state.memoryDetailsModel!.members!.length,
                separatorBuilder: (context, index) => SizedBox(height: 6.h),
                itemBuilder: (context, index) {
                  final member = state.memoryDetailsModel!.members![index];
                  return MemberItemWidget(
                    member: member,
                    isCreator: state.isCreator,
                    onRemove: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: appTheme.gray_900_02,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.h),
                          ),
                          title: Text(
                            'Remove Member',
                            style: TextStyleHelper
                                .instance.title18BoldPlusJakartaSans
                                .copyWith(color: appTheme.gray_50),
                          ),
                          content: Text(
                            'Are you sure you want to remove ${member.name} from this memory?',
                            style: TextStyleHelper
                                .instance.body14RegularPlusJakartaSans
                                .copyWith(color: appTheme.gray_50),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(
                                'Cancel',
                                style: TextStyleHelper
                                    .instance.body14BoldPlusJakartaSans
                                    .copyWith(color: appTheme.blue_gray_300),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                if (member.userId != null) {
                                  notifier.removeMember(member.userId!);
                                }
                              },
                              child: Text(
                                'Remove',
                                style: TextStyleHelper
                                    .instance.body14BoldPlusJakartaSans
                                    .copyWith(color: appTheme.red_500),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 16.h),
            ],

            // Search and invite section (only for creator)
            if (state.isCreator) ...[
              Divider(color: appTheme.blue_gray_300.withAlpha(51)),
              SizedBox(height: 16.h),
              Text(
                'Invite Friends',
                style: TextStyleHelper.instance.title16RegularPlusJakartaSans
                    .copyWith(color: appTheme.blue_gray_300, height: 1.31),
              ),
              SizedBox(height: 12.h),

              // Search bar
              CustomSearchView(
                controller: state.searchController,
                placeholder: 'Search friends...',
                onChanged: (value) {
                  notifier.filterFriends(value);
                },
              ),
              SizedBox(height: 12.h),

              // Friends list for inviting
              if (state.isLoadingFriends)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          appTheme.deep_purple_A100),
                    ),
                  ),
                )
              else if (state.filteredFriendsList.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Center(
                    child: Text(
                      state.searchController?.text.isNotEmpty ?? false
                          ? 'No friends found'
                          : 'No friends to invite',
                      style: TextStyleHelper
                          .instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.blue_gray_300),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: state.filteredFriendsList.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final friend = state.filteredFriendsList[index];
                    final friendId = friend['id'] as String;
                    final isAlreadyMember =
                        state.memberUserIds.contains(friendId);

                    return Container(
                      padding: EdgeInsets.all(12.h),
                      decoration: BoxDecoration(
                        color: appTheme.gray_900,
                        borderRadius: BorderRadius.circular(8.h),
                        border: Border.all(
                          color: appTheme.blue_gray_300.withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.h),
                            child: CustomImageView(
                              imagePath: friend['avatar_url'] as String? ?? '',
                              height: 40.h,
                              width: 40.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12.h),

                          // Name
                          Expanded(
                            child: Text(
                              friend['display_name'] as String? ??
                                  friend['username'] as String? ??
                                  'Unknown',
                              style: TextStyleHelper
                                  .instance.body14MediumPlusJakartaSans
                                  .copyWith(color: appTheme.gray_50),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Invite button
                          if (isAlreadyMember)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.h,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: appTheme.green_500.withAlpha(26),
                                borderRadius: BorderRadius.circular(6.h),
                              ),
                              child: Text(
                                'Member',
                                style: TextStyleHelper
                                    .instance.body12BoldPlusJakartaSans
                                    .copyWith(color: appTheme.green_500),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: state.isInviting
                                  ? null
                                  : () {
                                      notifier.inviteFriendToMemory(friendId);
                                    },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.h,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      appTheme.deep_purple_A100.withAlpha(26),
                                  borderRadius: BorderRadius.circular(6.h),
                                  border: Border.all(
                                    color: appTheme.deep_purple_A100,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Invite',
                                  style: TextStyleHelper
                                      .instance.body12BoldPlusJakartaSans
                                      .copyWith(
                                    color: appTheme.deep_purple_A100,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(memoryDetailsNotifier);
        final notifier = ref.read(memoryDetailsNotifier.notifier);

        return Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancel',
                onPressed: () {
                  // Close bottom sheet without saving
                  Navigator.pop(context);
                },
                buttonStyle: CustomButtonStyle.fillDark,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: CustomButton(
                text: state.isSaving ? 'Saving...' : 'Save',
                onPressed: state.isSaving
                    ? null
                    : () async {
                        final success = await notifier.saveMemory();

                        if (success && context.mounted) {
                          // Close bottom sheet
                          Navigator.pop(context);

                          // Show success snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Memory updated successfully'),
                              backgroundColor: appTheme.colorFF52D1,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                isDisabled: state.isSaving,
                buttonStyle: CustomButtonStyle.fillSuccess,
                buttonTextStyle: CustomButtonTextStyle.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Navigates to search and add people screen
  void onTapSearchAddPeople(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appTheme.transparentCustom,
      builder: (context) => InvitePeopleScreen(),
    );
  }

  /// Handles member action tap
  void onTapMemberAction(BuildContext context) {
    // Handle member action
  }
}
