import '../../../core/app_export.dart';
import '../../../widgets/custom_confirmation_dialog.dart';
import '../../../widgets/custom_friend_request_card.dart';
import '../notifier/friends_management_notifier.dart';

class SentRequestsSectionWidget extends ConsumerWidget {
  const SentRequestsSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsManagementNotifier);
    final sentRequests = state.filteredSentRequestsList ?? [];

    if (sentRequests.isEmpty) {
      return const SizedBox.shrink();
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
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sentRequests.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final request = sentRequests[index];

            // IMPORTANT:
            // Use the *target user's id* here.
            // If your model has something like request.userId / request.toUserId / request.recipientId,
            // use that instead of request.id.
            final String targetUserId =
                (request.userId as String?) ?? (request.id ?? '');

            final String displayName =
                request.displayName ?? request.userName ?? '';

            return InkWell(
              borderRadius: BorderRadius.circular(12.h),
              onTap: () {
                if (targetUserId.isEmpty) return;

                Navigator.of(context).pushNamed(
                  AppRoutes.appProfileUser,
                  arguments: <String, dynamic>{
                    'userId': targetUserId,
                  },
                );
              },
              child: CustomFriendRequestCard(
                profileImagePath: request.profileImagePath ?? '',
                userName: displayName,
                buttonText: 'Cancel',
                onButtonPressed: () {
                  _showCancelRequestConfirmation(
                    context,
                    ref,
                    request.id ?? '',
                    displayName,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCancelRequestConfirmation(
      BuildContext context,
      WidgetRef ref,
      String requestId,
      String userName,
      ) {
    CustomConfirmationDialog.show(
      context: context,
      title: 'Cancel Request',
      message: 'Are you sure you want to cancel the friend request to $userName?',
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
