import 'package:flutter/services.dart';

import '../constants/reactions.dart';
import '../services/reaction_service.dart';
import '../services/reaction_preloader.dart';
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

    for (final reaction in Reactions.all) {
      _reactionKeys[reaction.id] = GlobalKey();
    }

    _primeFromCacheAndFetch();
  }

  @override
  void didUpdateWidget(StoryReactionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storyId != widget.storyId) {
      _primeFromCacheAndFetch();
    }
  }

  void _primeFromCacheAndFetch() {
    // 1) Show cache immediately (if available)
    final cached = ReactionPreloader.instance.getCached(widget.storyId);
    if (cached != null) {
      _counts = Map<String, int>.from(cached.counts);
      _userTapCounts = Map<String, int>.from(cached.userTapCounts);
      _loading = false;
      if (mounted) setState(() {});
    } else {
      _loading = true;
      if (mounted) setState(() {});
    }

    // 2) Fetch (deduped). If cache was stale, this refreshes quickly.
    _loadReactionsFast();
  }

  Future<void> _loadReactionsFast() async {
    try {
      final snap = await ReactionPreloader.instance.fetch(widget.storyId);
      if (!mounted) return;

      setState(() {
        _counts = Map<String, int>.from(snap.counts);
        _userTapCounts = Map<String, int>.from(snap.userTapCounts);
        _loading = false;
      });
    } catch (e) {
      print('❌ ERROR loading reactions: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _onReactionTap(ReactionType reaction) async {
    final currentUserTaps = _userTapCounts[reaction.id] ?? 0;
    if (currentUserTaps >= ReactionService.maxTapsPerUser) {
      await HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Max ${ReactionService.maxTapsPerUser} taps reached for ${reaction.display}',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: appTheme.colorFF3A3A,
        ),
      );
      return;
    }

    await HapticFeedback.lightImpact();

    _showFloatingReaction(reaction);

    // Optimistic UI update
    setState(() {
      _counts[reaction.id] = (_counts[reaction.id] ?? 0) + 1;
      _userTapCounts[reaction.id] = (_userTapCounts[reaction.id] ?? 0) + 1;
    });

    // Keep cache aligned so next open is instant
    ReactionPreloader.instance.upsertLocal(
      storyId: widget.storyId,
      reactionType: reaction.id,
      deltaTotal: 1,
      deltaUser: 1,
    );

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
    })
        .catchError((e) {
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

    final now = DateTime.now();
    final randomSeed = now.microsecond;
    final horizontalOffset = ((randomSeed % 80) - 40.0);
    final verticalOffset = ((randomSeed ~/ 100) % 30) - 15.0;
    final rotationOffset = ((randomSeed ~/ 200) % 60) - 30.0;

    final baseDuration = 1500;
    final durationVariation = (randomSeed % 300) - 150;
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

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: -150.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

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

    _rotationAnimation = Tween<double>(
      begin: widget.rotationDegrees * 3.14159 / 180,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

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
