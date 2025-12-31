import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

import '../../core/app_export.dart';

class QRScannerOverlay extends StatefulWidget {
  final String scanType;
  final VoidCallback? onSuccess;

  const QRScannerOverlay({
    Key? key,
    required this.scanType,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<QRScannerOverlay> createState() => _QRScannerOverlayState();
}

class _QRScannerOverlayState extends State<QRScannerOverlay> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;
  bool _flashEnabled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String rawValue) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Haptic feedback
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }

      // Parse QR code - could be URL or raw 8-char code
      String code;
      String type = widget.scanType;

      if (rawValue.startsWith('http')) {
        final uri = Uri.parse(rawValue);
        // Extract type and code from URL path: /join/{type}/{code}
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3 && pathSegments[0] == 'join') {
          type = pathSegments[1];
          code = pathSegments[2];
        } else {
          throw Exception('Invalid QR code format');
        }
      } else {
        code = rawValue;
      }

      // Call Supabase edge function
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'handle-qr-scan',
        body: {
          'type': type,
          'code': code,
        },
      );

      if (response.status == 200) {
        _showSuccessFeedback();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
          widget.onSuccess?.call();
        }
      } else {
        throw Exception(response.data?['error'] ?? 'Failed to process QR code');
      }
    } catch (e) {
      _showErrorFeedback(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Successfully scanned!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorFeedback(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Error: $error')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleFlash() {
    setState(() => _flashEnabled = !_flashEnabled);
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final rawValue = barcodes.first.rawValue;
                if (rawValue != null) {
                  _handleQRCode(rawValue);
                }
              }
            },
          ),

          // Top overlay with back button and title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(179),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center scanning frame with animated corners
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.green : appTheme.deep_purple_A100,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Top-left corner
                  Positioned(
                    top: -2,
                    left: -2,
                    child: _buildCornerIndicator(),
                  ),
                  // Top-right corner
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Transform.rotate(
                      angle: 1.5708,
                      child: _buildCornerIndicator(),
                    ),
                  ),
                  // Bottom-left corner
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Transform.rotate(
                      angle: -1.5708,
                      child: _buildCornerIndicator(),
                    ),
                  ),
                  // Bottom-right corner
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Transform.rotate(
                      angle: 3.14159,
                      child: _buildCornerIndicator(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Point your camera at a QR code to add friends or join memories',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Flashlight toggle button
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              onPressed: _toggleFlash,
              backgroundColor: _flashEnabled
                  ? appTheme.deep_purple_A100
                  : Colors.white.withAlpha(51),
              child: Icon(
                _flashEnabled ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerIndicator() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: _isProcessing ? Colors.green : appTheme.deep_purple_A100,
            width: 6,
          ),
          top: BorderSide(
            color: _isProcessing ? Colors.green : appTheme.deep_purple_A100,
            width: 6,
          ),
        ),
      ),
    );
  }
}