import 'package:flutter/services.dart';

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
  Map<String, int> _userTapCounts = {};
  bool _loading = true;
  final Map<String, GlobalKey> _reactionKeys = {};

  // Queue for pending database operations
  final List<Future<void>> _pendingOperations = [];
  bool _isProcessingQueue = false;

  @override
  void initState() {
    super.initState();
    _loadReactions();
    for (final reaction in Reactions.all) {
      _reactionKeys[reaction.id] = GlobalKey();
    }
  }

  @override
  void didUpdateWidget(StoryReactionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storyId != widget.storyId) {
      _loadReactions();
    }
  }

  Future<void> _loadReactions() async {
    setState(() => _loading = true);
    try {
      final counts = await _reactionService.getReactionCounts(widget.storyId);

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
      // Stronger haptic for "blocked" action
      await HapticFeedback.mediumImpact();

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

    // HAPTIC: immediate tactile response on valid tap
    await HapticFeedback.lightImpact();

    // Immediate visual feedback - show animation
    _showFloatingReaction(reaction);

    // Immediate counter update - no await
    setState(() {
      _counts[reaction.id] = (_counts[reaction.id] ?? 0) + 1;
      _userTapCounts[reaction.id] = (_userTapCounts[reaction.id] ?? 0) + 1;
    });

    // Queue database operation without blocking
    _queueReactionOperation(reaction);
  }

  void _queueReactionOperation(ReactionType reaction) {
    final operation = _reactionService
        .addReaction(
      storyId: widget.storyId,
      reactionType: reaction.id,
    )
        .then((success) {
      if (success) {
        widget.onReactionAdded?.call();
      }
      return success;
    }).catchError((e) {
      print('❌ ERROR adding reaction: $e');
      return false;
    });

    _pendingOperations.add(operation);

    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessingQueue = true;

    while (_pendingOperations.isNotEmpty) {
      final operation = _pendingOperations.removeAt(0);
      try {
        await operation;
      } catch (e) {
        print('❌ ERROR processing queued reaction: $e');
      }
    }

    _isProcessingQueue = false;

    // REMOVED: await _loadReactions() - this was causing widget to reload
    // Optimistic UI updates are sufficient; no need to sync back from server on every tap
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

    // Enhanced random offsets for more spread during rapid-fire
    final now = DateTime.now();
    final randomSeed = now.microsecond;
    final horizontalOffset = ((randomSeed % 80) - 40.0); // Range: -40 to +40
    final verticalOffset =
        ((randomSeed ~/ 100) % 30) - 15.0; // Range: -15 to +15
    final rotationOffset =
        ((randomSeed ~/ 200) % 60) - 30.0; // Range: -30 to +30 degrees

    // Slight variation in animation duration for more organic feel
    final baseDuration = 1500;
    final durationVariation = (randomSeed % 300) - 150; // ±150ms variation
    final animationDuration = baseDuration + durationVariation;

    overlayEntry = OverlayEntry(
      builder: (context) => FloatingReactionAnimation(
        emoji: reaction.display,
        startPosition: Offset(
          position.dx + size.width / 2 + horizontalOffset,
          position.dy + size.height / 2 + verticalOffset,
        ),
        rotationDegrees: rotationOffset,
        duration: Duration(milliseconds: animationDuration),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row: Text-only reactions (LOL, HOTT, WILD, OMG) - Full width distributed evenly
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Reactions.textReactions.map((reaction) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.h),
                child: _buildReactionButton(reaction, isTextReaction: true),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 12.h),
        // Bottom row: Emoji-only reactions with larger size - Full width distributed evenly
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Reactions.emojiReactions.map((reaction) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.h),
                child: _buildReactionButton(reaction, isTextReaction: false),
              ),
            );
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
          horizontal: isTextReaction ? 12.h : 8.h,
          vertical: isTextReaction ? 10.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: appTheme.whiteCustom.withAlpha(26),
          borderRadius: BorderRadius.circular(20.h),
        ),
        child: isTextReaction
            ? Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: isMaxedOut ? 0.5 : 1.0,
              child: Text(
                reaction.display,
                style: TextStyle(
                  fontSize: 16.fSize,
                  fontWeight: FontWeight.bold,
                  color: appTheme.whiteCustom,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 6.h),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12.fSize,
                fontWeight: FontWeight.bold,
                color: appTheme.whiteCustom.withAlpha(179),
              ),
            ),
          ],
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: isMaxedOut ? 0.5 : 1.0,
              child: Text(
                reaction.display,
                style: TextStyle(
                  fontSize: 32.fSize,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.bold,
                color: appTheme.whiteCustom.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingReactionAnimation extends StatefulWidget {
  final String emoji;
  final Offset startPosition;
  final double rotationDegrees;
  final Duration duration;
  final VoidCallback onComplete;

  const FloatingReactionAnimation({
    Key? key,
    required this.emoji,
    required this.startPosition,
    this.rotationDegrees = 0.0,
    this.duration = const Duration(milliseconds: 1500),
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
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
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

    // Rotation animation for more dynamic movement
    _rotationAnimation = Tween<double>(
      begin: widget.rotationDegrees * 3.14159 / 180, // Convert to radians
      end: 0.0, // Rotate back to normal
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

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
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Text(
                  widget.emoji,
                  style: TextStyle(
                    fontSize: 40.fSize,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
