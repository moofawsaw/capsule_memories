import '../../../core/app_export.dart';
import '../../../widgets/custom_confirmation_dialog.dart';
import '../../../widgets/custom_friend_request_card.dart';
import '../notifier/friends_management_notifier.dart';

class IncomingRequestsSectionWidget extends ConsumerWidget {
  const IncomingRequestsSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsManagementNotifier);
    final incomingRequests = state.filteredIncomingRequestsList ??
        state.friendsManagementModel?.incomingRequestsList ??
        [];

    if (incomingRequests.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incoming Requests (${incomingRequests.length})',
          style: TextStyleHelper.instance.title16MediumPlusJakartaSans.copyWith(
            color: appTheme.gray_50,
          ),
        ),
        SizedBox(height: 12.h),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: incomingRequests.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final request = incomingRequests[index];
            return CustomFriendRequestCard(
              profileImagePath: request.profileImagePath ?? '',
              userName: request.displayName ?? request.userName ?? '',
              buttonText: request.buttonText ?? 'Accept',
              onButtonPressed: () {
                ref
                    .read(friendsManagementNotifier.notifier)
                    .onAcceptIncomingRequest(request.id ?? '');
              },
              onSecondaryButtonTap: () {
                _showDeclineRequestConfirmation(context, ref, request.id ?? '',
                    request.displayName ?? request.userName ?? '');
              },
              onProfileTap: request.id != null && request.id!.isNotEmpty
                  ? () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.appProfileUser,
                        arguments: request.id,
                      );
                    }
                  : null,
            );
          },
        ),
      ],
    );
  }

  void _showDeclineRequestConfirmation(BuildContext context, WidgetRef ref,
      String requestId, String userName) async {
    final result = await CustomConfirmationDialog.show(
      context: context,
      title: 'Decline Request',
      message:
          'Are you sure you want to decline the friend request from $userName?',
      confirmText: 'Decline',
      cancelText: 'Cancel',
    );

    if (result == true) {
      ref
          .read(friendsManagementNotifier.notifier)
          .onDeclineIncomingRequest(requestId);
    }
  }
}
