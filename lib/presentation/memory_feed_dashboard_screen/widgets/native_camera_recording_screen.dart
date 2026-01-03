import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';
import '../../story_edit_screen/story_edit_screen.dart';

enum CameraState {
  idle,
  preparingVideo,
  recording,
  recordingLocked,
}

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
    extends State<NativeCameraRecordingScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  String? _errorMessage;

  CameraState _state = CameraState.idle;

  // NEW: Track current camera direction
  bool _isRearCamera = true;

  Timer? _releaseToleranceTimer;

  // Progress animation
  AnimationController? _progressController;
  static const int _maxRecordingDurationSeconds = 60;
  Timer? _recordingTimer;
  int _elapsedSeconds = 0;
  DateTime? _recordingStartTime;

  // NEW: Lock animation controller
  AnimationController? _lockAnimationController;
  Animation<double>? _lockScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Initialize progress animation controller
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _maxRecordingDurationSeconds),
    );

    // NEW: Initialize lock animation controller
    _lockAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _lockScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lockAnimationController!,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _progressController?.dispose();
    _lockAnimationController?.dispose();
    _recordingTimer?.cancel();
    _releaseToleranceTimer?.cancel();
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

      // Update rear camera state
      _isRearCamera = camera.lensDirection == CameraLensDirection.back;

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

  // NEW: Camera flip method
  Future<void> _flipCamera() async {
    // Prevent flip during recording
    if (_state == CameraState.recording ||
        _state == CameraState.recordingLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot flip camera during recording'),
          duration: const Duration(seconds: 2),
          backgroundColor: appTheme.red_500,
        ),
      );
      return;
    }

    if (_cameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No other camera available'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Light haptic feedback
      await HapticFeedback.lightImpact();

      setState(() {
        _isInitialized = false;
      });

      // Dispose current controller
      await _cameraController?.dispose();

      // Find opposite camera
      final newCamera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection ==
            (_isRearCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => _cameras.firstWhere(
          (camera) =>
              camera.lensDirection !=
              (_isRearCamera
                  ? CameraLensDirection.back
                  : CameraLensDirection.front),
          orElse: () => _cameras.first,
        ),
      );

      // Update camera direction state
      _isRearCamera = newCamera.lensDirection == CameraLensDirection.back;

      // Initialize new controller
      _cameraController = CameraController(
        newCamera,
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
      print('❌ Error flipping camera: $e');
      setState(() {
        _errorMessage = 'Failed to flip camera: ${e.toString()}';
      });
    }
  }

  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    if (_state != CameraState.idle) return;

    // Light haptic feedback on press start
    await HapticFeedback.lightImpact();

    setState(() {
      _state = CameraState.preparingVideo;
    });

    // Start recording after brief preparation
    await Future.delayed(const Duration(milliseconds: 100));

    if (_state == CameraState.preparingVideo) {
      await _startRecording();
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_state == CameraState.recordingLocked) {
      // Locked - ignore release, tap to stop instead
      return;
    }

    if (_state == CameraState.recording && _elapsedSeconds < 2) {
      // Not locked yet - add release tolerance buffer
      _releaseToleranceTimer?.cancel();
      _releaseToleranceTimer = Timer(const Duration(milliseconds: 150), () {
        if (_state == CameraState.recording) {
          _handleRecordingStop();
        }
      });
    }
  }

  void _handleLongPressCancel() {
    _releaseToleranceTimer?.cancel();

    if (_state == CameraState.preparingVideo) {
      setState(() {
        _state = CameraState.idle;
      });
    } else if (_state == CameraState.recording && _elapsedSeconds < 2) {
      _handleRecordingStop();
    }
  }

  Future<void> _handleTapWhenLocked() async {
    if (_state == CameraState.recordingLocked) {
      await _stopRecording();
    }
  }

  Future<void> _handleRecordingStop() async {
    if (_elapsedSeconds < 1) {
      // Too short - discard and show toast
      await _stopRecording(discard: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hold longer for video'),
            duration: const Duration(seconds: 2),
            backgroundColor: appTheme.red_500,
          ),
        );
      }
    } else {
      // Valid recording - save it
      await _stopRecording();
    }
  }

  /// Take a photo (single tap)
  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_state != CameraState.idle) return;

    try {
      // Light haptic feedback
      await HapticFeedback.lightImpact();

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
        _state = CameraState.idle;
      });
      return;
    }

    try {
      // Medium haptic feedback when recording begins
      await HapticFeedback.mediumImpact();

      // Start recording
      await _cameraController!.startVideoRecording();
      _recordingStartTime = DateTime.now();

      // Start progress animation
      _progressController?.reset();
      _progressController?.forward();
      _elapsedSeconds = 0;

      // Start timer to track elapsed time
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });

        // Auto-lock after 2 seconds
        if (_elapsedSeconds == 2 && _state == CameraState.recording) {
          _lockRecording();
        }

        // Auto-stop at max duration
        if (_elapsedSeconds >= _maxRecordingDurationSeconds) {
          _stopRecording();
        }
      });

      setState(() {
        _state = CameraState.recording;
      });
    } catch (e) {
      print('❌ Error starting recording: $e');
      setState(() {
        _state = CameraState.idle;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording')),
        );
      }
    }
  }

  Future<void> _lockRecording() async {
    // Light haptic feedback when locking
    await HapticFeedback.lightImpact();

    setState(() {
      _state = CameraState.recordingLocked;
    });

    // Animate lock icon appearance
    _lockAnimationController?.forward();
  }

  Future<void> _stopRecording({bool discard = false}) async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      // Light haptic feedback when stopping
      await HapticFeedback.lightImpact();

      // Stop timers and animation
      _recordingTimer?.cancel();
      _progressController?.stop();
      _lockAnimationController?.reset();
      _releaseToleranceTimer?.cancel();

      final videoFile = await _cameraController!.stopVideoRecording();

      setState(() {
        _state = CameraState.idle;
      });

      if (discard) {
        // Just discard the file, don't navigate
        return;
      }

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
      setState(() {
        _state = CameraState.idle;
      });
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

            // Empty spacer to maintain layout balance
            SizedBox(width: 40.h),
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
      child: Stack(
        children: [
          // Main recording button in center - EXPLICITLY CENTERED
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Recording indicator with timer
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStateIndicator(),
                ),

                SizedBox(height: 16.h),

                // Record button with gestures - INCREASED SIZE
                GestureDetector(
                  onTap: _state == CameraState.recordingLocked
                      ? _handleTapWhenLocked
                      : _takePhoto,
                  onLongPressStart: _handleLongPressStart,
                  onLongPressEnd: _handleLongPressEnd,
                  onLongPressCancel: _handleLongPressCancel,
                  child: AnimatedScale(
                    scale: _state == CameraState.preparingVideo ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated circular progress ring - INCREASED SIZE
                        if (_state == CameraState.recording ||
                            _state == CameraState.recordingLocked)
                          AnimatedBuilder(
                            animation: _progressController!,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size(120.h, 120.h),
                                painter: _CircularProgressPainter(
                                  progress: _progressController!.value,
                                  strokeWidth: 4.0,
                                  progressColor: appTheme.red_500,
                                ),
                              );
                            },
                          ),

                        // Static border when idle or preparing - INCREASED SIZE
                        if (_state == CameraState.idle ||
                            _state == CameraState.preparingVideo)
                          Container(
                            width: 120.h,
                            height: 120.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _state == CameraState.preparingVideo
                                    ? appTheme.red_500.withAlpha(179)
                                    : appTheme.gray_50,
                                width: _state == CameraState.preparingVideo
                                    ? 5
                                    : 4,
                              ),
                            ),
                          ),

                        // Inner button with smooth shape transition - INCREASED SIZE
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: (_state == CameraState.recording ||
                                  _state == CameraState.recordingLocked)
                              ? 38.h
                              : 95.h,
                          height: (_state == CameraState.recording ||
                                  _state == CameraState.recordingLocked)
                              ? 38.h
                              : 95.h,
                          decoration: BoxDecoration(
                            color: appTheme.red_500,
                            shape: (_state == CameraState.recording ||
                                    _state == CameraState.recordingLocked)
                                ? BoxShape.rectangle
                                : BoxShape.circle,
                            borderRadius: (_state == CameraState.recording ||
                                    _state == CameraState.recordingLocked)
                                ? BorderRadius.circular(6.h)
                                : null,
                            boxShadow: (_state != CameraState.idle)
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
                ),
              ],
            ),
          ),

          // TikTok-style vertical control stack on bottom right
          Positioned(
            right: 16.h,
            bottom: 20.h,
            child: _buildVerticalControlStack(),
          ),
        ],
      ),
    );
  }

  /// NEW METHOD: TikTok-style vertical button stack (lock + volume/mute)
  Widget _buildVerticalControlStack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lock button - shows when recording is locked
        AnimatedOpacity(
          opacity: _state == CameraState.recordingLocked ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: _state == CameraState.recordingLocked
              ? GestureDetector(
                  onTap: _handleTapWhenLocked,
                  child: Container(
                    padding: EdgeInsets.all(12.h),
                    decoration: BoxDecoration(
                      color: appTheme.deep_purple_A100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: appTheme.deep_purple_A100.withAlpha(102),
                          blurRadius: 8.h,
                          spreadRadius: 2.h,
                        ),
                      ],
                    ),
                    child: ScaleTransition(
                      scale: _lockScaleAnimation!,
                      child: Icon(
                        Icons.lock,
                        color: appTheme.gray_50,
                        size: 24.h,
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),

        if (_state == CameraState.recordingLocked) SizedBox(height: 16.h),

        // Camera flip button - always visible
        GestureDetector(
          onTap: _flipCamera,
          child: Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(128),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flip_camera_ios,
              color: appTheme.gray_50,
              size: 24.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateIndicator() {
    switch (_state) {
      case CameraState.recording:
        return Container(
          key: ValueKey('recording'),
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
        );

      case CameraState.recordingLocked:
        return Container(
          key: ValueKey('locked'),
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
          decoration: BoxDecoration(
            color: appTheme.deep_purple_A100,
            borderRadius: BorderRadius.circular(20.h),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _lockScaleAnimation!,
                child: Icon(
                  Icons.lock,
                  color: appTheme.gray_50,
                  size: 16.h,
                ),
              ),
              SizedBox(width: 8.h),
              Text(
                'Locked • Tap to stop ${_formatTime(_elapsedSeconds)}/${_formatTime(_maxRecordingDurationSeconds)}',
                style: TextStyleHelper.instance.body14Bold
                    .copyWith(color: appTheme.gray_50),
              ),
            ],
          ),
        );

      case CameraState.preparingVideo:
        return Container(
          key: ValueKey('preparing'),
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
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
        );

      case CameraState.idle:
      default:
        return Container(
          key: ValueKey('idle'),
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(128),
            borderRadius: BorderRadius.circular(20.h),
          ),
          child: Text(
            'Tap for photo • Hold for video',
            style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                .copyWith(color: appTheme.gray_50),
          ),
        );
    }
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
