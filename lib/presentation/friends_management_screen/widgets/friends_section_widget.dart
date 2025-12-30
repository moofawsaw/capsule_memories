import '../../../core/app_export.dart';
import '../../../widgets/custom_confirmation_dialog.dart';
import '../../../widgets/custom_friend_item.dart';
import '../notifier/friends_management_notifier.dart';

class FriendsSectionWidget extends ConsumerWidget {
  const FriendsSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsManagementNotifier);
    final friends = state.filteredFriendsList ??
        state.friendsManagementModel?.friendsList ??
        [];

    if (state.isLoading ?? false) {
      return Center(
        child: CircularProgressIndicator(
          color: appTheme.deep_purple_A100,
        ),
      );
    }

    if (friends.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text(
            'No friends yet',
            style:
                TextStyleHelper.instance.body14RegularPlusJakartaSans.copyWith(
              color: appTheme.gray_50,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Friends (${friends.length})',
          style: TextStyleHelper.instance.title16MediumPlusJakartaSans.copyWith(
            color: appTheme.gray_50,
          ),
        ),
        SizedBox(height: 12.h),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: friends.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return CustomFriendItem(
              profileImagePath: friend.profileImagePath ?? '',
              userName: friend.displayName ?? friend.userName ?? '',
              onTap: () => _navigateToUserProfile(context, friend.id),
              onActionTap: () {
                _showRemoveFriendConfirmation(
                    context,
                    ref,
                    friend.friendshipId ?? '',
                    friend.displayName ?? friend.userName ?? '');
              },
            );
          },
        ),
      ],
    );
  }

  void _navigateToUserProfile(BuildContext context, String? userId) {
    if (userId != null && userId.isNotEmpty) {
      NavigatorService.pushNamed(
        AppRoutes.appProfileUser,
        arguments: userId,
      );
    }
  }

  void _showRemoveFriendConfirmation(BuildContext context, WidgetRef ref,
      String friendshipId, String userName) async {
    final confirmed = await CustomConfirmationDialog.show(
      context: context,
      title: 'Remove Friend',
      message: 'Are you sure you want to remove $userName from your friends?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
    );

    if (confirmed == true) {
      ref.read(friendsManagementNotifier.notifier).onRemoveFriend(friendshipId);
    }
  }
}
