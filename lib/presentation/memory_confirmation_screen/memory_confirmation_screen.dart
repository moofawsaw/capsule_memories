import 'dart:math' as math;

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../memory_share_options_screen/memory_share_options_screen.dart';

class MemoryConfirmationScreen extends ConsumerStatefulWidget {
  const MemoryConfirmationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MemoryConfirmationScreen> createState() =>
      _MemoryConfirmationScreenState();
}

class _MemoryConfirmationScreenState
    extends ConsumerState<MemoryConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Generate confetti particles
    _generateConfetti();

    // Start confetti animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiController.forward();
      }
    });
  }

  void _generateConfetti() {
    final random = math.Random();
    final colors = [
      appTheme.deep_purple_A100,
      appTheme.deep_purple_A200,
      Colors.amber,
      Colors.pink,
      Colors.cyan,
      Colors.orange,
    ];

    for (int i = 0; i < 50; i++) {
      _particles.add(
        ConfettiParticle(
          color: colors[random.nextInt(colors.length)],
          startX: random.nextDouble(),
          startY: -0.1,
          endY: 1.2 + random.nextDouble() * 0.3,
          rotation: random.nextDouble() * 4 * math.pi,
          size: 8.0 + random.nextDouble() * 8.0,
          drift: (random.nextDouble() - 0.5) * 0.3,
        ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get memory details from navigation arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final memoryId = args?['memory_id'] as String? ?? '';
    final memoryName = args?['memory_name'] as String? ?? '';

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      appBar: AppBar(
        backgroundColor: appTheme.gray_900_02,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: appTheme.gray_50),
            onPressed: () {
              // Close confirmation screen and go back to feed
              NavigatorService.goBack();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Success Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      appTheme.deep_purple_A100,
                      appTheme.deep_purple_A200
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                margin: EdgeInsets.all(20.h),
                child: Column(
                  children: [
                    Icon(Icons.check_circle,
                        color: appTheme.gray_50, size: 48.h),
                    SizedBox(height: 16.h),
                    Text(
                      'Memory Created!',
                      style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      memoryName,
                      style: TextStyleHelper
                          .instance.title16MediumPlusJakartaSans
                          .copyWith(color: appTheme.gray_50),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your memory is now active with a 12-hour posting window for contributions',
                      style: TextStyleHelper
                          .instance.body14RegularPlusJakartaSans
                          .copyWith(color: appTheme.gray_50.withAlpha(179)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Embedded Memory Share Options
              Expanded(
                child: MemoryShareOptionsScreen(),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.all(20.h),
                decoration: BoxDecoration(
                  color: appTheme.gray_900_01,
                  border: Border(
                    top: BorderSide(
                      color: appTheme.blue_gray_300.withAlpha(77),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: CustomButton(
                    text: 'Start Adding Stories',
                    buttonStyle: CustomButtonStyle.fillPrimary,
                    buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                    onPressed: () {
                      // Navigate to camera interface
                      NavigatorService.pushNamed(AppRoutes.appStoryRecord);
                    },
                    padding:
                        EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.h),
                  ),
                ),
              ),
            ],
          ),

          // Confetti overlay
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Confetti particle model
class ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double endY;
  final double rotation;
  final double size;
  final double drift;

  ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endY,
    required this.rotation,
    required this.size,
    required this.drift,
  });
}

// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      // Calculate particle position
      final x = (particle.startX + particle.drift * progress) * size.width;
      final y =
          (particle.startY + (particle.endY - particle.startY) * progress) *
              size.height;

      // Calculate rotation
      final rotation = particle.rotation * progress;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw confetti piece (rectangle or circle)
      final isCircle = particle.size % 2 == 0;
      if (isCircle) {
        canvas.drawCircle(
          Offset.zero,
          particle.size / 2,
          paint,
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
