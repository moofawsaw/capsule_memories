import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../../../services/supabase_service.dart';
import '../../../services/network_quality_service.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_view.dart';

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

  // Track current camera direction
  bool _isRearCamera = true;

  Timer? _releaseToleranceTimer;

  // Progress animation
  AnimationController? _progressController;
  static const int _maxRecordingDurationSeconds = 15;
  Timer? _recordingTimer;
  int _elapsedSeconds = 0;
  DateTime? _recordingStartTime;

  // Lock animation controller
  AnimationController? _lockAnimationController;
  Animation<double>? _lockScaleAnimation;

  // Instant-tap warm-up + buffering
  Future<void>? _warmupFuture;
  bool _warmupDone = false;
  bool _pendingPhotoTap = false;
  bool _isCapturing = false;

  // Orientation locking (native camera feel)
  bool _orientationLocked = false;

  // -----------------------------
  // OPTIMIZATION: Cache the mirror matrix for front camera
  // Avoids allocating a new Matrix4 on every frame
  // -----------------------------
  static final Matrix4 _frontCameraMirrorMatrix = Matrix4.identity()..rotateY(math.pi);

  // -----------------------------
  // OPTIMIZATION: Cache preview aspect ratio to avoid recalculating
  // -----------------------------
  double? _cachedPreviewAspectRatio;
  bool? _cachedIsPortrait;

  @override
  void initState() {
    super.initState();

    // Native camera apps commonly lock the capture UI to portrait.
    // This prevents "stretch/warp on rotation" issues.
    _lockCameraUiToPortrait();

    print('✅ RECORDER: categoryIcon="${widget.categoryIcon}"');

    _initializeCamera();

    // ✅ Warm upload pipeline early while user is recording/previewing
    unawaited(SupabaseService.instance.warmUploadPipeline());
    NetworkQualityService.prime();


    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _maxRecordingDurationSeconds),
    );

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

    // Restore normal app orientations
    _restoreUiOrientation();

    super.dispose();
  }

  // -----------------------------
  // OPTIMIZED: True native preview render with caching and RepaintBoundary
  // -----------------------------
  Widget _buildCameraPreviewNative() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize!.height,
          height: controller.value.previewSize!.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  // -----------------------------
  // Warm-up pipeline so first tap never fails
  // -----------------------------
  void _startWarmup() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    _warmupDone = false;
    _warmupFuture = () async {
      try {
        if (!kIsWeb) {
          // Explicit defaults help many devices stabilize faster
          await controller.setFlashMode(FlashMode.off);
          await controller.setExposureMode(ExposureMode.auto);
          await controller.setFocusMode(FocusMode.auto);
        }
      } catch (_) {
        // Ignore unsupported settings
      }

      // Let preview + AE/AF settle
      await Future.delayed(const Duration(milliseconds: 250));

      // Optional: nudge focus/exposure points to center (safe if unsupported)
      try {
        await controller.setFocusPoint(const Offset(0.5, 0.5));
        await controller.setExposurePoint(const Offset(0.5, 0.5));
      } catch (_) {}
    }();

    _warmupFuture!.then((_) {
      if (!mounted) return;

      setState(() {
        _warmupDone = true;
      });

      // If user tapped during warmup, fire immediately now
      if (_pendingPhotoTap) {
        _pendingPhotoTap = false;
        _takePhotoInternal();
      }
    });
  }
  int _quarterTurnsFor(DeviceOrientation o) {
    // These turns make the preview stay upright as the device rotates.
    // If you see left/right swapped on a specific device, swap 1 and 3.
    switch (o) {
      case DeviceOrientation.portraitUp:
        return 0;
      case DeviceOrientation.landscapeLeft:
        return 1;
      case DeviceOrientation.portraitDown:
        return 2;
      case DeviceOrientation.landscapeRight:
        return 3;
    }
  }

  bool _isLandscape(DeviceOrientation o) {
    return o == DeviceOrientation.landscapeLeft ||
        o == DeviceOrientation.landscapeRight;
  }

  // -----------------------------
  // Orientation lock helpers
  // -----------------------------
  Future<void> _lockCameraUiToPortrait() async {
    if (_orientationLocked) return;
    _orientationLocked = true;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _restoreUiOrientation() async {
    if (!_orientationLocked) return;
    _orientationLocked = false;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
        orElse: () => _cameras.first,
      )
          : _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _isRearCamera = camera.lensDirection == CameraLensDirection.back;

      // Reset cached aspect ratio when reinitializing
      _cachedPreviewAspectRatio = null;
      _cachedIsPortrait = null;

      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.high : ResolutionPreset.high,
        enableAudio: true,
        // OPTIMIZATION: Use more efficient pixel format
        imageFormatGroup: kIsWeb ? null : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Lock capture orientation too (prevents capture pipeline rotating/warping)
      if (!kIsWeb) {
        try {
          await _cameraController!.lockCaptureOrientation(
            DeviceOrientation.portraitUp,
          );
        } catch (_) {
          // Some devices/plugins don't support it
        }
      }

      if (!kIsWeb) {
        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
        } catch (e) {
          print('⚠️ Could not set focus mode: $e');
        }
      }

      setState(() {
        _isInitialized = true;
        _warmupDone = false;
        _pendingPhotoTap = false;
      });

      // Start warm-up AFTER showing preview so it feels instant
      _startWarmup();
    } catch (e) {
      print('❌ Error initializing camera: $e');
      setState(() {
        _errorMessage = 'Failed to initialize camera: ${e.toString()}';
      });
    }
  }

  Future<void> _flipCamera() async {
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
      await HapticFeedback.lightImpact();

      setState(() {
        _isInitialized = false;
        _warmupDone = false;
        _pendingPhotoTap = false;
        _warmupFuture = null;
        // Reset cached aspect ratio when flipping
        _cachedPreviewAspectRatio = null;
        _cachedIsPortrait = null;
      });

      // Unlock before dispose (safe if unsupported)
      if (!kIsWeb) {
        try {
          await _cameraController?.unlockCaptureOrientation();
        } catch (_) {}
      }

      await _cameraController?.dispose();

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

      _isRearCamera = newCamera.lensDirection == CameraLensDirection.back;

      _cameraController = CameraController(
        newCamera,
        kIsWeb ? ResolutionPreset.high : ResolutionPreset.high,
        enableAudio: true,
        // OPTIMIZATION: Use more efficient pixel format
        imageFormatGroup: kIsWeb ? null : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Keep capture orientation locked
      if (!kIsWeb) {
        try {
          await _cameraController!.lockCaptureOrientation(
            DeviceOrientation.portraitUp,
          );
        } catch (_) {}
      }

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

      _startWarmup();
    } catch (e) {
      print('❌ Error flipping camera: $e');
      setState(() {
        _errorMessage = 'Failed to flip camera: ${e.toString()}';
      });
    }
  }

  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    if (_state != CameraState.idle) return;

    await HapticFeedback.lightImpact();

    setState(() {
      _state = CameraState.preparingVideo;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    if (_state == CameraState.preparingVideo) {
      await _startRecording();
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (_state == CameraState.recordingLocked) {
      return;
    }

    if (_state == CameraState.recording && _elapsedSeconds < 2) {
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
      await _stopRecording();
    }
  }

  bool _hasCategoryIcon() {
    final s = widget.categoryIcon?.trim();
    if (s == null) return false;
    if (s.isEmpty) return false;
    if (s == 'null' || s == 'undefined') return false;
    return true;
  }

  bool _looksLikeEmoji(String s) {
    // quick heuristic: if it doesn't look like a path/url and is short, treat as emoji
    final v = s.trim();
    final isUrl = v.startsWith('http://') || v.startsWith('https://');
    final isAssetLike =
        v.contains('/') || v.contains('.') || v.startsWith('assets');
    return !isUrl && !isAssetLike && v.runes.length <= 4;
  }

  /// Take a photo (single tap) - INSTANT TAP SAFE
  Future<void> _takePhoto() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_state != CameraState.idle) return;

    // If camera warm-up not finished yet, buffer the tap and take photo ASAP
    if (!_warmupDone) {
      _pendingPhotoTap = true;
      return;
    }

    await _takePhotoInternal();
  }

  Future<void> _takePhotoInternal() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_state != CameraState.idle) return;

    if (_isCapturing) return;
    _isCapturing = true;

    try {
      await HapticFeedback.lightImpact();

      XFile photoFile;

      try {
        photoFile = await controller.takePicture();
      } on CameraException catch (e) {
        // One retry removes edge-device first-capture failures
        debugPrint(
            '⚠️ takePicture failed (first attempt): ${e.code} ${e.description}');
        await Future.delayed(const Duration(milliseconds: 160));
        photoFile = await controller.takePicture();
      }

      if (!mounted) return;

      Navigator.of(context).pushNamed(
        AppRoutes.appStoryEdit,
        arguments: {
          'video_path': photoFile.path,
          'is_video': false,
          'memory_id': widget.memoryId,
          'memory_title': widget.memoryTitle,
          'category_icon': widget.categoryIcon,
        },
      );
    } catch (e) {
      print('❌ Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to take photo')),
        );
      }
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _startRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      setState(() {
        _state = CameraState.idle;
      });
      return;
    }

    // If warmup isn't done yet, wait briefly (prevents first-record failures too)
    if (!_warmupDone) {
      try {
        await _warmupFuture;
      } catch (_) {}
    }

    try {
      await HapticFeedback.mediumImpact();

      await controller.startVideoRecording();
      _recordingStartTime = DateTime.now();

      _progressController?.reset();
      _progressController?.forward();
      _elapsedSeconds = 0;

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _elapsedSeconds++;
        });

        if (_elapsedSeconds == 2 && _state == CameraState.recording) {
          _lockRecording();
        }

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
    await HapticFeedback.lightImpact();

    setState(() {
      _state = CameraState.recordingLocked;
    });

    _lockAnimationController?.forward();
  }

  Future<void> _stopRecording({bool discard = false}) async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      await HapticFeedback.lightImpact();

      _recordingTimer?.cancel();
      _progressController?.stop();
      _lockAnimationController?.reset();
      _releaseToleranceTimer?.cancel();

      final videoFile = await _cameraController!.stopVideoRecording();

      setState(() {
        _state = CameraState.idle;
      });

      if (discard) {
        return;
      }

      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRoutes.appStoryEdit,
          arguments: {
            'video_path': videoFile.path,
            'is_video': true,
            'memory_id': widget.memoryId,
            'memory_title': widget.memoryTitle,
            'category_icon': widget.categoryIcon,
          },
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
            // OPTIMIZATION: Wrap camera preview in RepaintBoundary
            Positioned.fill(
              child: _buildCameraPreviewNative(),
            ),
            _buildTopHeader(),
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
                .copyWith(color: appTheme.whiteCustom),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.deepPurpleAccent,
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
                  color: appTheme.whiteCustom,
                  size: 24.h,
                ),
              ),
            ),
            Row(
              children: [
                if (_hasCategoryIcon()) ...[
                  if (_looksLikeEmoji(widget.categoryIcon!))
                    Text(
                      widget.categoryIcon!,
                      style: TextStyle(fontSize: 18.h),
                    )
                  else
                    CustomImageView(
                      imagePath: widget.categoryIcon!,
                      height: 20.h,
                      width: 20.h,
                      fit: BoxFit.contain,
                    ),
                  SizedBox(width: 8.h),
                ],
                SizedBox(width: 8.h),
                Text(
                  widget.memoryTitle,
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.whiteCustom),
                ),
              ],
            ),
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
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStateIndicator(),
                ),
                SizedBox(height: 16.h),
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
                                    : appTheme.whiteCustom,
                                width: _state == CameraState.preparingVideo
                                    ? 5
                                    : 4,
                              ),
                            ),
                          ),
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
          Positioned(
            right: 16.h,
            bottom: 20.h,
            child: _buildVerticalControlStack(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalControlStack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                  color: appTheme.whiteCustom,
                  size: 24.h,
                ),
              ),
            ),
          )
              : const SizedBox.shrink(),
        ),
        if (_state == CameraState.recordingLocked) SizedBox(height: 16.h),
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
              color: appTheme.whiteCustom,
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
          key: const ValueKey('recording'),
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
                  color: appTheme.whiteCustom,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.h),
              Text(
                'Recording ${_formatTime(_elapsedSeconds)}/${_formatTime(_maxRecordingDurationSeconds)}',
                style: TextStyleHelper.instance.body14Bold
                    .copyWith(color: appTheme.whiteCustom),
              ),
            ],
          ),
        );

      case CameraState.recordingLocked:
        return Container(
          key: const ValueKey('locked'),
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
                  color: appTheme.whiteCustom,
                  size: 16.h,
                ),
              ),
              SizedBox(width: 8.h),
              Text(
                'Locked • Tap to stop ${_formatTime(_elapsedSeconds)}/${_formatTime(_maxRecordingDurationSeconds)}',
                style: TextStyleHelper.instance.body14Bold
                    .copyWith(color: appTheme.whiteCustom),
              ),
            ],
          ),
        );

      case CameraState.preparingVideo:
        return Container(
          key: const ValueKey('preparing'),
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
                  color: appTheme.whiteCustom,
                ),
              ),
              SizedBox(width: 8.h),
              Text(
                'Preparing...',
                style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                    .copyWith(color: appTheme.whiteCustom),
              ),
            ],
          ),
        );

      case CameraState.idle:
      default:
        final idleLabel =
        _warmupDone ? 'Tap for photo • Hold for video' : 'Opening camera...';
        return Container(
          key: const ValueKey('idle'),
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(128),
            borderRadius: BorderRadius.circular(20.h),
          ),
          child: Text(
            idleLabel,
            style: TextStyleHelper.instance.body12MediumPlusJakartaSans
                .copyWith(color: appTheme.whiteCustom),
          ),
        );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

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

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
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