import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_search_view.dart';
import '../qr_code_share_screen_two_screen/qr_code_share_screen_two_screen.dart';
import './notifier/friends_management_notifier.dart';
import './widgets/friends_section_widget.dart';
import './widgets/incoming_requests_section_widget.dart';
import './widgets/sent_requests_section_widget.dart';
import './widgets/user_search_results_widget.dart';

class FriendsManagementScreen extends ConsumerStatefulWidget {
  const FriendsManagementScreen({Key? key}) : super(key: key);

  @override
  FriendsManagementScreenState createState() => FriendsManagementScreenState();
}

class FriendsManagementScreenState
    extends ConsumerState<FriendsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsManagementNotifier.notifier).initialize();
    });
  }

  @override
  void dispose() {
    // Clean up camera when leaving screen
    ref.read(friendsManagementNotifier.notifier).closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(friendsManagementNotifier);
        final notifier = ref.read(friendsManagementNotifier.notifier);

        final isSearching = (state.searchResults?.isNotEmpty ?? false) ||
            (state.searchQuery.isNotEmpty);

        return Scaffold(
          backgroundColor: theme.colorScheme.onPrimaryContainer,
          appBar: CustomAppBar(
            layoutType: CustomAppBarLayoutType.titleWithLeading,
            title: "Friends",
            leadingIcon: ImageConstant.imgButtons,
            onLeadingTap: () => _openQRShareBottomSheet(context),
            actionIcons: [
              ImageConstant.imgIconGray5042x42, // Camera scan icon
            ],
          ),
          body: Column(
            children: [
              _buildSearchBar(context, state, notifier),
              Expanded(
                child: state.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _buildContent(context, state, notifier, isSearching),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic state,
    FriendsManagementNotifier notifier,
    bool isSearching,
  ) {
    if (isSearching) {
      return UserSearchResultsWidget();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          FriendsSectionWidget(),
          SentRequestsSectionWidget(),
          IncomingRequestsSectionWidget(),
        ],
      ),
    );
  }

  /// Search bar with search query and results
  Widget _buildSearchBar(
      BuildContext context, dynamic state, FriendsManagementNotifier notifier) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: CustomSearchView(
              placeholder: 'Search for friends...',
              onChanged: (value) {
                notifier.onSearchChanged(value);
              },
            ),
          ),
          if (state.searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close,
                  color: theme.colorScheme.onPrimaryContainer),
              onPressed: () {
                notifier.onSearchChanged('');
              },
            ),
        ],
      ),
    );
  }

  /// Open QR share bottom sheet
  void _openQRShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QRCodeShareScreenTwoScreen(),
    );
  }

  /// Handle camera action
  void onTapCameraButton(BuildContext context) {
    ref.read(friendsManagementNotifier.notifier).onCameraTap();
  }
}
