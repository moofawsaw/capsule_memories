import 'dart:async';

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
    extends State<NativeCameraRecordingScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _errorMessage;
  Timer? _longPressTimer;
  bool _isLongPress = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      // Long press detected - start video recording
      _isLongPress = true;
      _startRecording();
    });
  }

  /// Handle tap up - either take photo or stop recording
  Future<void> _handleTapUp(TapUpDetails details) async {
    _longPressTimer?.cancel();

    if (_isRecording) {
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
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('❌ Error starting recording: $e');
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
          // Recording indicator
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
                    'Recording...',
                    style: TextStyleHelper.instance.body14Bold
                        .copyWith(color: appTheme.gray_50),
                  ),
                ],
              ),
            ),

          // Instruction text
          if (!_isRecording)
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

          // Record button with gesture detection
          GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: 72.h,
              height: 72.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: appTheme.gray_50,
                  width: 4,
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 24.h : 56.h,
                  height: _isRecording ? 24.h : 56.h,
                  decoration: BoxDecoration(
                    color: appTheme.red_500,
                    shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius:
                        _isRecording ? BorderRadius.circular(4.h) : null,
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
