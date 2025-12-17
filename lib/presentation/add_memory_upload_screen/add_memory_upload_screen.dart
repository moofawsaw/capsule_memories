import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_header_section.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_image_view.dart';
import 'notifier/add_memory_upload_notifier.dart';

class AddMemoryUploadScreen extends ConsumerStatefulWidget {
  AddMemoryUploadScreen({Key? key}) : super(key: key);

  @override
  AddMemoryUploadScreenState createState() => AddMemoryUploadScreenState();
}

class AddMemoryUploadScreenState extends ConsumerState<AddMemoryUploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: appTheme.gray_900_02,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.h),
          topRight: Radius.circular(20.h),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12.h),
          // Drag handle indicator
          Container(
            width: 48.h,
            height: 5.h,
            decoration: BoxDecoration(
              color: appTheme.colorFF3A3A,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          SizedBox(height: 20.h),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(addMemoryUploadNotifier);

        return Column(
          children: [
            Container(
              width: 116.h,
              height: 12.h,
              decoration: BoxDecoration(
                color: appTheme.color3BD81E,
                borderRadius: BorderRadius.circular(6.h),
              ),
            ),
            CustomHeaderSection(
              title: 'Add to Memory',
              description:
                  'Upload a photo or video from your device to add to "memory name"',
              margin: EdgeInsets.only(top: 32.h, left: 42.h, right: 42.h),
            ),
            _buildUploadSection(context),
            _buildActionButtons(context),
          ],
        );
      },
    );
  }

  /// Section Widget
  Widget _buildUploadSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(addMemoryUploadNotifier);

        ref.listen(
          addMemoryUploadNotifier,
          (previous, current) {
            if (current.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(current.errorMessage!)),
              );
            }
          },
        );

        return GestureDetector(
          onTap: () => _showFilePickerOptions(context),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 26.h),
            padding: EdgeInsets.symmetric(vertical: 34.h),
            decoration: BoxDecoration(
              color: appTheme.colorDF0782,
              border: Border.all(
                color: appTheme.deep_purple_A100,
                width: 2.h,
              ),
              borderRadius: BorderRadius.circular(12.h),
            ),
            child: Column(
              children: [
                if (state.selectedFile != null &&
                    state.selectedFile!.path?.toLowerCase().contains(
                            RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp)$')) ==
                        true) // Modified: Added null safety for path
                  Container(
                    height: 120.h,
                    width: 120.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.h),
                      child: kIsWeb
                          ? Image.network(
                              state.selectedFile!.path ??
                                  '', // Modified: Added null coalescing operator
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildUploadIcon(),
                            )
                          : Image.file(
                              File(state.selectedFile!.path ??
                                  ''), // Modified: Added null coalescing operator
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildUploadIcon(),
                            ),
                    ),
                  )
                else if (state.selectedFile != null)
                  Container(
                    padding: EdgeInsets.all(16.h),
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: appTheme.gray_900,
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomImageView(
                          imagePath: ImageConstant.imgIconWhiteA700,
                          height: 20.h,
                          width: 20.h,
                        ),
                        SizedBox(width: 8.h),
                        Flexible(
                          child: Text(
                            state.selectedFile!.name,
                            style: TextStyleHelper
                                .instance.body14MediumPlusJakartaSans,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildUploadIcon(),
                Text(
                  state.selectedFile != null ? 'File Selected' : 'Choose file',
                  style: TextStyleHelper.instance.title16BoldPlusJakartaSans
                      .copyWith(color: appTheme.gray_50),
                ),
                SizedBox(height: 4.h),
                Text(
                  state.selectedFile != null
                      ? '${(state.selectedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB'
                      : 'Photo or video up to 50MB',
                  style: TextStyleHelper.instance.body14BoldPlusJakartaSans
                      .copyWith(color: appTheme.blue_gray_300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadIcon() {
    return CustomIconButton(
      iconPath: ImageConstant.imgFrameDeepPurpleA100,
      backgroundColor: appTheme.color41C124,
      height: 62.h,
      width: 62.h,
      borderRadius: 30.h,
      padding: EdgeInsets.all(12.h),
    );
  }

  /// Section Widget
  Widget _buildActionButtons(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final state = ref.watch(addMemoryUploadNotifier);

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 20.h),
          child: Row(
            spacing: 12.h,
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () => _onTapCancel(context),
                  buttonStyle: CustomButtonStyle.fillDark,
                  buttonTextStyle: CustomButtonTextStyle.bodySmallPrimary,
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: (state.isUploading ?? false)
                      ? 'Uploading...'
                      : 'Add to Memory', // Modified: Added null safety check
                  leftIcon: (state.isUploading ?? false)
                      ? null
                      : ImageConstant
                          .imgIconWhiteA700, // Modified: Added null safety check
                  onPressed: (state.isUploading ?? false)
                      ? null
                      : () => _onTapAddToMemory(
                          context), // Modified: Added null safety check
                  buttonStyle: CustomButtonStyle.fillPrimary,
                  buttonTextStyle: CustomButtonTextStyle.bodyMedium,
                  isDisabled: state.isUploading ??
                      false, // Modified: Added null safety check
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shows file picker options
  void _showFilePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.gray_900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.h)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.h,
              height: 4.h,
              decoration: BoxDecoration(
                color: appTheme.blue_gray_300,
                borderRadius: BorderRadius.circular(2.h),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Select Media',
              style: TextStyleHelper.instance.title18BoldPlusJakartaSans
                  .copyWith(color: appTheme.gray_50),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading:
                  Icon(Icons.photo_camera, color: appTheme.deep_purple_A100),
              title: Text(
                'Take Photo',
                style: TextStyleHelper.instance.title16MediumPlusJakartaSans,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.photo_library, color: appTheme.deep_purple_A100),
              title: Text(
                'Choose from Gallery',
                style: TextStyleHelper.instance.title16MediumPlusJakartaSans,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: appTheme.deep_purple_A100),
              title: Text(
                'Record Video',
                style: TextStyleHelper.instance.title16MediumPlusJakartaSans,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickVideoFromCamera();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.video_library, color: appTheme.deep_purple_A100),
              title: Text(
                'Choose Video',
                style: TextStyleHelper.instance.title16MediumPlusJakartaSans,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickVideoFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.folder, color: appTheme.deep_purple_A100),
              title: Text(
                'Browse Files',
                style: TextStyleHelper.instance.title16MediumPlusJakartaSans,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickFileFromDevice();
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    final notifier = ref.read(addMemoryUploadNotifier.notifier);

    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      notifier.setError('Camera permission is required to take photos');
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = PlatformFile(
          name: image.name,
          path: image.path,
          size: await image.length(),
        );
        notifier.setSelectedFile(file);
      }
    } catch (e) {
      notifier.setError('Failed to capture image: ${e.toString()}');
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final notifier = ref.read(addMemoryUploadNotifier
        .notifier); // Modified: Defined notifier variable

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        final file = PlatformFile(
          name: image.name,
          path: image.path,
          size: await image.length(),
        );
        notifier.setSelectedFile(file);
      }
    } catch (e) {
      notifier.setError('Failed to select image: ${e.toString()}');
    }
  }

  /// Pick video from camera
  Future<void> _pickVideoFromCamera() async {
    final notifier = ref.read(addMemoryUploadNotifier.notifier);

    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      notifier.setError('Camera permission is required to record videos');
      return;
    }

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(minutes: 5),
      );

      if (video != null) {
        final file = PlatformFile(
          name: video.name,
          path: video.path,
          size: await video.length(),
        );

        // Check file size (50MB limit)
        if (file.size > 50 * 1024 * 1024) {
          notifier.setError('Video file size must be less than 50MB');
          return;
        }

        notifier.setSelectedFile(file);
      }
    } catch (e) {
      notifier.setError('Failed to record video: ${e.toString()}');
    }
  }

  /// Pick video from gallery
  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        final file = PlatformFile(
          name: video.name,
          path: video.path,
          size: await video.length(),
        );

        // Check file size (50MB limit)
        if (file.size > 50 * 1024 * 1024) {
          ref
              .read(addMemoryUploadNotifier.notifier)
              .setError('Video file size must be less than 50MB');
          return;
        }

        ref.read(addMemoryUploadNotifier.notifier).setSelectedFile(file);
      }
    } catch (e) {
      ref
          .read(addMemoryUploadNotifier.notifier)
          .setError('Failed to select video: ${e.toString()}');
    }
  }

  /// Pick file from device
  Future<void> _pickFileFromDevice() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (50MB limit)
        if (file.size > 50 * 1024 * 1024) {
          ref
              .read(addMemoryUploadNotifier.notifier)
              .setError('File size must be less than 50MB');
          return;
        }

        ref.read(addMemoryUploadNotifier.notifier).setSelectedFile(file);
      }
    } catch (e) {
      ref
          .read(addMemoryUploadNotifier.notifier)
          .setError('Failed to select file: ${e.toString()}');
    }
  }

  /// Handles the cancel button tap
  void _onTapCancel(BuildContext context) {
    NavigatorService.goBack();
  }

  /// Handles the add to memory button tap
  void _onTapAddToMemory(BuildContext context) {
    final state = ref.read(addMemoryUploadNotifier);

    if (state.selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    ref.read(addMemoryUploadNotifier.notifier).uploadFile().then((_) {
      NavigatorService.pushNamed(AppRoutes.homeScreen);
    });
  }
}
