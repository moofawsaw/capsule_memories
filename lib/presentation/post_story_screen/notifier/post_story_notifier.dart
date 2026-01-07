import '../models/post_story_model.dart';
import '../../../core/app_export.dart';

part 'post_story_state.dart';

final postStoryNotifier =
    StateNotifierProvider.autoDispose<PostStoryNotifier, PostStoryState>(
  (ref) => PostStoryNotifier(
    PostStoryState(
      postStoryModel: PostStoryModel(),
    ),
  ),
);

class PostStoryNotifier extends StateNotifier<PostStoryState> {
  PostStoryNotifier(PostStoryState state) : super(state) {
    initialize();
  }

  void initialize() {
    state = state.copyWith(
      isLoading: false,
      selectedTool: null,
      selectedImagePath: null,
    );
  }

  void updateSelectedImage(String imagePath) {
    state = state.copyWith(
      selectedImagePath: imagePath,
      postStoryModel: state.postStoryModel?.copyWith(
        selectedImagePath: imagePath,
      ),
    );
  }

  void selectTool(String tool) {
    state = state.copyWith(
      selectedTool: tool,
      postStoryModel: state.postStoryModel?.copyWith(
        selectedTool: tool,
      ),
    );
  }

  void shareStory() {
    state = state.copyWith(
      isSharing: true,
    );

    // Simulate story sharing process
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        state = state.copyWith(
          isSharing: false,
          isShared: true,
        );
      }
    });
  }
}
