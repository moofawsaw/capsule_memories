// lib/presentation/friends_management_screen/widgets/qr_scanner_overlay.dart

import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class QRScannerOverlay extends ConsumerStatefulWidget {
  const QRScannerOverlay({
    Key? key,
    required this.scanType, // 'friend' | 'group' | 'memory'
    this.onSuccess,
  }) : super(key: key);

  final String scanType;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<QRScannerOverlay> createState() => _QRScannerOverlayState();
}

class _QRScannerOverlayState extends ConsumerState<QRScannerOverlay> {
  late final MobileScannerController _controller;

  bool _isProcessing = false;
  String? _resultMessage;

  /// True only when backend says success AND user is authenticated (action completed).
  bool _isSuccess = false;

  /// True when backend created a pending action and user must sign in to finish.
  bool _needsAuth = false;

  bool _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      // formats: [BarcodeFormat.qrCode], // uncomment if you want QR only
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeType(String t) {
    final v = t.trim().toLowerCase();
    if (v == 'friends') return 'friend';
    if (v == 'groups') return 'group';
    if (v == 'memories') return 'memory';
    return v;
  }

  /// Supports:
  /// - raw 8-char code: ABCD1234
  /// - URLs:
  ///   /join/<type>/<code>
  ///   /join/<type>?code=ABCD1234
  Map<String, String> _parseScan(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) throw Exception('Empty QR code');

    String type = _normalizeType(widget.scanType);
    String extractedCode = '';

    if (trimmed.startsWith('http') ||
        trimmed.startsWith('capapp://') ||
        trimmed.startsWith('capsule://')) {
      final uri = Uri.parse(trimmed);
      final segments =
      uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();

      // /join/<type>/<code>
      if (segments.length >= 3 && segments[0] == 'join') {
        type = _normalizeType(segments[1]);
        extractedCode = segments[2].trim();
      }
      // /join/<type>?code=XXXX
      else if (segments.length >= 2 && segments[0] == 'join') {
        type = _normalizeType(segments[1]);
        extractedCode = (uri.queryParameters['code'] ?? '').trim();
      } else {
        throw Exception('Invalid QR code format');
      }
    } else {
      // raw code
      extractedCode = trimmed;
    }

    if (extractedCode.isEmpty) throw Exception('Invalid QR code format');
    // If you enforce 8 char codes, keep this:
    if (extractedCode.length != 8) throw Exception('Invalid code length');

    return {'type': type, 'code': extractedCode};
  }

  Future<void> _handleScannedCode(String rawValue) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _resultMessage = null;
      _isSuccess = false;
      _needsAuth = false;
    });

    // stop camera while processing to prevent repeats
    await _controller.stop();

    try {
      final parsed = _parseScan(rawValue);
      final type = parsed['type']!;
      final code = parsed['code']!;

      final client = SupabaseService.instance.client;
      if (client == null) throw Exception('Supabase not initialized');

      final response = await client.functions.invoke(
        'handle-qr-scan',
        body: {'type': type, 'code': code},
      );

      if (response.status != 200) {
        final data = response.data;
        final msg = (data is Map && data['error'] is String)
            ? (data['error'] as String)
            : 'Failed to process QR code';
        throw Exception(msg);
      }

      final data = response.data;

      final bool success = data is Map && data['success'] == true;
      final bool authenticated = data is Map && data['authenticated'] == true;

      final String message =
      (data is Map && data['message'] is String && (data['message'] as String).trim().isNotEmpty)
          ? (data['message'] as String)
          : 'QR processed.';

      setState(() {
        _isSuccess = success && authenticated;
        _needsAuth = success && !authenticated;
        _resultMessage = message;
      });

      // Auto close only if action truly completed
      if (success && authenticated) {
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        widget.onSuccess?.call();
        Navigator.pop(context);
        return;
      }

      // Not completed (needs auth or backend says not-success): reset + restart scanner
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _resultMessage = null;
        _needsAuth = false;
        _isSuccess = false;
      });
      await _controller.start();
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _needsAuth = false;
        _resultMessage = e.toString().replaceAll('Exception: ', '');
      });

      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _resultMessage = null;
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              final String? value = capture.barcodes
                  .map((b) => b.rawValue)
                  .whereType<String>()
                  .map((v) => v.trim())
                  .firstWhere(
                    (v) => v.isNotEmpty,
                orElse: () => '',
              );

              if (value != null && value.isNotEmpty) {
                _handleScannedCode(value);
              }
            },
          ),

          CustomPaint(
            size: Size.infinite,
            painter: ScannerOverlayPainter(),
          ),

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
                        _controller.toggleTorch();
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

          Positioned(
            bottom: 80.h,
            left: 0,
            right: 0,
            child: Padding(
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

          if (_isProcessing || _resultMessage != null)
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
                        if (_resultMessage == null)
                          CircularProgressIndicator(
                            color: appTheme.deep_purple_A100,
                          )
                        else
                          Icon(
                            _isSuccess
                                ? Icons.check_circle
                                : (_needsAuth ? Icons.info : Icons.error),
                            color: _isSuccess
                                ? Colors.green
                                : (_needsAuth
                                ? appTheme.deep_purple_A100
                                : Colors.red),
                            size: 48.h,
                          ),
                        SizedBox(height: 12.h),
                        Text(
                          _resultMessage ?? 'Processing QR code...',
                          textAlign: TextAlign.center,
                          style: TextStyleHelper
                              .instance.body14RegularPlusJakartaSans
                              .copyWith(color: appTheme.white_A700),
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
        ..addRRect(
          RRect.fromRectAndRadius(
            scanRect,
            const Radius.circular(16.0),
          ),
        )
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const cornerLength = 30.0;

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
