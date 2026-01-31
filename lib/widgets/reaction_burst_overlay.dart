import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import '../core/app_export.dart';

class ReactionBurstOverlay {
  ReactionBurstOverlay._();
  static final ReactionBurstOverlay instance = ReactionBurstOverlay._();

  OverlayEntry? _entry;
  _ReactionBurstOverlayWidgetState? _state;

  void _ensureInserted(BuildContext context) {
    if (_entry != null) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (ctx) => _ReactionBurstOverlayWidget(
        onStateReady: (s) => _state = s,
      ),
    );

    overlay.insert(_entry!);
  }

  void emit({
    required BuildContext context,
    required String emoji,
    required Offset startGlobal,
    double fontSize = 40,
    int? seed,
  }) {
    _ensureInserted(context);
    _state?.emit(
      emoji: emoji,
      startGlobal: startGlobal,
      fontSize: fontSize,
      seed: seed,
    );
  }
}

typedef _StateReady = void Function(_ReactionBurstOverlayWidgetState state);

class _ReactionBurstOverlayWidget extends StatefulWidget {
  final _StateReady onStateReady;

  const _ReactionBurstOverlayWidget({
    required this.onStateReady,
  });

  @override
  State<_ReactionBurstOverlayWidget> createState() =>
      _ReactionBurstOverlayWidgetState();
}

class _EmojiGlyph {
  final TextPainter painter;
  final Size size;

  const _EmojiGlyph(this.painter, this.size);
}

class _Particle {
  final String emoji;
  final Offset start;
  final double fontSize;
  final double dx;
  final double dy;
  final double rotationStart;
  final Duration duration;
  final int bornMicros;

  const _Particle({
    required this.emoji,
    required this.start,
    required this.fontSize,
    required this.dx,
    required this.dy,
    required this.rotationStart,
    required this.duration,
    required this.bornMicros,
  });
}

class _ReactionBurstOverlayWidgetState extends State<_ReactionBurstOverlayWidget>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = <_Particle>[];
  final Map<String, _EmojiGlyph> _glyphCache = <String, _EmojiGlyph>{};

  Ticker? _ticker;
  int _nowMicros = DateTime.now().microsecondsSinceEpoch;
  bool _ticking = false;

  @override
  void initState() {
    super.initState();
    widget.onStateReady(this);
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    _nowMicros = DateTime.now().microsecondsSinceEpoch;
    if (!mounted) return;

    // Remove expired particles.
    _particles.removeWhere((p) {
      final age = Duration(microseconds: _nowMicros - p.bornMicros);
      return age >= p.duration;
    });

    if (_particles.isEmpty) {
      _stopTicking();
      return;
    }

    // Repaint only this overlay.
    setState(() {});
  }

  void _startTicking() {
    if (_ticking) return;
    _ticking = true;
    _ticker?.start();
  }

  void _stopTicking() {
    if (!_ticking) return;
    _ticking = false;
    _ticker?.stop();
  }

  _EmojiGlyph _glyphFor(String emoji, double fontSize) {
    // Cache key by emoji+fontSize
    final key = '$emoji|$fontSize';
    final cached = _glyphCache[key];
    if (cached != null) return cached;

    final tp = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: fontSize,
          decoration: TextDecoration.none,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final glyph = _EmojiGlyph(tp, tp.size);
    _glyphCache[key] = glyph;
    return glyph;
  }

  void emit({
    required String emoji,
    required Offset startGlobal,
    required double fontSize,
    int? seed,
  }) {
    final s = seed ?? DateTime.now().microsecondsSinceEpoch;
    final r = math.Random(s);

    // Randomize trajectory a bit.
    final dx = (r.nextDouble() * 80.0) - 40.0;
    final dy = -140.0 - (r.nextDouble() * 80.0); // upward
    final rot = ((r.nextDouble() * 60.0) - 30.0) * math.pi / 180.0;
    final durationMs = 1050 + r.nextInt(550); // 1.05s - 1.6s

    _particles.add(
      _Particle(
        emoji: emoji,
        start: startGlobal,
        fontSize: fontSize,
        dx: dx,
        dy: dy,
        rotationStart: rot,
        duration: Duration(milliseconds: durationMs),
        bornMicros: DateTime.now().microsecondsSinceEpoch,
      ),
    );

    _startTicking();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: isolate this overlay from the rest of the UI (and the video texture)
    // so only this layer repaints.
    return IgnorePointer(
      ignoring: true,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ReactionBurstPainter(
            particles: _particles,
            nowMicros: _nowMicros,
            glyphFor: _glyphFor,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ReactionBurstPainter extends CustomPainter {
  final List<_Particle> particles;
  final int nowMicros;
  final _EmojiGlyph Function(String emoji, double fontSize) glyphFor;

  const _ReactionBurstPainter({
    required this.particles,
    required this.nowMicros,
    required this.glyphFor,
  });

  double _easeOutCubic(double t) {
    final p = (t - 1.0);
    return p * p * p + 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final age = Duration(microseconds: nowMicros - p.bornMicros);
      final tRaw = age.inMicroseconds / p.duration.inMicroseconds;
      final t = tRaw.clamp(0.0, 1.0);

      final ease = _easeOutCubic(t);
      final x = p.start.dx + (p.dx * ease);
      final y = p.start.dy + (p.dy * ease);

      final opacity = (1.0 - (t * 1.05)).clamp(0.0, 1.0);
      final scale = (1.0 + (0.45 * (1.0 - t))).clamp(0.65, 1.55);
      final rot = p.rotationStart * (1.0 - t);

      final glyph = glyphFor(p.emoji, p.fontSize);
      final halfW = glyph.size.width / 2.0;
      final halfH = glyph.size.height / 2.0;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.scale(scale, scale);

      // Opacity via layer save
      final paint = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.saveLayer(
        Rect.fromLTWH(-halfW - 4, -halfH - 4, glyph.size.width + 8, glyph.size.height + 8),
        paint,
      );

      glyph.painter.paint(canvas, Offset(-halfW, -halfH));
      canvas.restore(); // layer
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ReactionBurstPainter oldDelegate) {
    // We repaint every tick while there are particles.
    return true;
  }
}

