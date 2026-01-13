import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../../../core/app_export.dart';
import '../notifier/friends_management_notifier.dart';

class CameraScannerScreen extends ConsumerStatefulWidget {
  const CameraScannerScreen({Key? key}) : super(key: key);

  @override
  CameraScannerScreenState createState() => CameraScannerScreenState();
}

class CameraScannerScreenState extends ConsumerState<CameraScannerScreen> {
  bool isFlashOn = false;
  bool isScanning = false;
  BarcodeScanner? _barcodeScanner;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _barcodeScanner = BarcodeScanner();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
      _startImageStream();
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startImageStream() {
    final state = ref.read(friendsManagementNotifier);
    final cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    cameraController.startImageStream((CameraImage image) {
      if (isScanning) return;
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (isScanning || _barcodeScanner == null) return;

    setState(() => isScanning = true);

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      final InputImageRotation imageRotation = InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat = InputImageFormat.nv21;

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );

      final List<Barcode> barcodes =
          await _barcodeScanner!.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final barcode = barcodes.first;
        if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
          await _handleScannedCode(barcode.rawValue!);
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      setState(() => isScanning = false);
    }
  }

  Future<void> _handleScannedCode(String code) async {
    final state = ref.read(friendsManagementNotifier);
    final cameraController = _cameraController;

    if (cameraController != null && cameraController.value.isStreamingImages) {
      await cameraController.stopImageStream();
    }

    if (!mounted) return;

    // Process the QR code and get the result
    final result = await ref
        .read(friendsManagementNotifier.notifier)
        .processScannedQRCode(code);

    if (mounted && result['success'] == true) {
      // Close camera scanner
      Navigator.pop(context);

      // Navigate to Friends screen after successful friend QR scan
      if (result['type'] == 'friend') {
        // The realtime subscription will automatically refresh the friends list
        Navigator.pushNamed(context, AppRoutes.appFriends);
      }
    }
  }

  @override
  void dispose() {
    _barcodeScanner?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsManagementNotifier);
    final cameraController = _cameraController;

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

          // Top bar with close and flash buttons
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
                    if (!kIsWeb)
                      CustomIconButton(
                        height: 44.h,
                        width: 44.h,
                        iconPath: isFlashOn
                            ? ImageConstant.imgButtonsVolume
                            : ImageConstant.imgButtonsGray50,
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

          // Scanning indicator
          if (isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(64),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20.h),
                    decoration: BoxDecoration(
                      color: appTheme.gray_900_01.withAlpha(230),
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: appTheme.deep_purple_A100),
                        SizedBox(height: 12.h),
                        Text(
                          'Processing QR code...',
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

          // Success/Error messages
          if (state.successMessage != null && state.successMessage!.isNotEmpty)
            Positioned(
              top: 120.h,
              left: 16.h,
              right: 16.h,
              child: Container(
                padding: EdgeInsets.all(16.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(230),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                child: Text(
                  state.successMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: Colors.white),
                ),
              ),
            ),

          if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
            Positioned(
              top: 120.h,
              left: 16.h,
              right: 16.h,
              child: Container(
                padding: EdgeInsets.all(16.h),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(230),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body14RegularPlusJakartaSans
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (kIsWeb) return;

    final state = ref.read(friendsManagementNotifier);
    final cameraController = _cameraController;
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