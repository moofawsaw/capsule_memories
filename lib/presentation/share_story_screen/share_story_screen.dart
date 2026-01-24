import 'package:flutter/services.dart';
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
  // ✅ Uses capapp.co, not capsulememories.app
  static const String _shareDomain = 'https://capapp.co';

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

                    // ✅ IMPORTANT: your original file defined these but never rendered them.
                    // Without this, you only ever run the "Done" header tap and your share
                    // logic is effectively disconnected from the UI.
                    _buildActionButtons(context),

                    SizedBox(height: 16.h),
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
                  children: [
                    Icon(
                      Icons.share,
                      size: 20.h,
                      color: appTheme.gray_50,
                    ),
                    SizedBox(width: 8.h),
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
          SizedBox(width: 16.h),
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
                child: Icon(
                  Icons.content_copy,
                  size: 20.h,
                  color: appTheme.gray_50,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.h),
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
                child: Icon(
                  Icons.download,
                  size: 20.h,
                  color: appTheme.gray_50,
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

  // =========================
  // ✅ SHARE (UPDATED)
  // =========================

  /// Tries to pull storyId from the current route args.
  /// This matches your deep link / story viewer pattern where the story viewer is opened with:
  /// - String storyId, OR
  /// - FeedStoryContext (initialStoryId), OR
  /// - Map {storyId: ...}
  String? _tryGetStoryIdFromRouteArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is String && args.isNotEmpty) return args;

    // If you have FeedStoryContext available in this file, you can uncomment this:
    // if (args is FeedStoryContext && args.initialStoryId.isNotEmpty) {
    //   return args.initialStoryId;
    // }

    if (args is Map) {
      final map = args.cast<String, dynamic>();
      final v = map['storyId'];
      if (v is String && v.isNotEmpty) return v;
    }

    // Fallback: notifier should ideally provide this (recommended).
    // return ref.read(shareStoryNotifier).shareStoryModel?.storyId;
    return null;
  }

  String _buildStoryShareUrl(String storyId) {
    // ✅ canonical short link
    return '$_shareDomain/s/$storyId';
  }

  /// Handles share button tap
  void onTapShare(BuildContext context) {
    final storyId = _tryGetStoryIdFromRouteArgs(context);

    if (storyId == null || storyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No story selected to share'),
          backgroundColor: appTheme.colorFF3A3A,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final url = _buildStoryShareUrl(storyId);

    final selectedContacts = ref
        .read(shareStoryNotifier)
        .shareStoryModel
        ?.contacts
        ?.where((contact) => contact.isSelected ?? false)
        .toList() ??
        [];

    // Keep the message minimal so the receiver app uses the OG preview.
    // Including media attachments often changes iMessage behavior (camera/media composer UI).
    final message = url;

    final subject = selectedContacts.isNotEmpty
        ? 'Story shared with: ${selectedContacts.map((c) => c.name ?? '').where((n) => n.isNotEmpty).join(', ')}'
        : 'Check out this story on Capsule';

    Share.share(
      message,
      subject: subject,
    );
  }

  /// Handles copy link button tap
  void onTapCopyLink(BuildContext context) {
    final storyId = _tryGetStoryIdFromRouteArgs(context);

    if (storyId == null || storyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No story selected to copy'),
          backgroundColor: appTheme.colorFF3A3A,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final url = _buildStoryShareUrl(storyId);

    Clipboard.setData(ClipboardData(text: url));
    ref.read(shareStoryNotifier.notifier).copyStoryLink();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied to clipboard'),
        backgroundColor: appTheme.colorFF52D1,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handles download button tap
  void onTapDownload(BuildContext context) {
    ref.read(shareStoryNotifier.notifier).downloadStory();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Story downloaded successfully'),
        backgroundColor: appTheme.colorFF52D1,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
