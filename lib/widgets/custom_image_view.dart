import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../core/app_export.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    if (this.startsWith('http') || this.startsWith('https')) {
      if (this.endsWith('.svg')) {
        return ImageType.networkSvg;
      }
      return ImageType.network;
    } else if (this.endsWith('.svg')) {
      return ImageType.svg;
    } else if (this.startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, networkSvg, file, unknown }

class CustomImageView extends StatefulWidget {
  CustomImageView({
    Key? key,
    this.imagePath,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder,
  }) : super(key: key) {
    if (imagePath == null || imagePath!.isEmpty) {
      imagePath = ImageConstant.imgImageNotFound;
    }
  }

  ///[imagePath] is required parameter for showing image
  late String? imagePath;

  final double? height;

  final double? width;

  final Color? color;

  final BoxFit? fit;

  final String? placeHolder;

  final Alignment? alignment;

  final VoidCallback? onTap;

  final EdgeInsetsGeometry? margin;

  final BorderRadius? radius;

  final BoxBorder? border;

  @override
  State<CustomImageView> createState() => _CustomImageViewState();
}

class _CustomImageViewState extends State<CustomImageView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _previousImagePath;
  bool _hasAnimationCompleted =
      false; // Track if animation finished for current URL

  @override
  void initState() {
    super.initState();
    _previousImagePath = widget.imagePath;

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Listen for animation completion to prevent retriggering on rebuilds
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hasAnimationCompleted = true;
      }
    });

    // Only animate if this is a network image (avatar images are network images)
    if (_isNetworkImage(widget.imagePath)) {
      _animationController.forward();
    } else {
      // For non-network images, skip animation
      _animationController.value = 1.0;
      _hasAnimationCompleted = true;
    }
  }

  @override
  void didUpdateWidget(CustomImageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the image path ACTUALLY changed (not just widget rebuilt)
    final bool urlChanged =
        _hasImagePathChanged(oldWidget.imagePath, widget.imagePath);

    if (urlChanged) {
      // URL genuinely changed - reset animation state
      _previousImagePath = widget.imagePath;
      _hasAnimationCompleted = false;

      // Only animate network images (avatars)
      if (_isNetworkImage(widget.imagePath)) {
        _animationController.reset();
        _animationController.forward();
      } else {
        _animationController.value = 1.0;
        _hasAnimationCompleted = true;
      }
    } else if (!_hasAnimationCompleted && _isNetworkImage(widget.imagePath)) {
      // Same URL but animation was interrupted - continue/restart animation
      if (_animationController.status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    }
    // If URL is same and animation completed, do nothing (prevents retrigger on rebuild)
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if image path actually changed (not just rebuilt with same path)
  bool _hasImagePathChanged(String? oldPath, String? newPath) {
    // Handle null cases
    if (oldPath == null && newPath == null) return false;
    if (oldPath == null || newPath == null) return true;

    // CRITICAL: String comparison to detect actual URL changes
    // This prevents animation retrigger when widget rebuilds with same URL
    return oldPath != newPath;
  }

  /// Check if this is a network image (avatars are network images)
  bool _isNetworkImage(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return widget.alignment != null
        ? Align(alignment: widget.alignment!, child: _buildWidget())
        : _buildWidget();
  }

  Widget _buildWidget() {
    // Only wrap with animation if this is a network image
    Widget imageContent = Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        child: _buildCircleImage(),
      ),
    );

    // Apply scale animation ONLY for network images
    if (_isNetworkImage(widget.imagePath)) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: imageContent,
      );
    }

    return imageContent;
  }

  ///build the image with border radius
  _buildCircleImage() {
    if (widget.radius != null) {
      return ClipRRect(
        borderRadius: widget.radius ?? BorderRadius.zero,
        child: _buildImageWithBorder(),
      );
    } else {
      return _buildImageWithBorder();
    }
  }

  ///build the image with border and border radius style
  _buildImageWithBorder() {
    if (widget.border != null) {
      return Container(
        decoration: BoxDecoration(
          border: widget.border,
          borderRadius: widget.radius,
        ),
        child: _buildImageView(),
      );
    } else {
      return _buildImageView();
    }
  }

  Widget _buildImageView() {
    switch (widget.imagePath!.imageType) {
      case ImageType.svg:
        return Container(
          height: widget.height,
          width: widget.width,
          child: SvgPicture.asset(
            widget.imagePath!,
            height: widget.height,
            width: widget.width,
            fit: widget.fit ?? BoxFit.contain,
            colorFilter: widget.color != null
                ? ColorFilter.mode(
                    widget.color ?? appTheme.transparentCustom, BlendMode.srcIn)
                : null,
          ),
        );
      case ImageType.file:
        return Image.file(
          File(widget.imagePath!),
          height: widget.height,
          width: widget.width,
          fit: widget.fit ?? BoxFit.cover,
          color: widget.color,
        );
      case ImageType.networkSvg:
        return SvgPicture.network(
          widget.imagePath!,
          height: widget.height,
          width: widget.width,
          fit: widget.fit ?? BoxFit.contain,
          colorFilter: widget.color != null
              ? ColorFilter.mode(
                  widget.color ?? appTheme.transparentCustom, BlendMode.srcIn)
              : null,
        );
      case ImageType.network:
        return CachedNetworkImage(
          height: widget.height,
          width: widget.width,
          fit: widget.fit,
          imageUrl: widget.imagePath!,
          color: widget.color,
          // CRITICAL FIX: Optimize cache configuration for thumbnail stability
          cacheManager: CacheManager(
            Config(
              'customCacheKey',
              stalePeriod: const Duration(days: 7),
              maxNrOfCacheObjects: 200,
              repo: JsonCacheInfoRepository(databaseName: 'customCacheKey'),
              fileService: HttpFileService(
                httpClient: http.Client(),
              ),
            ),
          ),
          placeholder: (context, url) => Container(
            height: widget.height,
            width: widget.width,
            color: appTheme.grey100,
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: appTheme.gray_300,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            // CRITICAL FIX: Gracefully handle network errors without showing broken thumbnails
            final isInvalidUrl = url.isEmpty ||
                url == 'null' ||
                url == 'undefined' ||
                !url.startsWith('http');

            if (isInvalidUrl) {
              // Database returned invalid thumbnail URL
              return Image.asset(
                widget.placeHolder ?? ImageConstant.imgImageNotFound,
                height: widget.height,
                width: widget.width,
                fit: widget.fit ?? BoxFit.cover,
              );
            } else {
              // Valid URL but network/cache error - show loading state instead of broken image
              // This prevents "crash" appearance when returning from story viewer
              return Container(
                height: widget.height,
                width: widget.width,
                decoration: BoxDecoration(
                  color: appTheme.grey100,
                  borderRadius: widget.radius,
                ),
                child: Stack(
                  children: [
                    // CRITICAL: Show shimmer effect instead of broken image
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              appTheme.gray_300.withAlpha(51),
                              appTheme.gray_300.withAlpha(128),
                              appTheme.gray_300.withAlpha(51),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                          borderRadius: widget.radius,
                        ),
                      ),
                    ),
                    // Small loading indicator
                    Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: appTheme.gray_300,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
          // CRITICAL FIX: Add fadeInDuration to smooth appearance when loading from cache
          fadeInDuration: const Duration(milliseconds: 200),
          // CRITICAL FIX: Add memCacheHeight/Width for better memory management
          memCacheHeight: (widget.height?.toInt() ?? 200) * 2,
          memCacheWidth: (widget.width?.toInt() ?? 200) * 2,
        );
      case ImageType.png:
      default:
        return Image.asset(
          widget.imagePath!,
          height: widget.height,
          width: widget.width,
          fit: widget.fit ?? BoxFit.cover,
          color: widget.color,
          errorBuilder: (context, error, stackTrace) {
            // CRITICAL: Enhanced error logging for asset load failures
            print('❌ ASSET LOAD FAILED:');
            print('   Asset Path: ${widget.imagePath}');
            print('   Error: $error');
            print('   Stack Trace: $stackTrace');

            return Image.asset(
              widget.placeHolder ?? ImageConstant.imgImageNotFound,
              height: widget.height,
              width: widget.width,
              fit: widget.fit ?? BoxFit.cover,
            );
          },
        );
    }
  }
}
