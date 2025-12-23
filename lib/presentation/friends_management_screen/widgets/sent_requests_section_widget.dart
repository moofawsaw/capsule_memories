import '../../../core/app_export.dart';
import '../../../widgets/custom_confirmation_dialog.dart';
import '../../../widgets/custom_friend_request_card.dart';
import '../notifier/friends_management_notifier.dart';

class SentRequestsSectionWidget extends ConsumerWidget {
  const SentRequestsSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsManagementNotifier);
    final sentRequests = state.filteredSentRequestsList ??
        state.friendsManagementModel?.sentRequestsList ??
        [];

    if (sentRequests.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sent Requests (${sentRequests.length})',
          style: TextStyleHelper.instance.title16MediumPlusJakartaSans.copyWith(
            color: appTheme.gray_50,
          ),
        ),
        SizedBox(height: 12.h),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sentRequests.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final request = sentRequests[index];
            return CustomFriendRequestCard(
              profileImagePath: request.profileImagePath ?? '',
              userName: request.displayName ?? request.userName ?? '',
              buttonText: 'Cancel',
              onButtonPressed: () {
                _showCancelRequestConfirmation(context, ref, request.id ?? '',
                    request.displayName ?? request.userName ?? '');
              },
            );
          },
        ),
      ],
    );
  }

  void _showCancelRequestConfirmation(
      BuildContext context, WidgetRef ref, String requestId, String userName) {
    CustomConfirmationDialog.show(
      context: context,
      title: 'Cancel Request',
      message:
          'Are you sure you want to cancel the friend request to $userName?',
      confirmText: 'Cancel Request',
      cancelText: 'Keep',
    ).then((confirmed) {
      if (confirmed == true) {
        ref
            .read(friendsManagementNotifier.notifier)
            .onRemoveSentRequest(requestId);
      }
    });
  }
}