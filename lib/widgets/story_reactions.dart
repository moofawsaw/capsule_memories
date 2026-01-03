import '../constants/reactions.dart';
import '../services/reaction_service.dart';
import '../core/app_export.dart';

class StoryReactionsWidget extends StatefulWidget {
  final String storyId;
  final VoidCallback? onReactionAdded;

  const StoryReactionsWidget({
    Key? key,
    required this.storyId,
    this.onReactionAdded,
  }) : super(key: key);

  @override
  State<StoryReactionsWidget> createState() => _StoryReactionsWidgetState();
}

class _StoryReactionsWidgetState extends State<StoryReactionsWidget> {
  final _reactionService = ReactionService();
  Map<String, int> _counts = {};
  Map<String, int> _userTapCounts = {}; // Track user's tap count per reaction
  bool _loading = true;
  final Map<String, GlobalKey> _reactionKeys = {};

  @override
  void initState() {
    super.initState();
    _loadReactions();
    // Initialize keys for each reaction
    for (final reaction in Reactions.all) {
      _reactionKeys[reaction.id] = GlobalKey();
    }
  }

  @override
  void didUpdateWidget(StoryReactionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload reactions when story ID changes
    if (oldWidget.storyId != widget.storyId) {
      _loadReactions();
    }
  }

  Future<void> _loadReactions() async {
    setState(() => _loading = true);
    try {
      // Get total reaction counts for this story
      final counts = await _reactionService.getReactionCounts(widget.storyId);

      // Get user's tap counts for each reaction type
      final userTapCounts = <String, int>{};
      for (final type in Reactions.all) {
        final userCount =
            await _reactionService.getUserTapCount(widget.storyId, type.id);
        if (userCount > 0) {
          userTapCounts[type.id] = userCount;
        }
      }

      setState(() {
        _counts = counts;
        _userTapCounts = userTapCounts;
        _loading = false;
      });
    } catch (e) {
      print('❌ ERROR loading reactions: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _onReactionTap(ReactionType reaction) async {
    // Check if user has reached max taps
    final currentUserTaps = _userTapCounts[reaction.id] ?? 0;
    if (currentUserTaps >= ReactionService.maxTapsPerUser) {
      // Show feedback that max taps reached
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Max ${ReactionService.maxTapsPerUser} taps reached for ${reaction.display}'),
          duration: const Duration(seconds: 1),
          backgroundColor: appTheme.colorFF3A3A,
        ),
      );
      return;
    }

    // Show floating animation
    _showFloatingReaction(reaction);

    // Optimistic update - increment counts
    setState(() {
      _counts[reaction.id] = (_counts[reaction.id] ?? 0) + 1;
      _userTapCounts[reaction.id] = (_userTapCounts[reaction.id] ?? 0) + 1;
    });

    try {
      final success = await _reactionService.addReaction(
        storyId: widget.storyId,
        reactionType: reaction.id,
      );

      if (!success) {
        // Max reached on server, reload to sync
        await _loadReactions();
      } else {
        widget.onReactionAdded?.call();
      }
    } catch (e) {
      print('❌ ERROR adding reaction: $e');
      // Revert on error
      await _loadReactions();
    }
  }

  void _showFloatingReaction(ReactionType reaction) {
    final key = _reactionKeys[reaction.id];
    if (key?.currentContext == null) return;

    final RenderBox renderBox =
        key!.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => FloatingReactionAnimation(
        emoji: reaction.display,
        startPosition: Offset(
          position.dx + size.width / 2,
          position.dy + size.height / 2,
        ),
        onComplete: () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 50.h,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: appTheme.whiteCustom,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Text-only reactions (LOL, HOTT, WILD, OMG)
        Wrap(
          spacing: 8.h,
          runSpacing: 8.h,
          children: Reactions.textReactions.map((reaction) {
            return _buildReactionButton(reaction, isTextReaction: true);
          }).toList(),
        ),
        SizedBox(height: 12.h),
        // Bottom row: Emoji-only reactions with larger size
        Wrap(
          spacing: 8.h,
          runSpacing: 8.h,
          children: Reactions.emojiReactions.map((reaction) {
            return _buildReactionButton(reaction, isTextReaction: false);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReactionButton(ReactionType reaction,
      {required bool isTextReaction}) {
    final count = _counts[reaction.id] ?? 0;
    final userTaps = _userTapCounts[reaction.id] ?? 0;
    final hasUserReacted = userTaps > 0;
    final isMaxedOut = userTaps >= ReactionService.maxTapsPerUser;

    return GestureDetector(
      key: _reactionKeys[reaction.id],
      onTap: () => _onReactionTap(reaction),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTextReaction ? 16.h : 12.h,
          vertical: isTextReaction ? 10.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: appTheme.whiteCustom.withAlpha(26),
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isMaxedOut ? 0.5 : 1.0,
              child: Text(
                reaction.display,
                style: TextStyle(
                  fontSize: isTextReaction ? 16.fSize : 32.fSize,
                  fontWeight:
                      isTextReaction ? FontWeight.bold : FontWeight.normal,
                  color: isTextReaction ? appTheme.whiteCustom : null,
                ),
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6.h),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: isTextReaction ? 14.fSize : 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: appTheme.whiteCustom.withAlpha(179),
                ),
              ),
            ],
            // Show user's tap count if they have reacted
            if (userTaps > 0) ...[
              SizedBox(width: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 2.h),
                decoration: BoxDecoration(
                  color: appTheme.colorFF3A3A,
                  borderRadius: BorderRadius.circular(10.h),
                ),
                child: Text(
                  userTaps.toString(),
                  style: TextStyle(
                    fontSize: 10.fSize,
                    fontWeight: FontWeight.bold,
                    color: appTheme.whiteCustom,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FloatingReactionAnimation extends StatefulWidget {
  final String emoji;
  final Offset startPosition;
  final VoidCallback onComplete;

  const FloatingReactionAnimation({
    Key? key,
    required this.emoji,
    required this.startPosition,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FloatingReactionAnimation> createState() =>
      _FloatingReactionAnimationState();
}

class _FloatingReactionAnimationState extends State<FloatingReactionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Upward movement animation (150 pixels up)
    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: -150.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Scale animation: grow then shrink
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 0.8)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70.0,
      ),
    ]).animate(_controller);

    // Fade out animation (starts fading after 50% of animation)
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx - 20.h,
          top: widget.startPosition.dy + _positionAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Text(
                widget.emoji,
                style: TextStyle(
                  fontSize: 40.fSize,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
