import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_button.dart';
import '../notifier/friends_management_notifier.dart';

class CameraScannerScreen extends ConsumerStatefulWidget {
  const CameraScannerScreen({Key? key}) : super(key: key);

  @override
  CameraScannerScreenState createState() => CameraScannerScreenState();
}

class CameraScannerScreenState extends ConsumerState<CameraScannerScreen> {
  bool isFlashOn = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsManagementNotifier);
    final cameraController = state.cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return Scaffold(
        backgroundColor: appTheme.gray_900_02,
        body: Center(
          child: CircularProgressIndicator(
            color: appTheme.deep_purple_A100,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: appTheme.gray_900_02,
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: CameraPreview(cameraController),
          ),

          // Scanning overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomIconButton(
                      height: 44.h,
                      width: 44.h,
                      iconPath: '',
                      backgroundColor: appTheme.gray_900_01.withAlpha(179),
                      borderRadius: 22.h,
                      iconSize: 24.h,
                      onTap: () => Navigator.pop(context),
                    ),
                    if (!kIsWeb) // Flash not supported on web
                      CustomIconButton(
                        height: 44.h,
                        width: 44.h,
                        iconPath: '',
                        backgroundColor: appTheme.gray_900_01.withAlpha(179),
                        borderRadius: 22.h,
                        iconSize: 24.h,
                        onTap: _toggleFlash,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 80.h,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 32.h),
              child: Text(
                'Position QR code within the frame to scan',
                textAlign: TextAlign.center,
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans.copyWith(
                  color: appTheme.white_A700,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(128),
                      offset: Offset(0, 2.h),
                      blurRadius: 4.h,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (kIsWeb) return; // Flash not supported on web

    final cameraController =
        ref.read(friendsManagementNotifier).cameraController;
    if (cameraController == null) return;

    try {
      await cameraController.setFlashMode(
        isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() {
        isFlashOn = !isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(128)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;
    final scanRect = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaSize,
      scanAreaSize,
    );

    // Draw dark overlay around scan area
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(
          scanRect,
          Radius.circular(16.0),
        ))
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      Offset(scanAreaLeft, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength,
          scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize,
          scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}