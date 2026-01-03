import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../../story_edit_screen/story_edit_screen.dart';

class NativeCameraRecordingScreen extends StatefulWidget {
  final String memoryId;
  final String memoryTitle;
  final String? categoryIcon;

  const NativeCameraRecordingScreen({
    Key? key,
    required this.memoryId,
    required this.memoryTitle,
    this.categoryIcon,
  }) : super(key: key);

  @override
  State<NativeCameraRecordingScreen> createState() =>
      _NativeCameraRecordingScreenState();
}

class _NativeCameraRecordingScreenState
    extends State<NativeCameraRecordingScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _errorMessage;
  Timer? _longPressTimer;
  bool _isLongPress = false;
  bool _isPreparing = false; // NEW: Track when preparing to record

  // Progress animation
  AnimationController? _progressController;
  static const int _maxRecordingDurationSeconds = 60; // 60 seconds max
  Timer? _recordingTimer;
  int _elapsedSeconds = 0;
  DateTime? _recordingStartTime; // NEW: Track actual recording start time

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Initialize progress animation controller
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _maxRecordingDurationSeconds),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _progressController?.dispose();
    _recordingTimer?.cancel();
    _longPressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
        });
        return;
      }

      // Use rear camera on mobile, front camera on web
      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      // Apply platform-specific settings
      if (!kIsWeb) {
        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
        } catch (e) {
          print('⚠️ Could not set focus mode: $e');
        }
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('❌ Error initializing camera: $e');
      setState(() {
        _errorMessage = 'Failed to initialize camera: ${e.toString()}';
      });
    }
  }

  /// Handle tap down - start timer to detect long press
  void _handleTapDown(TapDownDetails details) {
    _isLongPress = false;
    // Reduced from 500ms to 250ms for lower sensitivity
    _longPressTimer = Timer(const Duration(milliseconds: 250), () {
      // Long press detected - start video recording
      _isLongPress = true;
      setState(() {
        _isPreparing = true; // Show visual feedback immediately
      });
      _startRecording();
    });
  }

  /// Handle tap up - either take photo or stop recording
  Future<void> _handleTapUp(TapUpDetails details) async {
    _longPressTimer?.cancel();

    setState(() {
      _isPreparing = false; // Reset preparing state
    });

    if (_isRecording) {
      // Check minimum recording duration (500ms) to prevent errors
      final recordingDuration =
          DateTime.now().difference(_recordingStartTime ?? DateTime.now());
      if (recordingDuration.inMilliseconds < 500) {
        // Too short - show message and continue recording briefly
        await Future.delayed(
            Duration(milliseconds: 500 - recordingDuration.inMilliseconds));
      }

      // Stop video recording
      await _stopRecording();
    } else if (!_isLongPress) {
      // Quick tap - take photo
      await _takePhoto();
    }
  }

  /// Handle tap cancel - stop recording if active
  void _handleTapCancel() {
    _longPressTimer?.cancel();
    setState(() {
      _isPreparing = false; // Reset preparing state
    });
    if (_isRecording) {
      _stopRecording();
    }
  }

  /// Take a photo (single tap)
  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final photoFile = await _cameraController!.takePicture();

      // Navigate to story edit screen with photo
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryEditScreen(
              mediaPath: photoFile.path,
              isVideo: false,
              memoryId: widget.memoryId,
              memoryTitle: widget.memoryTitle,
              categoryIcon: widget.categoryIcon,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _isPreparing = false;
      });
      return;
    }

    try {
      // Start recording immediately
      await _cameraController!.startVideoRecording();
      _recordingStartTime = DateTime.now(); // Track start time

      // Start progress animation
      _progressController?.reset();
      _progressController?.forward();
      _elapsedSeconds = 0;

      // Start timer to track elapsed time and auto-stop at max duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });

        // Auto-stop at max duration
        if (_elapsedSeconds >= _maxRecordingDurationSeconds) {
          _stopRecording();
        }
      });

      setState(() {
        _isRecording = true;
        _isPreparing = false; // Recording started successfully
      });
    } catch (e) {
      print('❌ Error starting recording: $e');
      setState(() {
        _isPreparing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      // Stop timers and animation
      _recordingTimer?.cancel();
      _progressController?.stop();

      final videoFile = await _cameraController!.stopVideoRecording();

      setState(() {
        _isRecording = false;
      });

      // Navigate to story edit screen with video
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryEditScreen(
              mediaPath: videoFile.path,
              isVideo: true,
              memoryId: widget.memoryId,
              memoryTitle: widget.memoryTitle,
              categoryIcon: widget.categoryIcon,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save recording')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _errorMessage != null
            ? _buildErrorView()
            : !_isInitialized
                ? _buildLoadingView()
                : Stack(
                    children: [
                      // Camera preview
                      Positioned.fill(
                        child: CameraPreview(_cameraController!),
                      ),

                      // Top header with close button
                      _buildTopHeader(),

                      // Bottom recording controls
                      _buildRecordingControls(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.h,
            color: appTheme.red_500,
          ),
          SizedBox(height: 16.h),
          Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyleHelper.instance.body14MediumPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(
        color: appTheme.deep_purple_A100,
      ),
    );
  }

  Widget _buildTopHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(178),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(102),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: appTheme.gray_50,
                  size: 24.h,
                ),
              ),
            ),

            // Memory title
            Row(
              children: [
                if (widget.categoryIcon != null)
                  CustomImageView(
                    imagePath: widget.categoryIcon!,
                    height: 20.h,
                    width: 20.h,
                    fit: BoxFit.contain,
                  ),
                SizedBox(width: 8.h),
                Text(
                  widget.memoryTitle,
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
              ],
            ),

            SizedBox(width: 40.h), // Balance for close button
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingControls() {
    return Positioned(
      bottom: 40.h,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator with timer
          if (_isRecording)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
              decoration: BoxDecoration(
                color: appTheme.red_500,
                borderRadius: BorderRadius.circular(20.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8.h,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: appTheme.gray_50,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Recording ${_formatTime(_elapsedSeconds)}/${_formatTime(_maxRecordingDurationSeconds)}',
                    style: TextStyleHelper.instance.body14Bold
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),

          // Preparing indicator
          if (_isPreparing && !_isRecording)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: appTheme.red_500.withAlpha(179),
                borderRadius: BorderRadius.circular(20.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12.h,
                    height: 12.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: appTheme.gray_50,
                    ),
                  ),
                  SizedBox(width: 8.h),
                  Text(
                    'Preparing...',
                    style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),

          // Instruction text
          if (!_isRecording && !_isPreparing)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(20.h),
              ),
              child: Text(
                'Tap for photo • Hold for video',
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(color: appTheme.gray_50),
              ),
            ),

          SizedBox(height: 16.h),

          // Record button with circular progress indicator - MADE BIGGER
          GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated circular progress ring (increased size)
                if (_isRecording)
                  AnimatedBuilder(
                    animation: _progressController!,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(100.h, 100.h), // Increased from 80.h
                        painter: _CircularProgressPainter(
                          progress: _progressController!.value,
                          strokeWidth: 4.0,
                          progressColor: appTheme.red_500,
                        ),
                      );
                    },
                  ),

                // Static white border when not recording (increased size)
                if (!_isRecording)
                  Container(
                    width: 100.h, // Increased from 80.h
                    height: 100.h, // Increased from 80.h
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isPreparing
                            ? appTheme.red_500.withAlpha(179)
                            : appTheme.gray_50,
                        width: _isPreparing ? 5 : 4,
                      ),
                    ),
                  ),

                // Inner button with pulsing animation when recording (increased size)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording
                      ? 32.h
                      : 80.h, // Increased from 28.h and 64.h
                  height: _isRecording
                      ? 32.h
                      : 80.h, // Increased from 28.h and 64.h
                  decoration: BoxDecoration(
                    color: appTheme.red_500,
                    shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius:
                        _isRecording ? BorderRadius.circular(6.h) : null,
                    boxShadow: (_isRecording || _isPreparing)
                        ? [
                            BoxShadow(
                              color: appTheme.red_500.withAlpha(128),
                              blurRadius: 12.h,
                              spreadRadius: 2.h,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format seconds to MM:SS
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw progress arc (starts at top, goes clockwise)
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Calculate sweep angle (0 to 2π)
    final sweepAngle = 2 * math.pi * progress;

    // Draw arc starting from top (-π/2 radians = 12 o'clock)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at 12 o'clock
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor;
  }
}
