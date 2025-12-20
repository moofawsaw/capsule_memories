import 'package:share_plus/share_plus.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_search_view.dart';
import './widgets/contact_item_widget.dart';
import 'notifier/share_story_notifier.dart';

class ShareStoryScreen extends ConsumerStatefulWidget {
  ShareStoryScreen({Key? key}) : super(key: key);

  @override
  ShareStoryScreenState createState() => ShareStoryScreenState();
}

class ShareStoryScreenState extends ConsumerState<ShareStoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: appTheme.gray_900_02,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.h),
            topRight: Radius.circular(20.h),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            // Drag handle indicator
            Container(
              width: 48.h,
              height: 5.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF3A3A,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            SizedBox(height: 20.h),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    SizedBox(height: 24.h),
                    _buildSearchSection(context),
                    SizedBox(height: 24.h),
                    _buildContactsList(context),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header section with title and done button
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 20.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appTheme.colorFF2A27,
            width: 1.h,
          ),
        ),
      ),
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(shareStoryNotifier);
          final selectedCount = state.shareStoryModel?.contacts
                  ?.where((contact) => contact.isSelected ?? false)
                  .length ??
              0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Story',
                    style: TextStyleHelper.instance.title20Bold,
                  ),
                  Text(
                    '($selectedCount) selected',
                    style: TextStyleHelper.instance.body14Regular,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => onTapDone(context),
                child: Text(
                  'Done',
                  style: TextStyleHelper.instance.title16SemiBold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Search section
  Widget _buildSearchSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 22.h, vertical: 16.h),
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(shareStoryNotifier);

          return CustomSearchView(
            controller: state.searchController,
            placeholder: 'Search contacts...',
            onChanged: (value) {
              ref.read(shareStoryNotifier.notifier).searchContacts(value);
            },
          );
        },
      ),
    );
  }

  /// Contacts grid section
  Widget _buildContactsList(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(shareStoryNotifier);
        final filteredContacts = state.shareStoryModel?.filteredContacts ?? [];

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20.h,
            mainAxisSpacing: 24.h,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredContacts.length,
          itemBuilder: (context, index) {
            final contact = filteredContacts[index];
            return ContactItemWidget(
              contact: contact,
              onTap: () {
                ref
                    .read(shareStoryNotifier.notifier)
                    .toggleContactSelection(index);
              },
            );
          },
        );
      },
    );
  }

  /// Action buttons section
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(22.h),
      child: Row(
        spacing: 16.h,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTapShare(context),
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: appTheme.colorFF8B5C,
                  borderRadius: BorderRadius.circular(28.h),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8.h,
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.imgShareIcon,
                      height: 20.h,
                      width: 20.h,
                    ),
                    Text(
                      'Share',
                      style: TextStyleHelper.instance.title16SemiBold
                          .copyWith(color: appTheme.gray_50),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onTapCopyLink(context),
            child: Container(
              height: 56.h,
              width: 56.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF2A27,
                borderRadius: BorderRadius.circular(28.h),
              ),
              child: Center(
                child: CustomImageView(
                  imagePath: ImageConstant.imgCopyIcon,
                  height: 20.h,
                  width: 20.h,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onTapDownload(context),
            child: Container(
              height: 56.h,
              width: 56.h,
              decoration: BoxDecoration(
                color: appTheme.colorFF2A27,
                borderRadius: BorderRadius.circular(28.h),
              ),
              child: Center(
                child: CustomImageView(
                  imagePath: ImageConstant.imgDownloadIcon,
                  height: 20.h,
                  width: 20.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles done button tap
  void onTapDone(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles share button tap
  void onTapShare(BuildContext context) {
    final selectedContacts = ref
            .read(shareStoryNotifier)
            .shareStoryModel
            ?.contacts
            ?.where((contact) => contact.isSelected ?? false)
            .toList() ??
        [];

    if (selectedContacts.isNotEmpty) {
      final contactNames =
          selectedContacts.map((contact) => contact.name ?? '').join(', ');

      Share.share(
        'Check out this story!',
        subject: 'Story shared with: $contactNames',
      );
    }
  }

  /// Handles copy link button tap
  void onTapCopyLink(BuildContext context) {
    ref.read(shareStoryNotifier.notifier).copyStoryLink();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: appTheme.colorFF52D1,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Handles download button tap
  void onTapDownload(BuildContext context) {
    ref.read(shareStoryNotifier.notifier).downloadStory();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Story downloaded successfully'),
        backgroundColor: appTheme.colorFF52D1,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
