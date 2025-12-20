import '../../../core/app_export.dart';
import '../../../widgets/custom_friend_item.dart';
import '../notifier/friends_management_notifier.dart';

class SentRequestsSectionWidget extends ConsumerWidget {
  const SentRequestsSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: 4.h),
          child: Text(
            'Sent Requests',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        ),
        SizedBox(height: 10.h),
        Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(friendsManagementNotifier);
            final sentRequestsList = state.filteredSentRequestsList ??
                state.friendsManagementModel?.sentRequestsList ??
                [];

            if (sentRequestsList.isEmpty) {
              return Container(
                padding: EdgeInsets.all(20.h),
                child: Text(
                  'No sent requests',
                  style: TextStyleHelper.instance.body14,
                ),
              );
            }

            return Container(
              margin: EdgeInsets.only(left: 4.h),
              child: Column(
                spacing: 6.h,
                children: sentRequestsList
                    .map((request) => CustomFriendItem(
                          profileImagePath: request.profileImagePath ?? '',
                          userName: request.userName ?? '',
                          statusText: request.status,
                          onActionTap: () => ref
                              .read(friendsManagementNotifier.notifier)
                              .onRemoveSentRequest(request.id ?? ''),
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
