import 'package:flutter/services.dart';
import '../models/share_story_model.dart';
import '../models/contact_model.dart';
import '../../../core/app_export.dart';

part 'share_story_state.dart';

final shareStoryNotifier =
    StateNotifierProvider.autoDispose<ShareStoryNotifier, ShareStoryState>(
  (ref) => ShareStoryNotifier(
    ShareStoryState(
      shareStoryModel: ShareStoryModel(),
    ),
  ),
);

class ShareStoryNotifier extends StateNotifier<ShareStoryState> {
  ShareStoryNotifier(ShareStoryState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      searchController: TextEditingController(),
      isLoading: false,
    );
  }

  void searchContacts(String query) {
    final allContacts = state.shareStoryModel?.contacts ?? [];

    if (query.isEmpty) {
      state = state.copyWith(
        shareStoryModel: state.shareStoryModel?.copyWith(
          filteredContacts: allContacts,
          searchQuery: query,
        ),
      );
    } else {
      final filteredContacts = allContacts
          .where((contact) =>
              contact.name?.toLowerCase().contains(query.toLowerCase()) ??
              false)
          .toList();

      state = state.copyWith(
        shareStoryModel: state.shareStoryModel?.copyWith(
          filteredContacts: filteredContacts,
          searchQuery: query,
        ),
      );
    }
  }

  void toggleContactSelection(int index) {
    final filteredContacts =
        List<ContactModel>.from(state.shareStoryModel?.filteredContacts ?? []);
    final allContacts =
        List<ContactModel>.from(state.shareStoryModel?.contacts ?? []);

    if (index >= 0 && index < filteredContacts.length) {
      final selectedContact = filteredContacts[index];
      final updatedContact = selectedContact.copyWith(
        isSelected: !(selectedContact.isSelected ?? false),
      );

      // Update in filtered list
      filteredContacts[index] = updatedContact;

      // Update in main contacts list
      final mainIndex = allContacts
          .indexWhere((contact) => contact.name == selectedContact.name);
      if (mainIndex != -1) {
        allContacts[mainIndex] = updatedContact;
      }

      state = state.copyWith(
        shareStoryModel: state.shareStoryModel?.copyWith(
          contacts: allContacts,
          filteredContacts: filteredContacts,
        ),
      );
    }
  }

  void copyStoryLink() {
    const storyLink = 'https://capsule.app/story/shared/12345';
    Clipboard.setData(ClipboardData(text: storyLink));
  }

  void downloadStory() {
    // Simulate story download
    state = state.copyWith(isLoading: true);

    Future.delayed(Duration(seconds: 1), () {
      state = state.copyWith(
        isLoading: false,
        isDownloadComplete: true,
      );
    });
  }

  @override
  void dispose() {
    state.searchController?.dispose();
    super.dispose();
  }
}
