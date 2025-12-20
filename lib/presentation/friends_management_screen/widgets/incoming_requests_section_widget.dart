import '../../../core/app_export.dart';
import '../../../widgets/custom_friend_request_card.dart';
import '../notifier/friends_management_notifier.dart';

class IncomingRequestsSectionWidget extends ConsumerWidget {
  const IncomingRequestsSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: 4.h),
          child: Text(
            'Incoming Requests',
            style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        ),
        SizedBox(height: 10.h),
        Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(friendsManagementNotifier);
            final incomingRequestsList = state.filteredIncomingRequestsList ??
                state.friendsManagementModel?.incomingRequestsList ??
                [];

            if (incomingRequestsList.isEmpty) {
              return Container(
                padding: EdgeInsets.all(20.h),
                child: Text(
                  'No incoming requests',
                  style: TextStyleHelper.instance.body14,
                ),
              );
            }

            return Container(
              margin: EdgeInsets.only(left: 4.h),
              child: Column(
                spacing: 6.h,
                children: incomingRequestsList
                    .map((request) => CustomFriendRequestCard(
                          profileImagePath: request.profileImagePath,
                          userName: request.userName,
                          buttonText: request.buttonText,
                          onButtonPressed: () => ref
                              .read(friendsManagementNotifier.notifier)
                              .onAcceptIncomingRequest(request.id ?? ''),
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
