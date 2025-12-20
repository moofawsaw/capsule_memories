import '../../../core/app_export.dart';
import '../../../widgets/custom_user_list_item.dart';
import '../notifier/friends_management_notifier.dart';

class FriendsSectionWidget extends ConsumerWidget {
  const FriendsSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          margin: EdgeInsets.only(left: 4.h),
          child: Text('Friends',
              style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50))),
      SizedBox(height: 12.h),
      Consumer(builder: (context, ref, _) {
        final state = ref.watch(friendsManagementNotifier);
        final friendsList = state.filteredFriendsList ??
            state.friendsManagementModel?.friendsList ??
            [];

        if (friendsList.isEmpty) {
          return Container(
              padding: EdgeInsets.all(20.h),
              child: Text('No friends found',
                  style: TextStyleHelper.instance.body14));
        }

        return Container(
            margin: EdgeInsets.only(left: 4.h),
            child: Column(
                spacing: 6.h,
                children: friendsList
                    .map((friend) => CustomUserListItem(
                        imagePath: friend.profileImagePath ??
                            '', // Modified: Added required imagePath parameter
                        name: friend.userName ??
                            '', // Modified: Added required name parameter
                        onTap: () => ref
                            .read(friendsManagementNotifier.notifier)
                            .onFriendTap(friend.id ?? '')))
                    .toList()));
      }),
    ]);
  }
}
