import '../../../core/app_export.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_image_view.dart';
import '../models/friends_management_model.dart';
import '../notifier/friends_management_notifier.dart';

class UserSearchResultsWidget extends ConsumerWidget {
  const UserSearchResultsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsManagementNotifier);
    final searchResults = state.searchResults ?? [];

    if (state.isSearching ?? false) {
      return Center(
        child: CircularProgressIndicator(
          color: appTheme.deep_purple_A100,
        ),
      );
    }

    if (searchResults.isEmpty && (state.searchQuery?.isNotEmpty ?? false)) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text(
            'No users found',
            style:
                TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
              color: appTheme.gray_50,
            ),
          ),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: TextStyleHelper.instance.title16MediumPlusJakartaSans.copyWith(
            color: appTheme.gray_50,
          ),
        ),
        SizedBox(height: 12.h),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: searchResults.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final user = searchResults[index];
            return _buildUserSearchItem(context, ref, user);
          },
        ),
      ],
    );
  }

  Widget _buildUserSearchItem(
      BuildContext context, WidgetRef ref, SearchUserModel user) {
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: appTheme.gray_900_01,
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Row(
        children: [
          Container(
            width: 48.h,
            height: 48.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: appTheme.deep_purple_A100,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.h),
              child: CustomImageView(
                imagePath: user.profileImagePath ?? '',
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
                  user.displayName ?? user.userName ?? '',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(
                    color: appTheme.gray_50,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.userName != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '@${user.userName}',
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(
                      color: appTheme.gray_50.withAlpha(153),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.h),
          _buildActionButton(context, ref, user),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, WidgetRef ref, SearchUserModel user) {
    switch (user.friendshipStatus) {
      case 'friends':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
          decoration: BoxDecoration(
            color: appTheme.gray_50.withAlpha(26),
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Text(
            'Friends',
            style:
                TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
              color: appTheme.gray_50.withAlpha(153),
            ),
          ),
        );
      case 'request_sent':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
          decoration: BoxDecoration(
            color: appTheme.deep_orange_A700.withAlpha(26),
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Text(
            'Pending',
            style:
                TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
              color: appTheme.deep_orange_A700,
            ),
          ),
        );
      case 'request_received':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
          decoration: BoxDecoration(
            color: appTheme.deep_purple_A100.withAlpha(26),
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Text(
            'Respond',
            style:
                TextStyleHelper.instance.body12MediumPlusJakartaSans.copyWith(
              color: appTheme.deep_purple_A100,
            ),
          ),
        );
      default:
        return SizedBox(
          height: 32.h,
          child: CustomButton(
            text: 'Add',
            onPressed: () {
              if (user.id != null) {
                ref
                    .read(friendsManagementNotifier.notifier)
                    .onAcceptIncomingRequest(user.id!);
              }
            },
            buttonStyle: CustomButtonStyle.fillPrimary,
            buttonTextStyle: CustomButtonTextStyle.bodySmall,
          ),
        );
    }
  }
}