import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import '../qr_code_share_screen_two_screen/qr_code_share_screen_two_screen.dart';
import './notifier/friends_management_notifier.dart';
import './widgets/camera_scanner_screen.dart';
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
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(friendsManagementNotifier);
        final notifier = ref.read(friendsManagementNotifier.notifier);

        if (state.isCameraActive) {
          return CameraScannerScreen();
        }

        final isSearching = (state.searchResults?.isNotEmpty ?? false) ||
            (state.searchQuery.isNotEmpty);

        return Scaffold(
          backgroundColor: theme.colorScheme.onPrimaryContainer,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchBar(context, state, notifier),
                Expanded(
                  child: state.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _buildContent(context, state, notifier, isSearching),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Header section with title and action buttons (Figma original)
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Friends",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _openQRShareBottomSheet(context),
                child: Container(
                  width: 44.h,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                  child: Center(
                    child: CustomImageView(
                      imagePath: ImageConstant.imgButtons,
                      height: 24.h,
                      width: 24.h,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.h),
              GestureDetector(
                onTap: () =>
                    ref.read(friendsManagementNotifier.notifier).onCameraTap(),
                child: Container(
                  width: 44.h,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                  child: Center(
                    child: CustomImageView(
                      imagePath: ImageConstant.imgIconGray5042x42,
                      height: 24.h,
                      width: 24.h,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 0.h),
      child: CustomSearchView(
        placeholder: 'Search for friends...',
        onChanged: (value) {
          notifier.onSearchChanged(value);
        },
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
}