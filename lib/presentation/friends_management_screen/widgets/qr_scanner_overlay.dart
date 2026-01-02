import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_icon_button.dart';

class QRScannerOverlay extends ConsumerStatefulWidget {
  final String scanType;
  final VoidCallback? onSuccess;

  const QRScannerOverlay({
    Key? key,
    required this.scanType,
    this.onSuccess,
  }) : super(key: key);

  @override
  QRScannerOverlayState createState() => QRScannerOverlayState();
}

class QRScannerOverlayState extends ConsumerState<QRScannerOverlay> {
  MobileScannerController? _controller;
  bool isProcessing = false;
  String? resultMessage;
  bool isSuccess = false;
  bool _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleScannedCode(String code) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Parse the code - can be URL or raw code
      String extractedCode;
      String type = widget.scanType;

      if (code.startsWith('http')) {
        // Parse URL: https://capsule.app/join/{type}/{code}
        final uri = Uri.parse(code);
        final segments = uri.pathSegments;

        if (segments.length >= 3 && segments[0] == 'join') {
          type = segments[1];
          extractedCode = segments[2];
        } else {
          throw Exception('Invalid QR code format');
        }
      } else if (code.length == 8) {
        // Raw 8-character code
        extractedCode = code;
      } else {
        throw Exception('Invalid code length');
      }

      // Call Supabase edge function to handle QR scan
      final client = SupabaseService.instance.client;
      if (client == null) throw Exception('Supabase not initialized');

      final response = await client.functions.invoke(
        'handle-qr-scan',
        body: {
          'type': type,
          'code': extractedCode,
        },
      );

      if (response.status == 200) {
        setState(() {
          isSuccess = true;
          resultMessage = 'Friend request sent successfully!';
        });

        await Future.delayed(Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess?.call();
        }
      } else {
        throw Exception(response.data['error'] ?? 'Failed to process QR code');
      }
    } catch (e) {
      setState(() {
        isSuccess = false;
        resultMessage = e.toString().replaceAll('Exception: ', '');
      });

      await Future.delayed(Duration(seconds: 3));

      setState(() {
        isProcessing = false;
        resultMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _handleScannedCode(barcodes.first.rawValue!);
              }
            },
          ),

          // Scanning overlay
          CustomPaint(
            size: Size.infinite,
            painter: ScannerOverlayPainter(),
          ),

          // Top bar
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
                      iconPath: ImageConstant.imgArrowLeft,
                      backgroundColor: appTheme.gray_900_01.withAlpha(179),
                      borderRadius: 22.h,
                      iconSize: 24.h,
                      onTap: () => Navigator.pop(context),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _flashEnabled = !_flashEnabled);
                        _controller?.toggleTorch();
                      },
                      child: Container(
                        height: 44.h,
                        width: 44.h,
                        decoration: BoxDecoration(
                          color: appTheme.gray_900_01.withAlpha(179),
                          borderRadius: BorderRadius.circular(22.h),
                        ),
                        child: Icon(
                          _flashEnabled ? Icons.flash_on : Icons.flash_off,
                          color: appTheme.white_A700,
                          size: 24.h,
                        ),
                      ),
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
                style: TextStyleHelper.instance.body16MediumPlusJakartaSans
                    .copyWith(
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

          // Processing/Result overlay
          if (isProcessing || resultMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(179),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20.h),
                    margin: EdgeInsets.symmetric(horizontal: 32.h),
                    decoration: BoxDecoration(
                      color: appTheme.gray_900_01,
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (resultMessage == null)
                          CircularProgressIndicator(
                              color: appTheme.deep_purple_A100),
                        if (resultMessage != null)
                          Icon(
                            isSuccess ? Icons.check_circle : Icons.error,
                            color: isSuccess ? Colors.green : Colors.red,
                            size: 48.h,
                          ),
                        SizedBox(height: 12.h),
                        Text(
                          resultMessage ?? 'Processing QR code...',
                          textAlign: TextAlign.center,
                          style: TextStyleHelper
                              .instance.body14RegularPlusJakartaSans
                              .copyWith(
                            color: appTheme.white_A700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final cornerLength = 30.0;

    // Top-left
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

    // Top-right
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

    // Bottom-left
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

    // Bottom-right
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
